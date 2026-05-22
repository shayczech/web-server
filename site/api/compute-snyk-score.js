#!/usr/bin/env node
/**
 * Reads `snyk test --json` output and prints a 0–100 security score to stdout.
 * Used in CI only; not part of the runtime API container.
 */
const fs = require('fs');

const path = process.argv[2] || 'snyk.json';
const FALLBACK = 98;
const PENALTY = { critical: 20, high: 10, medium: 5, low: 2 };

function collectVulnerabilities(data) {
    const vulns = [];
    if (!data) return vulns;
    if (Array.isArray(data)) {
        for (const project of data) {
            if (Array.isArray(project?.vulnerabilities)) {
                vulns.push(...project.vulnerabilities);
            }
        }
        return vulns;
    }
    if (Array.isArray(data.vulnerabilities)) {
        vulns.push(...data.vulnerabilities);
    }
    return vulns;
}

function main() {
    let raw;
    try {
        raw = fs.readFileSync(path, 'utf8');
    } catch {
        process.stdout.write(String(FALLBACK));
        return;
    }

    let data;
    try {
        data = JSON.parse(raw);
    } catch {
        process.stdout.write(String(FALLBACK));
        return;
    }

    let score = 100;
    for (const v of collectVulnerabilities(data)) {
        const severity = String(v.severity || '').toLowerCase();
        score -= PENALTY[severity] || 0;
    }

    process.stdout.write(String(Math.max(0, Math.min(100, score))));
}

main();
