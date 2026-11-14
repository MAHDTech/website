# MAHDTech website

Source for [mahdtech.com](https://mahdtech.com): a blog and an interactive resume, built from Markdown and YAML with Zola, Tailwind CSS v4 and Typst, and hosted on GitHub Pages.

## Quick start

```bash
devenv shell   # installs tools, builds CSS, PDFs, social cards, exports and the search index
zola serve     # http://127.0.0.1:1111
```

- `/` is the blog. Draft posts only show with `zola serve --drafts`.
- `/resume/` is the resume, with Full and Short PDF downloads, Auto/Light/Dark themes and a skill filter.
- Press `Ctrl K` (`⌘K` on macOS) or `/` anywhere for search and commands.

For live rebuilds of the CSS and generated files while you edit, run `devenv up` instead of `zola serve`.

## Editing content

Content lives in two places, and you shouldn't need to touch templates to change it.

| What | Where |
| --- | --- |
| Blog posts | `content/posts/<slug>.md` (Markdown with YAML frontmatter) |
| Resume, name, contact details | `data/resume.yaml` |
| Site title, menu, description | `config.toml` |

### Writing a post

```yaml
---
title: "Post title"
date: 2026-11-14
description: "One or two sentences, shown on the blog card and in link previews."
draft: true            # remove to publish
taxonomies:
  tags: ["kubernetes", "rust"]
  categories: ["Platform Engineering"]
extra:
  category: "Platform Engineering"     # chip on the card and social image
  image: "/images/posts/my-cover.svg"  # card and header image (16:9)
  image_alt: "What the image shows"
  digest: "Optional TL;DR shown at the top of the post."
  key_points: ["Optional takeaway", "Another takeaway"]
  github_issue_id: 2                   # optional: show comments from this issue
---
```

A social preview image is generated for every post automatically.

### Updating the resume

Edit `data/resume.yaml`. Dates are `YYYY-MM` and an empty `end` means the role is current. Years of experience, role counts, durations and the career timeline are calculated from those dates, and `{years}` in prose is replaced with the computed number.

The same file feeds the web resume, both PDFs, the resume social card, `/resume.json` ([JSON Resume](https://jsonresume.org/schema)), `/resume.md` and `/llms.txt`. Run `generate` (or keep `devenv up` running) to rebuild them.

## Commands

Available inside `devenv shell`:

| Command | Does |
| --- | --- |
| `generate` | Rebuild PDFs, social cards, exports and the search index |
| `resumes` | Rebuild only the PDFs |
| `css` | Rebuild `static/css/custom.css` from `styles/input.css` |
| `fonts` | Regenerate the subsetted WOFF2 fonts |
| `build` | Production build into `public/` |
| `devenv test` | Build and verify everything (CI runs this) |

The `tailwind-css` pre-commit hook rebuilds the committed stylesheet when templates, styles or scripts change.

## How it fits together

```text
content/*.md ─────────┐
data/resume.yaml ─────┼─▶ Zola (templates/) ─────────▶ HTML
config.toml ──────────┘
data/resume.yaml ─▶ Typst (resume/resume.typ) ───────▶ Full and Short PDFs
posts + resume ───▶ Typst (resume/og.typ) ───────────▶ 1200×630 social cards
data/resume.yaml ─▶ jaq (resume/export.jq) ──────────▶ resume.json, resume.md
public/*.html ────▶ Pagefind ────────────────────────▶ full-text search index
```

Generated files are git-ignored and rebuilt on `devenv shell` and in CI.

## Deployment

`.github/workflows/pages.yaml` runs `devenv test` on every pull request. On `trunk` it also deploys `public/` to GitHub Pages, and it redeploys monthly so computed values stay current.

One-time setup:

1. In the repository settings under **Pages**, set **Source** to **GitHub Actions**.
2. Point DNS at GitHub Pages: `A` records for `mahdtech.com` to `185.199.108.153`, `185.199.109.153`, `185.199.110.153` and `185.199.111.153`, and a `CNAME` from `www` to `mahdtech.github.io`. If DNS stays on Cloudflare, set these records to DNS only (grey cloud).
3. Once the certificate is issued, tick **Enforce HTTPS**.

`static/CNAME` keeps the custom domain on each deploy.
