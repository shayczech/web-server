# Resume page redesign: tasks

Tick each task with the date and the evidence that proved it. Record no-go results and why.

## Tasks

- [ ] 1. Resolve the two open items in `requirements.md` with Shaylee.
- [ ] 2. Write the `resume-data` JSON block from the resume PDF, minus the exclusions. Evidence: line-by-line check of each role, project and metric against the PDF.
- [ ] 3. Build the page shell: hero, four metrics, summary. Header and navigation unchanged. Evidence: screenshot at desktop width.
- [ ] 4. Render skill chips and the "Also worked with" list from the data. Evidence: every chip has at least one matching card.
- [ ] 5. Render project cards as `<details>` and the earlier-roles timeline. Evidence: all roles from the PDF present.
- [ ] 6. Implement the filter, highlight, "Showing N of M" and Clear. Evidence: click through three chips in a local browser.
- [ ] 7. Render the featured project with links to `/architecture`, `/grc` and the repo, plus certification and education.
- [ ] 8. Remove the old Core Competencies, Professional Skills and Toolkit sections. Evidence: file size before and after (118,720 bytes before).
- [ ] 9. Accessibility pass: keyboard-only use, `aria-pressed`, `aria-live`, color contrast. Evidence: notes of what was tested.
- [ ] 10. Check at 375 px wide. Evidence: screenshot.
- [ ] 11. Exclusion check: grep `site/` and the PR diff for every line in `~/code/temp/resume-exclusions.txt`. Evidence: no matches.
- [ ] 12. Update the Author line in the root `README.md` to the new title.
- [ ] 13. Open the PR. After merge, confirm the content workflow is green and `/resume` renders on the live site.

## Tabled

| Work | Reopen when |
|---|---|
| Filter state in the URL hash, so a filtered view is shareable | You want to link to a specific skill view |
| Print stylesheet | You want to print or save the page as a PDF |
| Generate static HTML from the data instead of rendering in the browser | Crawlers or no-JS visitors matter |
| Sync the `index.html` About copy to the new resume | After this page ships |
