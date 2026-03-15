const express = require('express');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const pdf = require('pdf-parse');
const { SSMClient, GetParameterCommand } = require('@aws-sdk/client-ssm');
const app = express();
const PORT = 3000;

const IAC_COUNT_PARAM = '/web-server/iac-resource-count';
const GITHUB_TOKEN_PARAM = '/web-server/github-token';
const ANTHROPIC_API_KEY_PARAM = '/web-server/anthropic-api-key';
const KITCHEN_AUTH_PARAM = '/web-server/kitchen-auth-hash';

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

const SECURITY_SCORE_PATH = path.join('/', 'app', 'security-score.json');
const FALLBACK_SECURITY_SCORE = 98;

function getSecurityScore() {
    try {
        if (fs.existsSync(SECURITY_SCORE_PATH)) {
            const raw = fs.readFileSync(SECURITY_SCORE_PATH, 'utf8');
            const data = JSON.parse(raw);
            const score = Number(data?.securityScore);
            if (Number.isFinite(score) && score >= 0 && score <= 100) return score;
        }
    } catch (err) {
        console.warn('Could not read security score file:', err?.message || err);
    }
    return FALLBACK_SECURITY_SCORE;
}

app.use(express.json({ limit: '1mb' }));

// Configure CORS to allow access from the front-end (running on the host)
app.use((req, res, next) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Kitchen-Auth');
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
    next();
});

// GitHub-only dynamic stats (no AWS)
const GITHUB_REPO_OWNER = 'shayczech';
// Repos to include in stats. Non-existent/private repos will be skipped safely
const REPOSITORIES = [
    'web-server',
    'k8s-ci-cd-demo',
    'terraform-aws-secure-vpc',
];

function getAxiosOpts() {
    return {
        timeout: 3000,
        headers: process.env.GITHUB_TOKEN
            ? { Authorization: `Bearer ${process.env.GITHUB_TOKEN}` }
            : undefined,
    };
}

// Fetch commit count for a single repo
async function getRepoCommitCount(repoName) {
    try {
        const response = await axios.get(
            `https://api.github.com/repos/${GITHUB_REPO_OWNER}/${repoName}/commits?per_page=1`,
            getAxiosOpts(),
        );
        const linkHeader = response.headers.link;
        if (linkHeader) {
            const match = linkHeader.match(/&page=(\d+)>; rel="last"/);
            if (match && match[1]) {
                return parseInt(match[1], 10);
            }
        }
        return Array.isArray(response.data) ? response.data.length : 0;
    } catch (error) {
        console.warn(`GitHub commits failed for ${repoName}: ${error.message}`);
        return 0;
    }
}

// Total commits across repositories
async function getTotalCommitCount() {
    const results = await Promise.all(REPOSITORIES.map(getRepoCommitCount));
    return results.reduce((sum, n) => sum + (Number.isFinite(n) ? n : 0), 0);
}

// Count Terraform modules by scanning repo trees for .tf files
async function getRepoTerraformFileCount(repoName) {
    try {
        // Use the repo tree API to list all files at HEAD
        const response = await axios.get(
            `https://api.github.com/repos/${GITHUB_REPO_OWNER}/${repoName}/git/trees/HEAD?recursive=1`,
            getAxiosOpts(),
        );
        const tree = response.data && Array.isArray(response.data.tree) ? response.data.tree : [];
        const tfCount = tree.filter((node) => node.type === 'blob' && /\.tf$/i.test(node.path)).length;
        return tfCount;
    } catch (error) {
        console.warn(`GitHub tree scan failed for ${repoName}: ${error.message}`);
        return 0;
    }
}

async function getTerraformModuleCount() {
    const results = await Promise.all(REPOSITORIES.map(getRepoTerraformFileCount));
    return results.reduce((sum, n) => sum + (Number.isFinite(n) ? n : 0), 0);
}

// Count Ansible playbooks across repositories
// Heuristics: any .yml/.yaml file under paths commonly used for playbooks
// e.g., ansible/**, playbooks/**, or filenames containing 'playbook'
function isLikelyPlaybookPath(path) {
    if (!path) return false;
    const lower = path.toLowerCase();
    if (!/\.ya?ml$/.test(lower)) return false;
    if (lower.includes('/ansible/') || lower.startsWith('ansible/')) return true;
    if (lower.includes('/playbooks/') || lower.startsWith('playbooks/')) return true;
    if (lower.includes('playbook')) return true;
    // Exclude typical CI config files to reduce false positives
    if (lower.startsWith('.github/workflows/')) return false;
    if (lower.includes('/.github/')) return false;
    return false;
}

