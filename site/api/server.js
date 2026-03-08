const express = require('express');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const { SSMClient, GetParameterCommand } = require('@aws-sdk/client-ssm');
const app = express();
const PORT = 3000;

const IAC_COUNT_PARAM = '/web-server/iac-resource-count';

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

// Configure CORS to allow access from the front-end (running on the host)
app.use((req, res, next) => {
    // Since the front-end is served on 443, allow requests from the same origin
    res.setHeader('Access-Control-Allow-Origin', '*'); 
    res.setHeader('Access-Control-Allow-Methods', 'GET');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    // Prevent any caching of API responses
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

const axiosOpts = {
    timeout: 3000,
    headers: process.env.GITHUB_TOKEN
        ? { Authorization: `Bearer ${process.env.GITHUB_TOKEN}` }
        : undefined,
};

// Fetch commit count for a single repo
async function getRepoCommitCount(repoName) {
    try {
        const response = await axios.get(
            `https://api.github.com/repos/${GITHUB_REPO_OWNER}/${repoName}/commits?per_page=1`,
            axiosOpts,
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
            axiosOpts,
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
            axiosOpts,
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
            axiosOpts,
        );
        const total = response.data?.total_count;
        return Number.isFinite(total) && total >= 0 ? total : 0;
    } catch (error) {
        console.warn(`GitHub Actions runs fetch failed: ${error.message}`);
        return 0;
    }
}

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

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Stats API listening on port ${PORT}`);
});
