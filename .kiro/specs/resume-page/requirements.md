# Resume page redesign: requirements

**Status:** Draft, ready for review. Not started.
**Page:** `site/resume.html`, served at `/resume`.

## Goal

Replace the long stacked resume page with one where the work is the spine and the skills are how you navigate it. A reader should see the headline results in seconds, click a skill, and see only the projects and roles that prove it. Content must match the November 2026 resume.

## Decisions

| Date | Decision | Decided by |
|---|---|---|
| 2026-11-08 | Interaction model: skill chips filter project and role cards. Work is the spine of the page. | Shaylee |
| 2026-11-08 | Content lives in one data block that the page renders, so a resume update is one edit. | Shaylee |
| 2026-11-08 | Leave phone, email and CISSP ID number off the public page. LinkedIn is the only contact path. | Shaylee |
| 2026-11-08 | Leave the API gateway auditor material in the current role off the public page. | Shaylee |
| 2026-11-08 | Update the `web` README Author line to the new title. | Shaylee (default accepted) |
| 2026-11-08 | Omit the gap and finding details from the two other current-role bullets (the attack-surface bullet and the merge-request validation findings bullet). | Shaylee (default accepted) |
| 2026-11-08 | Remove the old Professional Skills and Toolkit sections. | Shaylee (default accepted) |
| 2026-11-08 | Remove the footer email link from all four pages. Required by the exclusions below, which cover all of `site/`, and by "LinkedIn only". | Shaylee (spec #17) |

## Requirements

1. **Content matches the resume.** Every role, project, metric and certification on the page comes from the current resume PDF, except the exclusions below.
2. **Headline numbers.** The top of the page shows four metrics: under 30 seconds per firewall change review, 15 to 20 hours a week of manual review replaced, about 300 load balancers covered, and about 480 automated tests.
3. **Skill chips filter the work.**
   - Each chip is a keyboard-operable button with `aria-pressed`.
   - Choosing a chip shows only the cards tagged with that skill, highlights the skill inside each card, and shows "Showing N of M" and a Clear control.
   - Choosing the active chip again clears the filter.
   - Skills with no matching card are not chips. They appear as plain text under "Also worked with".
4. **Project cards.** The EchoStar work is shown as cards that expand to show what was built, the result, and the stack. Cards expand and collapse without JavaScript.
5. **Earlier roles.** Older roles and consulting engagements appear in a compact timeline and are filtered by the same chips.
6. **Featured project.** The serverless platform entry links to `/architecture` and `/grc` and to the GitHub repo.
7. **Certification and education.** CISSP (no ID number) and the B.S. in Computer Science, Western Washington University, 2017.
8. **Site consistency.** The header and navigation, color palette and fonts are unchanged. The page works at 375 px wide.
9. **No new infrastructure.** No change under `infra/`. The page deploys through the existing content workflow.

## Public-content exclusions

This repo is public, so the exclusion terms are deliberately not written here. They live in a local file outside the repo (`~/code/temp/resume-exclusions.txt`), and the check in `tasks.md` greps `site/` for every line in it.

- Personal contact details: phone number, email address, certification ID number.
- Employer-sensitive material: the API gateway auditor bullet in the current role, with its findings and the vendor name. The merge-request validation project is described only as "API gateway".

## Open items

None. Both earlier open items were resolved on 2026-11-08 (see Decisions).

## Out of scope

- The `index.html` About copy. Check it against the new resume in a separate change.
- Any change to `/architecture`, `/grc` or `/p/recipes`.