async function getRepoAnsiblePlaybookCount(repoName) {
    try {
        const response = await axios.get(
            `https://api.github.com/repos/${GITHUB_REPO_OWNER}/${repoName}/git/trees/HEAD?recursive=1`,
            getAxiosOpts(),
        );
        const tree = response.data && Array.isArray(response.data.tree) ? response.data.tree : [];
        const count = tree.filter((node) => node.type === 'blob' && isLikelyPlaybookPath(node.path)).length;
        return count;
    } catch (error) {
        console.warn(`GitHub playbook scan failed for ${repoName}: ${error.message}`);
        return 0;
    }
}

async function getTotalAnsiblePlaybooks() {
    const results = await Promise.all(REPOSITORIES.map(getRepoAnsiblePlaybookCount));
    return results.reduce((sum, n) => sum + (Number.isFinite(n) ? n : 0), 0);
}

// Load GitHub token from SSM at startup (avoids 60/hr unauthenticated rate limit)
async function loadGitHubTokenFromSSM() {
    if (process.env.GITHUB_TOKEN) return;
    try {
        const client = new SSMClient({ region: process.env.AWS_REGION || 'us-east-2' });
        const out = await client.send(new GetParameterCommand({
            Name: GITHUB_TOKEN_PARAM,
            WithDecryption: true,
        }));
        const value = out.Parameter?.Value;
        if (value && typeof value === 'string') {
            process.env.GITHUB_TOKEN = value;
            console.log('GitHub token loaded from SSM');
        }
    } catch (err) {
        console.warn('SSM GitHub token not set or unavailable:', err?.message || err);
    }
}

// Load Anthropic API key from SSM (for recipe-from-PDF)
async function loadAnthropicKeyFromSSM() {
    if (process.env.ANTHROPIC_API_KEY) return;
    try {
        const client = new SSMClient({ region: process.env.AWS_REGION || 'us-east-2' });
        const out = await client.send(new GetParameterCommand({
            Name: ANTHROPIC_API_KEY_PARAM,
            WithDecryption: true,
        }));
        const value = out.Parameter?.Value;
        if (value && typeof value === 'string') {
            process.env.ANTHROPIC_API_KEY = value;
            console.log('Anthropic API key loaded from SSM');
        }
    } catch (err) {
        console.warn('SSM Anthropic key not set or unavailable:', err?.message || err);
    }
}

// Kitchen data: persist pantry, grocery, recipes. Auth via X-Kitchen-Auth (SHA-256 of password).
// Intentional: authenticated user data only; path is fixed, payload validated (no arbitrary file write).
async function loadKitchenAuthFromSSM() {
    if (process.env.KITCHEN_AUTH_HASH) return;
    try {
        const client = new SSMClient({ region: process.env.AWS_REGION || 'us-east-2' });
        const out = await client.send(new GetParameterCommand({
            Name: KITCHEN_AUTH_PARAM,
            WithDecryption: true,
        }));
        const value = out.Parameter?.Value;
        if (value && typeof value === 'string') {
            process.env.KITCHEN_AUTH_HASH = value;
            console.log('Kitchen auth hash loaded from SSM');
        }
    } catch (err) {
        console.warn('SSM Kitchen auth not set or unavailable:', err?.message || err);
    }
}

// Fixed path only: resolve to absolute and ensure under app dir (no path traversal / user-controlled path).
const KITCHEN_DATA_PATH = (() => {
    const baseDir = path.resolve(__dirname);
    const candidate = path.resolve(path.normalize(process.env.KITCHEN_DATA_PATH || path.join(__dirname, 'kitchen-data.json')));
    if (!candidate.startsWith(baseDir)) return path.join(__dirname, 'kitchen-data.json');
    return candidate;
})();

const KITCHEN_MAX_ITEMS_PER_ARRAY = 20000;
const KITCHEN_MAX_PAYLOAD_BYTES = 5 * 1024 * 1024; // 5MB

function requireKitchenAuth(req, res, next) {
    const expected = process.env.KITCHEN_AUTH_HASH;
    if (!expected) {
        return next();
    }
    const provided = req.headers['x-kitchen-auth'];
    if (provided !== expected) {
        return res.status(401).json({ error: 'Unauthorized' });
    }
    next();
}

