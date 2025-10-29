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
    next();
});

// Mock service for current project stats
const GITHUB_REPO_OWNER = 'shayczech'; 
const GITHUB_REPO_NAME = 'web-server'; // Your project repository

// Function to fetch the total number of commits
async function getCommitCount() {
    try {
        const response = await axios.get(`https://api.github.com/repos/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}/commits?per_page=1`, {
            // Optional: Use an environment variable for a GitHub Token if rate limits are an issue
            // headers: { 'Authorization': `token ${process.env.GITHUB_TOKEN}` }
        });
        
        // The last page link header usually contains the total number of pages/commits
        const linkHeader = response.headers.link;
        if (linkHeader) {
            const match = linkHeader.match(/&page=(\d+)>; rel="last"/);
            if (match && match[1]) {
                // If the last page number is found, that is the total commit count
                return parseInt(match[1], 10);
            }
        }
        // Fallback: Estimate commits by fetching all pages (inefficient, but works for small repos)
        // Or, if no link header, return the number of commits on the first page
        return response.data.length || 0; 
        
    } catch (error) {
        console.error('Error fetching GitHub commits:', error.message);
        // Fallback safe mock data if API fails
        return 75; 
    }
}

// Primary Stats Endpoint
app.get('/api/stats', async (req, res) => {
    const totalCommits = await getCommitCount();
    
    // Simple static stats - no more AWS complexity
    const data = {
        terraformModules: 5, // Static
        ansiblePlaybooks: 8,
        ciCdRuns: 105,
        securityScore: 92,
        githubCommits: totalCommits, // Only dynamic data
    };

    // Simulate network delay for realistic front-end loading effect
    setTimeout(() => {
        res.json(data);
    }, 500); // 500ms delay
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Stats API listening on port ${PORT}`);
});
