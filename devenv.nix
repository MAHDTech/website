{
  config,
  pkgs,
  ...
}:

{
  packages = [
    pkgs.zola
    pkgs.tailwindcss_4
    pkgs.typst
    pkgs.poppler-utils
    pkgs.pagefind
    pkgs.convco
    pkgs.prek
    pkgs.nixfmt
    pkgs.yamllint
    pkgs.markdownlint-cli
    pkgs.actionlint
    pkgs.inter
    pkgs.jetbrains-mono
    pkgs.woff2
    pkgs.git
    pkgs.curl
    pkgs.jq
  ];

  git-hooks = {
    package = pkgs.prek;
    hooks = {
      nixfmt.enable = true;
      convco.enable = true;
      actionlint.enable = true;
      terra-templates = {
        enable = true;
        name = "terra-templates";
        entry = "${pkgs.writeShellScript "terra-templates" config.scripts.terra-templates.exec}";
        files = "^templates/";
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

  scripts.fonts.exec = ''
    set -euo pipefail
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' EXIT
    install -m 0644 "${pkgs.inter}/share/fonts/truetype/InterVariable.ttf" "$tmp_dir/Inter-Variable.ttf"
    install -m 0644 "${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono[wght].ttf" "$tmp_dir/JetBrainsMono-Variable.ttf"
    woff2_compress "$tmp_dir/Inter-Variable.ttf"
    woff2_compress "$tmp_dir/JetBrainsMono-Variable.ttf"
    install -Dm 0644 "$tmp_dir/Inter-Variable.woff2" static/fonts/Inter-Variable.woff2
    install -Dm 0644 "$tmp_dir/JetBrainsMono-Variable.woff2" static/fonts/JetBrainsMono-Variable.woff2
  '';

  scripts.resumes.exec = ''
    set -euo pipefail
    mkdir -p static/resume
    typst compile --root . \
      --font-path "${pkgs.inter}/share/fonts/truetype" \
      --font-path "${pkgs.jetbrains-mono}/share/fonts/truetype" \
      --input variant=full \
      resume/resume.typ \
      static/resume/Matthew-Duncan-Resume-Full.pdf
    typst compile --root . \
      --font-path "${pkgs.inter}/share/fonts/truetype" \
      --font-path "${pkgs.jetbrains-mono}/share/fonts/truetype" \
      --input variant=short \
      resume/resume.typ \
      static/resume/Matthew-Duncan-Resume-Short.pdf
  '';

  scripts.css.exec = ''
    set -euo pipefail
    tailwindcss -i styles/input.css -o static/css/custom.css --minify
  '';

  scripts.build.exec = ''
    set -euo pipefail
    if [ ! -f static/fonts/Inter-Variable.woff2 ] || [ ! -f static/fonts/JetBrainsMono-Variable.woff2 ]; then
      fonts
    fi
    resumes
    css
    zola check
    zola build
    pagefind --site public
  '';

  scripts.check.exec = "zola check";
  scripts.serve.exec = "zola serve --drafts";

  enterShell = ''
    if [ ! -f static/fonts/Inter-Variable.woff2 ] || [ ! -f static/fonts/JetBrainsMono-Variable.woff2 ]; then
      fonts
    fi
    if [ ! -f static/resume/Matthew-Duncan-Resume-Full.pdf ] \
      || [ ! -f static/resume/Matthew-Duncan-Resume-Short.pdf ] \
      || [ data/resume.yaml -nt static/resume/Matthew-Duncan-Resume-Full.pdf ] \
      || [ resume/resume.typ -nt static/resume/Matthew-Duncan-Resume-Full.pdf ]; then
      resumes
    fi
    if [ ! -f static/css/custom.css ] || [ styles/input.css -nt static/css/custom.css ]; then
      css
    fi
    echo "MAHDTech Website & Agentic Resume Development Environment"
    echo "Available commands: zola serve, build, resumes, css, fonts, check, devenv --no-tui test"
    zola --version
    typst --version
    pagefind --version
  '';

  enterTest = ''
    set -euo pipefail
    test -f static/fonts/Inter-Variable.woff2
    test -f static/fonts/JetBrainsMono-Variable.woff2
    test "$(head -c 4 static/fonts/Inter-Variable.woff2)" = "wOF2"
    test "$(head -c 4 static/fonts/JetBrainsMono-Variable.woff2)" = "wOF2"
    resumes
    full_pages="$(pdfinfo static/resume/Matthew-Duncan-Resume-Full.pdf | awk '/^Pages:/ {print $2}')"
    short_pages="$(pdfinfo static/resume/Matthew-Duncan-Resume-Short.pdf | awk '/^Pages:/ {print $2}')"
    echo "Verified PDF page counts -> Full: $full_pages pages (< 5), Short: $short_pages pages (< 2)"
    test "$full_pages" -ge 1 && test "$full_pages" -lt 5
    test "$short_pages" -ge 1 && test "$short_pages" -lt 2
    css
    git diff --exit-code -- static/css/custom.css
    terra-templates templates
    zola check
    zola build
    pagefind --site public
    test -f public/index.html
    test -f public/resume/index.html
    test -f public/2020/01/welcome/index.html
    test -f public/resume/Matthew-Duncan-Resume-Full.pdf
    test -f public/resume/Matthew-Duncan-Resume-Short.pdf
    test -f public/pagefind/pagefind.js
    grep -q "Deterministic AI Harnesses" public/index.html
    grep -q "Matthew-Duncan-Resume-Full.pdf" public/resume/index.html
    grep -q "Matthew-Duncan-Resume-Short.pdf" public/resume/index.html
    grep -q 'data-theme-choice="system"' public/resume/index.html
    grep -q "VMware" public/resume/index.html
    grep -q "Red Hat" public/resume/index.html
    grep -q "Auth0" public/resume/index.html
    grep -q "GitHub" public/resume/index.html
    prek run --all-files
  '';
}