/** Validate and normalize body: only pantry, grocery, recipes arrays; reject extra keys and oversized payload. */
function validateKitchenPayload(body) {
    if (!body || typeof body !== 'object') return null;
    const allowed = ['pantry', 'grocery', 'recipes'];
    const keys = Object.keys(body);
    if (keys.some((k) => !allowed.includes(k))) return null;
    const out = {
        pantry: Array.isArray(body.pantry) ? body.pantry.slice(0, KITCHEN_MAX_ITEMS_PER_ARRAY) : [],
        grocery: Array.isArray(body.grocery) ? body.grocery.slice(0, KITCHEN_MAX_ITEMS_PER_ARRAY) : [],
        recipes: Array.isArray(body.recipes) ? body.recipes.slice(0, KITCHEN_MAX_ITEMS_PER_ARRAY) : [],
    };
    const serialized = JSON.stringify(out);
    if (Buffer.byteLength(serialized, 'utf8') > KITCHEN_MAX_PAYLOAD_BYTES) return null;
    return out;
}

function readKitchenData() {
    try {
        if (fs.existsSync(KITCHEN_DATA_PATH)) {
            const raw = fs.readFileSync(KITCHEN_DATA_PATH, 'utf8');
            if (Buffer.byteLength(raw, 'utf8') > KITCHEN_MAX_PAYLOAD_BYTES) return { pantry: [], grocery: [], recipes: [] };
            const data = JSON.parse(raw);
            return {
                pantry: Array.isArray(data.pantry) ? data.pantry : [],
                grocery: Array.isArray(data.grocery) ? data.grocery : [],
                recipes: Array.isArray(data.recipes) ? data.recipes : [],
            };
        }
    } catch (err) {
        console.warn('Kitchen data read failed:', err?.message || err);
    }
    return { pantry: [], grocery: [], recipes: [] };
}

function writeKitchenData(data) {
    const toWrite = {
        pantry: Array.isArray(data.pantry) ? data.pantry : [],
        grocery: Array.isArray(data.grocery) ? data.grocery : [],
        recipes: Array.isArray(data.recipes) ? data.recipes : [],
    };
    const dir = path.dirname(KITCHEN_DATA_PATH);
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
    const content = JSON.stringify(toWrite, null, 2);
    if (Buffer.byteLength(content, 'utf8') > KITCHEN_MAX_PAYLOAD_BYTES) throw new Error('Kitchen data too large');
    fs.writeFileSync(KITCHEN_DATA_PATH, content, 'utf8');
}

const RECIPE_JSON_SCHEMA = `Return only valid JSON (no markdown, no code block) with this shape:
{
  "title": "string",
  "category": "Breakfast|Lunch|Dinner|Dessert|Snack|Baked Good|Appetizer|Drinks|Other",
  "description": "string (1-2 sentences)",
  "prepTime": "string e.g. 20 min",
  "cookTime": "string e.g. 30 min",
  "servings": number,
  "ingredients": ["string", "..."],
  "steps": ["string", "..."],
  "notes": "string or empty"
}`;

async function recipeFromText(text) {
    const key = process.env.ANTHROPIC_API_KEY;
    if (!key) throw new Error('ANTHROPIC_API_KEY not configured (set env or SSM /web-server/anthropic-api-key)');
    const truncated = text.slice(0, 12000);
    const response = await axios.post(
        'https://api.anthropic.com/v1/messages',
        {
            model: 'claude-sonnet-4-20250514',
            max_tokens: 1500,
            system: `You extract a single recipe from raw text and return only valid JSON. ${RECIPE_JSON_SCHEMA}`,
            messages: [{ role: 'user', content: truncated }],
        },
        {
            timeout: 60000,
            headers: {
                'Content-Type': 'application/json',
                'x-api-key': key,
                'anthropic-version': '2023-06-01',
            },
        },
    );
    const raw = response.data?.content?.[0]?.text;
    if (!raw) throw new Error('No recipe in response');
    const clean = raw.replace(/```json|```/g, '').trim();
    return JSON.parse(clean);
}

// Live IaC resource count from SSM (written by pipeline after terraform apply)
async function getIacResourceCountFromSSM() {
    try {
        const client = new SSMClient({ region: process.env.AWS_REGION || 'us-east-2' });
        const out = await client.send(new GetParameterCommand({
            Name: IAC_COUNT_PARAM,
            WithDecryption: false,
        }));
        const value = out.Parameter?.Value;
        if (value == null) return null;
        const n = parseInt(value, 10);
        return Number.isFinite(n) && n >= 0 ? n : null;
    } catch (err) {
        console.warn('SSM IaC count fetch failed:', err?.message || err);
        return null;
    }
}

