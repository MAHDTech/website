# MAHDTech Website & Agentic Resume

Source repository for [mahdtech.com](https://mahdtech.com), built as a zero-Node, 100%-code-defined static engineering blog and interactive resume.

## Tech Stack

- **Static Site Generator**: [Zola](https://www.getzola.org/) (Rust, Tera v2 components, YAML frontmatter)
- **Styling**: [Tailwind CSS v4](https://tailwindcss.com/) standalone CLI (`styles/input.css` -> `static/css/custom.css`) with adaptive `light-dark()` tokens
- **PDF Typesetting**: [Typst](https://typst.app/) (`resume/resume.typ`) generating both Full (`< 5 pages`) and Short (`< 2 pages`) resumes from a single YAML source
- **Static Search**: [Pagefind](https://pagefind.app/) WASM search index
- **Toolchain & CI Parity**: [devenv](https://devenv.sh/) (Nix) + `prek` Git hooks
- **Hosting**: Cloudflare Workers Static Assets (`wrangler.toml`)

## Quickstart

Enter the reproducible Nix shell and start the live-reloading Zola server:

```bash
devenv shell
zola serve
```

Then open:

- `http://127.0.0.1:1111/` for the **Blog** (Markdown dispatches with YAML frontmatter)
- `http://127.0.0.1:1111/resume/` for the **Interactive Resume** (System/Light/Dark theme toggle + Full & Short PDF downloads)

## Common Commands

Inside `devenv shell`, the following helper scripts are available:

```bash
build    # Compile fonts (if missing), Typst PDFs, Tailwind CSS, Zola site, and Pagefind index
css      # Recompile styles/input.css -> static/css/custom.css
resumes  # Recompile Full and Short PDF resumes from data/resume.yaml via Typst
fonts    # Regenerate self-hosted Inter & JetBrains Mono variable WOFF2 fonts
check    # Run zola check (validates templates, internal links, and anchors)
```

Run the full automated verification and lint suite from outside or inside the shell:

```bash
devenv --no-tui test
```

## Writing a Blog Post

Create a Markdown file in `content/posts/<slug>.md` using **YAML frontmatter** (`---`):

```yaml
---
title: "Your Dispatch Title"
date: 2026-11-14
description: "Short summary shown on the main blog card and social previews."
taxonomies:
  tags:
    - "kubernetes"
    - "rust"
  categories:
    - "Platform Engineering"
extra:
  category: "Platform Engineering"
  image: "/images/posts/zero-node-zola-stack.svg"
  image_alt: "Accessible description of the post cover illustration"
  digest: "Optional one-sentence TL;DR rendered in the Agentic Synthesis callout."
  key_points:
    - "Optional first key takeaway."
    - "Optional second key takeaway."
  github_issue_id: 2
---

Write your Markdown content here...
```

When `extra.github_issue_id` is set, comments on that GitHub issue in `MAHDTech/website` are loaded onto the post page automatically.

## Updating the Resume (Single Source of Truth)

All resume content lives in `data/resume.yaml`. Neither HTML templates nor Typst layout files contain hardcoded resume prose.

1. Edit `data/resume.yaml` (identity, metrics, summary, experience entries, or skill categories).
2. Run `resumes` inside `devenv shell` (or `build`) to regenerate:
   - `static/resume/Matthew-Duncan-Resume-Full.pdf` (`< 5 pages` target)
   - `static/resume/Matthew-Duncan-Resume-Short.pdf` (`< 2 pages` target)
3. Reload `/resume/` in `zola serve` to view the updated web resume immediately.
