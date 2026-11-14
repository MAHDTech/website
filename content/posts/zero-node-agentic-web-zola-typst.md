---
title: "Zero-Node Agentic Web Stack: Zola, Tailwind v4, and Single-Source Typst PDFs"
date: 2026-11-14
description: "Rebuilding mahdtech.com from first principles in Rust, Nix devenv, Tailwind CSS v4, and Typst - 100% code-defined with zero npm_modules."
taxonomies:
  tags:
    - "zola"
    - "rust"
    - "nix"
    - "typst"
  categories:
    - "Web Architecture"
extra:
  category: "Stack Architecture"
  image: "/images/posts/zero-node-zola-stack.svg"
  image_alt: "Build pipeline schematic showing YAML data and Markdown compiling through Zola, Tailwind v4, and Typst into static HTML and PDFs"
  digest: "A personal engineering blog and resume should still build cleanly five years from now. Dropping Node.js bundlers in favor of Zola, standalone Tailwind v4, and Typst inside Nix devenv makes the entire site reproducible in under two seconds."
  key_points:
    - "Zero package.json or node_modules: every binary is cryptographically pinned via Nix devenv."
    - "One data/resume.yaml drives the interactive web dossier and both Full and Short Typst PDFs."
    - "Modern CSS light-dark(), anchored popovers, and scroll-driven animations replace heavy client frameworks."
---

## Why Static Sites Rot

Most developer blogs do not fail because Markdown goes out of style. They rot because a simple content edit two years later collides with 1,400 transitive `node_modules` dependencies, deprecated Webpack plugins, and broken Sass native bindings.

When revamping **mahdtech.com**, the primary engineering constraint was longevity: **100% defined in code, DRY, fast, and reproducible from two commands**:

```bash
devenv shell
zola serve
```

## Single-Source-of-Truth Resume Architecture

Maintaining an interactive HTML resume alongside downloadable PDFs usually creates immediate drift: you update a role bullet on the website and forget the LaTeX or Word document, or vice versa. Furthermore, hiring workflows need two distinct lengths:

- **Full Dossier (`< 5 pages`)**: Comprehensive architectural context, metrics, and per-engagement technology stacks for technical hiring managers.
- **Short Executive Brief (`< 2 pages`)**: High-signal one-page summary for rapid screening.

Instead of duplicating prose, every role, metric, summary statement, and skill category lives once in `data/resume.yaml`:

```yaml
---
basics:
  name: "Matthew Duncan"
  subtitle: "Senior Platform Engineer"
experience:
  - company: "Freelance"
    short_summary: "Platform engineering, Kubernetes modernization, and AI harness systems."
    highlights:
      - lead: "Automated"
        detail: "multi-cluster policy validation across immutable environments."
```

At build time, two compilers consume that exact YAML tree:

1. **Zola (`load_data(path="data/resume.yaml")`)** renders `/resume/` with instant client-side Full/Short density toggling, skill-tag cross-filtering across roles, and adaptive Light/Dark theming.
2. **Typst (`typst compile --input variant=full|short`)** typesets `Matthew-Duncan-Resume-Full.pdf` (3 pages) and `Matthew-Duncan-Resume-Short.pdf` (1 page) using the exact same self-hosted Inter and JetBrains Mono fonts.

## Modern Platform CSS Over Client Bloat

Browser engines in 2026 natively ship primitives that previously demanded kilobytes of JavaScript state libraries:

```css
@supports (color: light-dark(white, black)) {
  :root {
    color-scheme: light dark;
    --canvas: light-dark(#f4f7fb, #060a12);
    --accent-cyan: light-dark(#0284c7, #06b6d4);
  }
}

@media (prefers-reduced-motion: no-preference) {
  @view-transition {
    navigation: auto;
  }
}
```

Combining CSS `light-dark()` tokens with `<meta name="color-scheme">`, native HTML `[popover]` download menus with CSS Anchor Positioning, and Pagefind WASM static indexing delivers an app-like engineering interface with zero framework runtime.
