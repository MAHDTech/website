# Machine-readable resume exports, run by the `generate` devenv script:
#   jaq --from yaml -r --arg format json     -f resume/export.jq data/resume.yaml
#   jaq --from yaml -r --arg format markdown -f resume/export.jq data/resume.yaml
# Year and period rules match resume/lib.typ and templates/resume.html.

def months: split("-") | map(tonumber) | .[0] * 12 + .[1];

def years: ((now | strftime("%Y-%m") | months) - ([.experience[].start | months] | min)) / 12 | floor;

def month_name: ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][(split("-")[1] | tonumber) - 1] + " " + split("-")[0];

def period: "\(.start | month_name) – \(if .end == "" then "Present" else (.end | month_name) end)";

# Roles marked `hidden: true` stay in the YAML but are left out of every export.
.experience |= map(select(.hidden != true))
| (years | tostring) as $years
| (.profile.executive_summary | gsub("\\{years\\}"; $years)) as $summary
| if $format == "json" then
    # https://jsonresume.org/schema
    {
      "$schema": "https://raw.githubusercontent.com/jsonresume/resume-schema/v1.0.0/schema.json",
      basics: {
        name: .basics.name,
        label: .basics.subtitle,
        email: .basics.email,
        url: .basics.website,
        summary: $summary,
        location: { region: .basics.location },
        profiles: [{ network: "GitHub", username: .basics.github, url: .basics.github_url }]
      },
      work: [.experience[] | {
        name: .company,
        position: .role,
        location: .location,
        startDate: .start,
        endDate: (if .end == "" then null else .end end),
        summary: .short_summary,
        highlights: [.bullets[] | "\(.verb) \(.detail)"],
        keywords: .tech_stack
      } | with_entries(select(.value != null))],
      skills: [.skills[] | { name: .category, keywords: .items }],
      meta: { canonical: "\(.basics.website)/resume.json", version: "v1.0.0" }
    } | tojson
  elif $format == "markdown" then
    [
      "# \(.basics.name)",
      "",
      "\(.basics.subtitle) · \(.basics.location)",
      "",
      "- Email: \(.basics.email)",
      "- GitHub: \(.basics.github_url)",
      "- Website: \(.basics.website)",
      "- PDFs: \(.basics.website)/resume/\(.downloads.full.filename) (full), \(.basics.website)/resume/\(.downloads.short.filename) (short)",
      "",
      "## Summary",
      "",
      $summary,
      "",
      "## Experience",
      (.experience[] | (
        "",
        "### \(.company): \(.role)",
        "",
        "\(period) · \(.employment_type) · \(.location)",
        "",
        (.bullets[] | "- **\(.verb)** \(.detail)"),
        (if .note then "", "> Note: \(.note)" else empty end),
        "",
        "Stack: \(.tech_stack | join(", "))"
      )),
      "",
      "## Skills",
      "",
      (.skills[] | "- **\(.category)**: \(.items | join(", "))")
    ] | join("\n")
  else
    error("unknown format: \($format)")
  end
