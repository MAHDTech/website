# Website Agent Instructions

## Overview

This repository is the source for [mahdtech.com](https://mahdtech.com): a personal blog and an interactive resume, built with Zola, Tailwind CSS, Typst, and Pagefind, and hosted on GitHub Pages.

See the [README.md](./README.md) for how content is edited and what each generated file is for.

## Structure

- Blog posts live in `content/posts/<slug>.md`. Resume data, name, and contact details live in `data/resume.yaml`. Site title, menu, and description live in `config.toml`.
- Templates live in `templates/`. Shared markup belongs in a Tera component in `templates/macros/ui.html`, not repeated across templates.
- Styles live in `styles/input.css`. The built `static/css/custom.css` is committed and must be rebuilt whenever templates, styles, or `static/js/` change; the `tailwind-css` hook enforces this.
- PDFs, social cards, `resume.json`, `resume.md`, `llms.txt`, and the search index are generated and ignored by Git. Never edit or commit them.
- The skills dashboard at `skills.mahdtech.com` shares this site's design system. Keep token, class, and component names stable, or change both repositories together.

## devenv

Everything runs inside the `devenv` environment defined in `devenv.nix`.

| Command                              | Use it to                                                                          |
| ------------------------------------ | ---------------------------------------------------------------------------------- |
| `devenv --no-tui shell -- <command>` | Run one command inside the environment.                                            |
| `devenv --no-tui test`               | Build the site, verify the output, and run every hook. This is what CI runs.       |
| `devenv up`                          | Start `zola serve` plus the CSS and generated-file watchers. Stop it when done.    |

- Always pass `--no-tui` to `devenv` in automated or agent sessions so the command cannot hang on the interactive interface.
- Entering the shell runs `fonts`, `css`, and `generate` when their outputs are missing or stale, so the first entry is slow.
- If the port is busy, Zola falls back to the next free port from 1024 and prints the address it chose.

Scripts on `PATH` inside the shell:

| Script            | What it does                                                           |
| ----------------- | ---------------------------------------------------------------------- |
| `generate`        | Rebuild PDFs, social cards, exports, and the development search index. |
| `build`           | Full production build into `public/`.                                  |
| `css`             | Rebuild `static/css/custom.css`.                                       |
| `css-check`       | Rebuild the stylesheet and fail if it changed.                         |
| `fonts`           | Regenerate the subset WOFF2 fonts in `static/fonts/`.                  |
| `check`           | Run `zola check`.                                                      |
| `terra-templates` | Reject quoted Tera component arguments in `templates/`.                |

- Hooks are managed by `prek` through `git-hooks` in `devenv.nix`. Do not add the standalone `pre-commit` tool, and do not run individual linters by hand; add or change hooks in `devenv.nix`.
- Tera component arguments take bare braces: write `arg={value}`, never `arg="{value}"`, which renders the literal text.

### devenv.nix style

- **Define each top-level option once.** Group related settings in a single attribute set instead of repeating the key with dotted paths. Repeated keys trigger the statix `W20` warning.

  ```nix
  # Wrong: `scripts` is assigned three times.
  scripts.css.exec = "...";
  scripts.build.exec = "...";
  scripts.check.exec = "...";

  # Right: one `scripts` block.
  scripts = {
    css.exec = "...";
    build.exec = "...";
    check.exec = "...";
  };
  ```

- The same rule applies to `processes`, `packages`, `git-hooks.hooks`, and every other option.
- Dotted paths are fine inside a block for a single leaf, such as `css.exec = "...";`.
- Format with `nixfmt` and keep `statix check devenv.nix` clean. `nixfmt` runs as a hook.

## Development

- Use Conventional Commits for commit messages and PR titles: `type(scope): description`.
- Run `devenv --no-tui test` before pushing.
- Use relative links for files in this repository; never `file:///` paths.
