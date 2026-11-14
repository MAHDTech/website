{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Fonts used by Typst for the PDFs and social cards.
  # The website serves subsetted WOFF2 copies of the same fonts (see the `fonts` script).
  typstFonts = "--font-path ${pkgs.inter}/share/fonts/truetype --font-path ${pkgs.jetbrains-mono}/share/fonts/truetype";

  fontTools = pkgs.python3.withPackages (ps: [
    ps.fonttools
    ps.brotli
  ]);

  # What `generate` reads and writes, for the freshness check in enterShell.
  # Templates count because the search index comes from a full zola build.
  generateStamp = "${config.devenv.state}/generate.stamp";
  generateInputs = [
    "data"
    "resume"
    "content"
    "templates"
    "config.toml"
    "devenv.nix"
  ];
  generateOutputs = [
    "static/resume/meta.json"
    "static/og/site.png"
    "static/resume.json"
    "static/resume.md"
    "static/llms.txt"
    "static/pagefind/pagefind.js"
  ];
in
{
  packages = with pkgs; [
    actionlint
    convco
    git
    jaq
    markdownlint-cli
    nixfmt
    pagefind
    poppler-utils
    prek
    tailwindcss_4
    typst
    watchexec
    yamllint
    zola
  ];

  git-hooks = {
    package = pkgs.prek;
    hooks = {
      nixfmt.enable = true;
      convco.enable = true;
      actionlint.enable = true;
      ripsecrets.enable = true;
      terra-templates = {
        enable = true;
        name = "terra-templates";
        entry = "${pkgs.writeShellScript "terra-templates" config.scripts.terra-templates.exec}";
        files = "^templates/";
      };
      # Tailwind only emits classes it finds in templates and JS.
      # The committed stylesheet must be rebuilt whenever those change.
      tailwind-css = {
        enable = true;
        name = "tailwind-css";
        entry = "${pkgs.writeShellScript "tailwind-css" config.scripts.css-check.exec}";
        files = "^(templates/|styles/|static/js/)";
        pass_filenames = false;
      };
      markdownlint = {
        enable = true;
        excludes = [ "^content/" ];
        settings.configuration = {
          MD013 = false;
        };
      };
      yamllint = {
        enable = true;
        settings.configuration = ''
          extends: default
          rules:
            line-length: disable
            brackets:
              forbid: non-empty
            truthy:
              allowed-values:
                - "true"
                - "false"
                - "on"
            indentation:
              indent-sequences: consistent
            comments:
              min-spaces-from-content: 1
            document-start:
              level: error
        '';
      };
    };
  };

  scripts.terra-templates.exec = ''
    set -euo pipefail
    targets=("$@")
    if [ "''${#targets[@]}" -eq 0 ]; then
      targets=(templates)
    fi
    if ${pkgs.gnugrep}/bin/grep -rnE '[a-zA-Z0-9_-]+="[{][^{%#]' "''${targets[@]}"; then
      echo "error: quoted Tera component expression detected in templates/" >&2
      exit 1
    fi
  '';

  scripts.css.exec = ''
    set -euo pipefail
    tailwindcss -i styles/input.css -o static/css/custom.css --minify
  '';

  # Rebuild the stylesheet; fail (so the hook asks for a re-stage) if it changed.
  scripts.css-check.exec = ''
    set -euo pipefail
    before="$(sha256sum static/css/custom.css 2>/dev/null || true)"
    tailwindcss -i styles/input.css -o static/css/custom.css --minify 2>/dev/null
    if [ "$before" != "$(sha256sum static/css/custom.css)" ]; then
      echo "static/css/custom.css was out of date and has been rebuilt; stage it and commit again." >&2
      exit 1
    fi
  '';

  # Subset to Latin plus the arrows and symbols the site uses (~65% smaller).
  scripts.fonts.exec = ''
    set -euo pipefail
    ranges="U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2190-21FF,U+2212,U+2215,U+2248,U+2318,U+25A0-25FF,U+FEFF,U+FFFD"
    subset() {
      ${fontTools}/bin/pyftsubset "$1" --flavor=woff2 --layout-features='*' --unicodes="$ranges" --output-file="$2"
    }
    mkdir -p static/fonts
    subset "${pkgs.inter}/share/fonts/truetype/InterVariable.ttf" static/fonts/Inter-Variable.woff2
    subset "${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono[wght].ttf" static/fonts/JetBrainsMono-Variable.woff2
    ls -l static/fonts
  '';

  # Full and short PDFs, plus their page counts for the download menu.
  scripts.resumes.exec = ''
    set -euo pipefail
    mkdir -p static/resume
    for variant in full short; do
      file="$(jaq --from yaml -r ".downloads.$variant.filename" data/resume.yaml)"
      typst compile --root . ${typstFonts} --input variant="$variant" resume/resume.typ "static/resume/$file"
      pages="$(pdfinfo "static/resume/$file" | awk '/^Pages:/ {print $2}')"
      printf '%s\t%s\n' "$variant" "$pages"
    done | jaq -Rn '[inputs | split("\t") | {key: "\(.[0])_pages", value: (.[1] | tonumber)}] | from_entries' > static/resume/meta.json
    echo "resumes: $(jaq -c . static/resume/meta.json)"
  '';

  # 1200x630 PNG social cards: one per post, plus the site and resume cards.
  scripts.og.exec = ''
    set -euo pipefail
    card() { typst compile --root . ${typstFonts} --ppi 144 "$@"; }
    mkdir -p static/og
    card --input kind=site resume/og.typ static/og/site.png
    card --input kind=resume resume/og.typ static/og/resume.png
    find content -name '*.md' ! -name '_index.md' | while read -r post; do
      out="static/og/''${post#content/}"
      mkdir -p "$(dirname "$out")"
      card --input kind=post --input post="/$post" resume/og.typ "''${out%.md}.png"
    done
  '';

  # /resume.json (JSON Resume), /resume.md and /llms.txt for AI agents and tools.
  scripts.exports.exec = ''
    set -euo pipefail
    jaq --from yaml -r --arg format json -f resume/export.jq data/resume.yaml > static/resume.json
    jaq --from yaml -r --arg format markdown -f resume/export.jq data/resume.yaml > static/resume.md

    base_url="$(jaq --from toml -r .base_url config.toml)"
    {
      echo "# $(jaq --from toml -r .title config.toml)"
      echo
      echo "> $(jaq --from toml -r .description config.toml)"
      echo
      echo "## Resume"
      echo
      echo "- [Resume (Markdown)]($base_url/resume.md): full resume as Markdown"
      echo "- [Resume (JSON Resume)]($base_url/resume.json): structured resume using the jsonresume.org schema"
      echo "- [Resume (web)]($base_url/resume/): interactive resume with PDF downloads"
      echo
      echo "## Posts"
      echo
      find content/posts -name '*.md' ! -name '_index.md' | sort | while read -r post; do
        awk '/^---$/ {n++; next} n == 1' "$post" \
          | jaq --from yaml -r --arg base "$base_url" --arg stem "$(basename "$post" .md)" \
            'select(.draft != true) | "- [\(.title)](\($base)/posts/\(.slug // $stem)/): \(.description // "")"'
      done
    } > static/llms.txt
  '';

  # Pagefind index for the Ctrl/Cmd+K palette during `zola serve`.
  # Production builds index public/ directly (see `build`).
  scripts.search.exec = ''
    set -euo pipefail
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    zola build --force --output-dir "$tmp/site" > /dev/null
    rm -rf static/pagefind
    pagefind --site "$tmp/site" --output-path static/pagefind --quiet
  '';

  # The stamp is taken before the run starts, so inputs edited mid-run stay newer
  # than it and the next shell regenerates. A failed run leaves no stamp.
  scripts.generate.exec = ''
    set -euo pipefail
    mkdir -p "$(dirname "${generateStamp}")"
    touch "${generateStamp}.pending"
    resumes
    og
    exports
    search
    mv "${generateStamp}.pending" "${generateStamp}"
  '';

  scripts.build.exec = ''
    set -euo pipefail
    generate
    css
    zola check
    zola build
    pagefind --site public
  '';

  scripts.check.exec = "zola check";

  # `devenv up`: zola serve plus watchers that rebuild CSS and generated files.
  # Skipped under `devenv test`, which would otherwise start them alongside the build.
  processes = lib.mkIf (!config.devenv.isTesting) {
    zola.exec = "zola serve";
    tailwind.exec = "tailwindcss -i styles/input.css -o static/css/custom.css --minify --watch=always";
    generate.exec = "watchexec --postpone --debounce 1s --watch data --watch resume --watch content --watch config.toml -- generate";
  };

  enterShell = ''
    if [ ! -f static/fonts/Inter-Variable.woff2 ] || [ ! -f static/fonts/JetBrainsMono-Variable.woff2 ]; then
      fonts
    fi
    if [ ! -f static/css/custom.css ] || [ -n "$(find styles templates static/js -newer static/css/custom.css -type f 2>/dev/null | head -1)" ]; then
      css
    fi
    # `generate` takes seconds (Typst, a full zola build, Pagefind), so only run it
    # when an output is missing or an input changed since the last run.
    if [ ! -f "${generateStamp}" ] \
      || [ -n "$(find ${lib.concatStringsSep " " generateInputs} -newer "${generateStamp}" 2>/dev/null | head -1)" ] \
      || ! ls ${lib.concatStringsSep " " generateOutputs} > /dev/null 2>&1; then
      generate
    fi
    echo
    echo "MAHDTech website"
    echo "  zola serve   preview at http://127.0.0.1:1111 (drafts: zola serve --drafts)"
    echo "  devenv up    zola serve + live CSS and PDF/card/export rebuilds"
    echo "  generate     rebuild PDFs, social cards, exports and search index"
    echo "  build        full production build into public/"
    echo "  devenv test  build and verify everything (what CI runs)"
  '';

  enterTest = ''
    set -euo pipefail
    css-check
    test "$(head -c 4 static/fonts/Inter-Variable.woff2)" = "wOF2"
    test "$(head -c 4 static/fonts/JetBrainsMono-Variable.woff2)" = "wOF2"

    build

    full_pages="$(jaq -r .full_pages static/resume/meta.json)"
    short_pages="$(jaq -r .short_pages static/resume/meta.json)"
    echo "PDF page counts: full=$full_pages (must be < 5), short=$short_pages (must be < 2)"
    test "$full_pages" -ge 1 && test "$full_pages" -lt 5
    test "$short_pages" -ge 1 && test "$short_pages" -lt 2

    terra-templates templates

    for f in index.html 404.html resume/index.html 2020/01/welcome/index.html CNAME \
      og/site.png og/resume.png og/posts/welcome.png \
      resume.json resume.md llms.txt pagefind/pagefind.js; do
      test -s "public/$f" || { echo "missing: public/$f" >&2; exit 1; }
    done
    for variant in full short; do
      test -s "public/resume/$(jaq --from yaml -r ".downloads.$variant.filename" data/resume.yaml)"
    done
    jaq -e '.basics.name and (.work | length > 0)' public/resume.json > /dev/null
    grep -q 'og:image" content="https://mahdtech.com/og/posts/welcome.png"' public/posts/welcome/index.html
    grep -q 'data-theme-choice="system"' public/resume/index.html
    for employer in VMware "Red Hat" Auth0 GitHub; do
      grep -q "$employer" public/resume/index.html
    done
    for post in $(grep -rlx 'draft: true' content/posts); do
      if [ -e "public/posts/$(basename "$post" .md)" ]; then
        echo "draft was published: $post" >&2
        exit 1
      fi
    done

    prek run --all-files
  '';
}
