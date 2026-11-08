# Resume page redesign: design

## Approach

One file, `site/resume.html`. Resume content sits in a single `<script type="application/json" id="resume-data">` block. A small inline script renders it into the page and wires the filter. Nothing is fetched at runtime, and there is no build step.

Chosen over a separate `resume-data.json` fetch because that adds a request and a flash of empty content, and over generated static HTML because it adds a build step and a committed generated file that can drift.

## Data shape

```
profile    name, title, tagline, summary, links { linkedin, github, site }
metrics    [ { value, label } ]                       four headline numbers
skillGroups[ { id, label, items: [ { id, label } ] } ]  from the resume's Core Competencies
projects   [ { id, title, context, built[], result, skills[] } ]   EchoStar work
roles      [ { id, title, org, dates, bullets[], skills[] } ]      earlier roles
featured   { title, links[], bullets[], skills[] }
credentials[ { label } ]
```

`skills[]` holds skill ids. Nothing else links skills to work, so a chip exists only when at least one project, role or the featured entry uses it.

## Page layout, top to bottom

1. Existing header and navigation, unchanged.
2. Hero: name, title, one-line tagline.
3. Four metric tiles.
4. Summary paragraph.
5. Skill chips, grouped by skill group, then "Also worked with" as plain text.
6. Filter status line: "Showing N of M" and Clear.
7. EchoStar project cards, each a `<details>` element.
8. Earlier roles and consulting engagements, compact timeline.
9. Featured project card.
10. Certification and education.

## Filter behavior

- Single-select. Choosing a chip hides cards whose `skills[]` lacks that id. Choosing it again, or Clear, restores everything.
- Matching skill labels inside visible cards get the `keyword` highlight class.
- Hidden cards use the `hidden` attribute, so they leave the accessibility tree.
- Each chip is a `<button aria-pressed>`. The status line is `aria-live="polite"`.

## Why `<details>` for cards

It is native, keyboard accessible, and works with JavaScript disabled. Filtering does not depend on it.

## Deploy

`deploy-content.yml` syncs `site/` to S3 on merge to `main` and invalidates CloudFront. A pull request deploys nothing. Preview locally before merging.

## Verified

- No Content-Security-Policy is set (`infra/cloudfront.tf` documents why), and every page already uses inline scripts and the Tailwind Play CDN. An inline JSON block and inline script need no infrastructure change.
- `/resume` is rewritten to `resume.html` by the CloudFront Function (`infra/cf-functions/viewer-request.js`).
- The current page filters cards through `data-tags`, so the pattern is already in the codebase.
- Source content is the November 2026 resume PDF.

## Not yet verified

- Layout and chip wrapping at 375 px.
- Keyboard and screen-reader behavior of the chips and cards.
- Rendering without JavaScript. Content is JavaScript-rendered, so it is not visible without JS. Search crawlers that run JavaScript will see it, and others will not. LinkedIn is the primary channel, so v1 accepts this. A `<noscript>` line points to LinkedIn.
- Whether the card wording reads well. Problem, built and result text is derived from the resume bullets and needs your review.

## Risks

- Merging to `main` publishes immediately. Mitigation: local preview and the exclusion check before the PR is merged.
- Employer-sensitive detail. Mitigation: the exclusions list and its grep check.
