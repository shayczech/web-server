const express = require('express');
const axios = require('axios');
const app = express();
const PORT = 3000;

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
    // headers: process.env.GITHUB_TOKEN ? { Authorization: `token ${process.env.GITHUB_TOKEN}` } : undefined,
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

// Primary Stats Endpoint
app.get('/api/stats', async (req, res) => {
    try {
        const [totalCommits, terraformModules, ansiblePlaybooks] = await Promise.all([
            getTotalCommitCount(),
            getTerraformModuleCount(),
            getTotalAnsiblePlaybooks(),
        ]);

        const data = {
            terraformModules: terraformModules || 0,
            ansiblePlaybooks: ansiblePlaybooks || 0,
            iacResources: (terraformModules || 0) + (ansiblePlaybooks || 0),
            ciCdRuns: 105, // static
            securityScore: 94, // static fallback
            githubCommits: totalCommits || 0,
        };

        res.json(data);
    } catch (err) {
        console.error('Unexpected stats error:', err && err.message ? err.message : err);
        res.json({
            terraformModules: 0,
            ansiblePlaybooks: 8,
            ciCdRuns: 105,
            securityScore: 94,
            githubCommits: 0,
        });
    }
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Stats API listening on port ${PORT}`);
});
