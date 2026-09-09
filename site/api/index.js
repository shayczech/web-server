const { SSMClient, GetParameterCommand } = require('@aws-sdk/client-ssm');

const IAC_COUNT_PARAM = '/web-server/iac-resource-count';
const GITHUB_TOKEN_PARAM = '/web-server/github-token';
const SECURITY_SCORE_PARAM = '/web-server/security-score';
const GITHUB_FETCH_TIMEOUT_MS = 3000;
const FALLBACK_SECURITY_SCORE = 98;

const ssmClient = new SSMClient({ region: process.env.AWS_REGION || 'us-east-2' });

async function getSecurityScore() {
    try {
        const out = await ssmClient.send(new GetParameterCommand({
            Name: SECURITY_SCORE_PARAM,
            WithDecryption: false,
        }));
        const value = out.Parameter?.Value;
        const n = value == null ? NaN : parseInt(value, 10);
        if (Number.isFinite(n) && n >= 0 && n <= 100) return n;
    } catch (err) {
        console.warn('SSM security score fetch failed:', err?.message || err);
    }
    return FALLBACK_SECURITY_SCORE;
}

const GITHUB_REPO_OWNER = 'shayczech';
const REPOSITORIES = [
    'web-server',
    'k8s-ci-cd-demo',
    'terraform-aws-secure-vpc',
];

function githubFetchHeaders() {
    const headers = {
        Accept: 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
    };
    if (process.env.GITHUB_TOKEN) {
        headers.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;
    }
    return headers;
}

async function githubGet(url) {
    // A manually-cleared AbortController, not AbortSignal.timeout() — the
    // latter's internal timer isn't reliably cleared on Lambda's Node 22
    // runtime once the fetch settles, and a dangling timer surviving past
    // the response causes a "Runtime.NodeJsExit: unsettled Promise" crash
    // on a later invocation (reproduced via CloudWatch Logs after deploy).
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), GITHUB_FETCH_TIMEOUT_MS);
    let response;
    try {
        response = await fetch(url, {
            headers: githubFetchHeaders(),
            signal: controller.signal,
        });
    } finally {
        clearTimeout(timeoutId);
    }
    if (!response.ok) {
        throw new Error(`GitHub HTTP ${response.status}`);
    }
    const data = await response.json();
    return { data, link: response.headers.get('link') };
}

async function getRepoCommitCount(repoName) {
    try {
        const { data, link } = await githubGet(
            `https://api.github.com/repos/${GITHUB_REPO_OWNER}/${repoName}/commits?per_page=1`,
        );
        if (link) {
            const match = link.match(/&page=(\d+)>; rel="last"/);
            if (match && match[1]) {
                return parseInt(match[1], 10);
            }
        }
        return Array.isArray(data) ? data.length : 0;
    } catch (error) {
        console.warn(`GitHub commits failed for ${repoName}: ${error.message}`);
        return 0;
    }
}

async function getTotalCommitCount() {
    const results = await Promise.all(REPOSITORIES.map(getRepoCommitCount));
    return results.reduce((sum, n) => sum + (Number.isFinite(n) ? n : 0), 0);
}

async function getRepoTerraformFileCount(repoName) {
    try {
        const { data } = await githubGet(
            `https://api.github.com/repos/${GITHUB_REPO_OWNER}/${repoName}/git/trees/HEAD?recursive=1`,
        );
        const tree = data && Array.isArray(data.tree) ? data.tree : [];
        return tree.filter((node) => node.type === 'blob' && /\.tf$/i.test(node.path)).length;
    } catch (error) {
        console.warn(`GitHub tree scan failed for ${repoName}: ${error.message}`);
        return 0;
    }
}

async function getTerraformModuleCount() {
    const results = await Promise.all(REPOSITORIES.map(getRepoTerraformFileCount));
    return results.reduce((sum, n) => sum + (Number.isFinite(n) ? n : 0), 0);
}