// GitHub Actions workflow run count (primary repo: web-server)
const CICD_REPO = 'web-server';
async function getActionsRunCount() {
    try {
        const response = await axios.get(
            `https://api.github.com/repos/${GITHUB_REPO_OWNER}/${CICD_REPO}/actions/runs?per_page=1`,
            getAxiosOpts(),
        );
        const total = response.data?.total_count;
        return Number.isFinite(total) && total >= 0 ? total : 0;
    } catch (error) {
        console.warn(`GitHub Actions runs fetch failed: ${error.message}`);
        return 0;
    }
}

// Recipe from PDF (admin-only use; obscure admin URL is the gate)
app.post('/api/recipes/from-pdf', upload.single('pdf'), async (req, res) => {
    try {
        if (!req.file || !req.file.buffer) {
            res.status(400).json({ error: 'No PDF file uploaded' });
            return;
        }
        const data = await pdf(req.file.buffer);
        const text = data?.text?.trim();
        if (!text || text.length < 50) {
            res.status(400).json({ error: 'Could not extract enough text from PDF' });
            return;
        }
        const recipe = await recipeFromText(text);
        res.json(recipe);
    } catch (err) {
        console.error('Recipe from PDF error:', err?.message || err);
        res.status(500).json({ error: err?.message || 'Failed to generate recipe' });
    }
});

// Recipe from description (admin: type a prompt, get structured recipe)
app.post('/api/recipes/from-text', async (req, res) => {
    try {
        const text = req.body?.text?.trim();
        if (!text || text.length < 3) {
            res.status(400).json({ error: 'Provide a description (e.g. "banana bread with chocolate chips")' });
            return;
        }
        const recipe = await recipeFromText(text);
        res.json(recipe);
    } catch (err) {
        console.error('Recipe from text error:', err?.message || err);
        res.status(500).json({ error: err?.message || 'Failed to generate recipe' });
    }
});

// Kitchen data: load/save pantry, grocery, recipes (auth via X-Kitchen-Auth header = SHA-256 of password)
app.get('/api/kitchen/data', requireKitchenAuth, (req, res) => {
    try {
        const data = readKitchenData();
        res.json(data);
    } catch (err) {
        console.error('Kitchen GET error:', err?.message || err);
        res.status(500).json({ error: 'Failed to load kitchen data' });
    }
});

app.post('/api/kitchen/data', requireKitchenAuth, (req, res) => {
    try {
        const validated = validateKitchenPayload(req.body);
        if (!validated) {
            return res.status(400).json({ error: 'Invalid payload: only pantry, grocery, recipes arrays allowed; max 5MB' });
        }
        writeKitchenData(validated);
        res.json({ ok: true });
    } catch (err) {
        console.error('Kitchen POST error:', err?.message || err);
        res.status(500).json({ error: 'Failed to save kitchen data' });
    }
});

// Primary Stats Endpoint
app.get('/api/stats', async (req, res) => {
    try {
        const [totalCommits, terraformModules, ansiblePlaybooks, ciCdRuns, iacFromSSM] = await Promise.all([
            getTotalCommitCount(),
            getTerraformModuleCount(),
            getTotalAnsiblePlaybooks(),
            getActionsRunCount(),
            getIacResourceCountFromSSM(),
        ]);

        const fileCountFallback = (terraformModules || 0) + (ansiblePlaybooks || 0);
        const data = {
            terraformModules: terraformModules || 0,
            ansiblePlaybooks: ansiblePlaybooks || 0,
            iacResources: iacFromSSM != null ? iacFromSSM : fileCountFallback,
            ciCdRuns: ciCdRuns ?? 0,
            securityScore: getSecurityScore(),
            githubCommits: totalCommits || 0,
        };

        res.json(data);
    } catch (err) {
        console.error('Unexpected stats error:', err && err.message ? err.message : err);
        res.json({
            terraformModules: 0,
            ansiblePlaybooks: 8,
            iacResources: 0,
            ciCdRuns: 0,
            securityScore: getSecurityScore(),
            githubCommits: 0,
        });
    }
});

(async () => {
    await loadGitHubTokenFromSSM();
    await loadAnthropicKeyFromSSM();
    await loadKitchenAuthFromSSM();
    app.listen(PORT, '0.0.0.0', () => {
        console.log(`Stats API listening on port ${PORT}`);
        if (!process.env.GITHUB_TOKEN) {
            console.warn('GITHUB_TOKEN not set; GitHub API calls are unauthenticated (60 req/hr). Set SSM /web-server/github-token for 5000/hr.');
        }
    });
})();
