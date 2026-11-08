# Resume page redesign: tasks

Tick each task with the date and the evidence that proved it. Record no-go results and why.

## Tasks

- [x] 1. Resolve the two open items in `requirements.md` with Shaylee. 2026-11-08: defaults accepted (see Decisions).
- [x] 2. Write the `resume-data` JSON block from the resume PDF, minus the exclusions. 2026-11-08: every role, project, metric and credential checked against the PDF. Two roles on the old page that the new resume drops (a network internship and a computer-services job) are no longer shown. One more bullet was trimmed under the accepted "omit gap details" default: the alert-only load balancer count in the Dynatrace scoring bullet.
- [x] 3. Build the page shell: hero, four metrics, summary. Header and navigation unchanged. 2026-11-08: the splice kept everything before the style block and the header byte-for-byte; desktop screenshot reviewed.
- [x] 4. Render skill chips and the "Also worked with" list from the data. 2026-11-08: 40 chips, 18 skills listed as text. Headless test clicked every chip and found none with zero matching entries.
- [x] 5. Render project cards as `<details>` and the earlier-roles timeline. 2026-11-08: 4 project cards, collapsed by default; all 7 organizations from the PDF present in the rendered page.
- [x] 6. Implement the filter, highlight, "Showing N of M" and Clear. 2026-11-08: headless test. Terraform shows 3 of 11 entries and hides the earlier and consulting sections; clicking Terraform again restores 11; Oracle DBA shows 2 of 11; Clear restores 11 and returns focus to the Oracle chip.
- [x] 7. Render the featured project with links to `/architecture`, `/grc` and the repo, plus certification and education. 2026-11-08: screenshot reviewed.
- [x] 8. Remove the old Core Competencies, Professional Skills and Toolkit sections. 2026-11-08: `resume.html` went from 118,720 to about 43,800 bytes.
- [~] 9. Accessibility pass. 2026-11-08: chips are native buttons with `aria-pressed`; status is `aria-live="polite"`; cards are native `<details>`; focus returns to the chip after Clear (tested). Not done: a screen-reader run and a contrast measurement.
- [x] 10. Check at 375 px wide. 2026-11-08: rendered in a 375 px iframe. No horizontal overflow; metric numbers shrink and stay on one line.
- [x] 11. Exclusion check: grep `site/` and the PR diff for every line in `~/code/temp/resume-exclusions.txt`. 2026-11-08: 0 matches across all of `site/`, after removing the footer email link from all four pages.
- [x] 12. Update the Author line in the root `README.md` to the new title. 2026-11-08.
- [x] 12a. Fix CodeQL alert `js/xss-through-dom` (high) on PR #18: featured link `href` was set from the data block. 2026-11-08: targets moved into the `FEATURED_LINKS` constant; every remaining sink in the script reviewed (only constant attributes and `textContent`); rendered DOM shows the three links with the right targets and all 11 entries. Closed when CodeQL reports no open alerts on the PR.
- [ ] 13. Open the PR. After merge, confirm the content workflow is green and `/resume` renders on the live site.

## Tabled

| Work | Reopen when |
|---|---|
| Filter state in the URL hash, so a filtered view is shareable | You want to link to a specific skill view |
| Print stylesheet | You want to print or save the page as a PDF |
| Generate static HTML from the data instead of rendering in the browser | Crawlers or no-JS visitors matter |
| Sync the `index.html` About copy to the new resume | After this page ships |
| Screen-reader and contrast checks | Before the next accessibility-facing change |