function isLikelyPlaybookPath(p) {
    if (!p) return false;
    const lower = p.toLowerCase();
    if (!/\.ya?ml$/.test(lower)) return false;
    if (lower.includes('/ansible/') || lower.startsWith('ansible/')) return true;
    if (lower.includes('/playbooks/') || lower.startsWith('playbooks/')) return true;
    if (lower.includes('playbook')) return true;
    return false;
}

async function getRepoAnsiblePlaybookCount(repoName) {
    try {
        const { data } = await githubGet(
            `https://api.github.com/repos/${GITHUB_REPO_OWNER}/${repoName}/git/trees/HEAD?recursive=1`,
        );
        const tree = data && Array.isArray(data.tree) ? data.tree : [];
        return tree.filter((node) => node.type === 'blob' && isLikelyPlaybookPath(node.path)).length;
    } catch (error) {
        console.warn(`GitHub playbook scan failed for ${repoName}: ${error.message}`);
        return 0;
    }
}

async function getTotalAnsiblePlaybooks() {
    const results = await Promise.all(REPOSITORIES.map(getRepoAnsiblePlaybookCount));
    return results.reduce((sum, n) => sum + (Number.isFinite(n) ? n : 0), 0);
}

async function loadGitHubTokenFromSSM() {
    if (process.env.GITHUB_TOKEN) return;
    try {
        const out = await ssmClient.send(new GetParameterCommand({
            Name: GITHUB_TOKEN_PARAM,
            WithDecryption: true,
        }));
        const value = out.Parameter?.Value;
        if (value && typeof value === 'string') {
            process.env.GITHUB_TOKEN = value;
        }
    } catch (err) {
        console.warn('SSM GitHub token not set or unavailable:', err?.message || err);
    }
}

async function getIacResourceCountFromSSM() {
    try {
        const out = await ssmClient.send(new GetParameterCommand({
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

const CICD_REPO = 'web-server';
async function getActionsRunCount() {
    try {
        const { data } = await githubGet(
            `https://api.github.com/repos/${GITHUB_REPO_OWNER}/${CICD_REPO}/actions/runs?per_page=1`,
        );
        const total = data?.total_count;
        return Number.isFinite(total) && total >= 0 ? total : 0;
    } catch (error) {
        console.warn(`GitHub Actions runs fetch failed: ${error.message}`);
        return 0;
    }
}

function response(statusCode, body) {
    return {
        statusCode,
        headers: {
            'Content-Type': 'application/json',
            'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
            Pragma: 'no-cache',
            Expires: '0',
        },
        body: JSON.stringify(body),
    };
}

exports.handler = async (event) => {
    const expectedSecret = process.env.ORIGIN_SECRET;
    const providedSecret = event?.headers?.['x-origin-verify'];
    if (expectedSecret && providedSecret !== expectedSecret) {
        return response(403, { error: 'Forbidden' });
    }

    await loadGitHubTokenFromSSM();

    try {
        const [totalCommits, terraformModules, ansiblePlaybooks, ciCdRuns, iacFromSSM, securityScore] = await Promise.all([
            getTotalCommitCount(),
            getTerraformModuleCount(),
            getTotalAnsiblePlaybooks(),
            getActionsRunCount(),
            getIacResourceCountFromSSM(),
            getSecurityScore(),
        ]);

        const fileCountFallback = (terraformModules || 0) + (ansiblePlaybooks || 0);
        return response(200, {
            terraformModules: terraformModules || 0,
            ansiblePlaybooks: ansiblePlaybooks || 0,
            iacResources: iacFromSSM != null ? iacFromSSM : fileCountFallback,
            ciCdRuns: ciCdRuns ?? 0,
            securityScore,
            githubCommits: totalCommits || 0,
        });
    } catch (err) {
        console.error('Unexpected stats error:', err && err.message ? err.message : err);
        const securityScore = await getSecurityScore();
        return response(200, {
            terraformModules: 0,
            ansiblePlaybooks: 8,
            iacResources: 0,
            ciCdRuns: 0,
            securityScore,
            githubCommits: 0,
        });
    }
};
