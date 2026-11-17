// PDF resume generated from data/resume.yaml.
//   --input variant=full  -> every role in detail (target: under 5 pages)
//   --input variant=short -> one-page overview     (target: under 2 pages)
// Built by the `resumes` devenv script; `devenv test` checks the page counts.

#import "lib.typ": fill, fmt-period, resume-data

#let data = resume-data
#let person = data.basics
#let variant = sys.inputs.at("variant", default: "full")
#let is-short = variant == "short"

// Print-safe palette: dark ink on white, one accent colour.
#let col-ink = rgb("#0F172A")
#let col-body = rgb("#1E293B")
#let col-muted = rgb("#475569")
#let col-rule = rgb("#CBD5E1")
#let col-wash = rgb("#F1F5F9")
#let col-accent = rgb("#0369A1")

#let body-size = if is-short { 8.6pt } else { 9.4pt }
#let mono = "JetBrains Mono"

#set document(
  title: person.name
    + " – Resume ("
    + if is-short { "short" } else { "full" }
    + ")",
  author: person.name,
)

#set page(
  paper: "a4",
  margin: if is-short { (x: 13mm, top: 11mm, bottom: 12mm) } else {
    (x: 15mm, top: 14mm, bottom: 15mm)
  },
  header: context {
    if here().page() > 1 {
      set text(font: mono, size: 7pt, fill: col-muted)
      grid(
        columns: (1fr, auto),
        person.name, person.email,
      )
      v(-4pt)
      line(length: 100%, stroke: 0.5pt + col-rule)
    }
  },
  footer: context {
    set text(font: mono, size: 7pt, fill: col-muted)
    grid(
      columns: (1fr, auto),
      link(
        person.website + "/resume/",
      )[#person.website.replace("https://", "")/resume],
      counter(page).display("1 / 1", both: true),
    )
  },
)

#set text(font: "Inter", size: body-size, fill: col-body, lang: "en")
#set par(
  justify: false,
  leading: if is-short { 0.5em } else { 0.58em },
  spacing: if is-short { 0.55em } else { 0.8em },
)
#set block(spacing: if is-short { 0.55em } else { 0.8em })
#show link: set text(fill: col-accent)

#let section(title) = {
  v(if is-short { 7pt } else { 11pt }, weak: true)
  block(breakable: false, sticky: true, below: if is-short { 6pt } else {
    8pt
  })[
    #text(
      font: mono,
      size: if is-short { 8pt } else { 8.6pt },
      weight: "bold",
      tracking: 0.08em,
      fill: col-accent,
      upper(title),
    )
    #v(-1pt)
    #line(length: 100%, stroke: 0.6pt + col-rule)
  ]
}

#let tech-line(items) = text(
  font: mono,
  size: if is-short { 6.9pt } else { 7.4pt },
  fill: col-muted,
  items.join(" · "),
)

// Short edition: everything on one line to save vertical space.
#let role-heading-compact(role) = grid(
  columns: (1fr, auto),
  column-gutter: 10pt,
  [#text(
      size: body-size + 0.8pt,
      weight: "bold",
      fill: col-ink,
      role.company,
    ) #text(fill: col-muted)[·] #text(
      weight: "semibold",
      fill: col-accent,
      role.role,
    ) #text(fill: col-muted)[· #role.employment_type]],
  align(right, text(
    font: mono,
    size: 7pt,
    fill: col-muted,
  )[#fmt-period(role) · #role.location]),
)

#let role-heading(role) = grid(
  columns: (1fr, auto),
  column-gutter: 10pt,
  row-gutter: 2.5pt,
  text(size: body-size + 1.4pt, weight: "bold", fill: col-ink, role.company),
  align(right, text(
    font: mono,
    size: 7.4pt,
    fill: col-muted,
    fmt-period(role),
  )),

  text(weight: "semibold", fill: col-accent)[#role.role #text(
      weight: "regular",
      fill: col-muted,
    )[· #role.employment_type]],
  align(right, text(size: 7.6pt, fill: col-muted, role.location)),
)

// ---------------------------------------------------------------- header --
#block(below: if is-short { 10pt } else { 14pt })[
  #grid(
    columns: (1fr, auto),
    column-gutter: 16pt,
    align: (left + bottom, right + bottom),
    [
      #text(
        size: if is-short { 22pt } else { 26pt },
        weight: "bold",
        fill: col-ink,
        tracking: -0.02em,
        person.name,
      )
      #v(-2pt)
      #text(
        size: if is-short { 11pt } else { 12pt },
        fill: col-accent,
        weight: "medium",
        person.subtitle,
      )
    ],
    [
      #set text(size: 8pt, fill: col-muted)
      #set par(leading: 0.45em)
      #person.location \
      #link("mailto:" + person.email, person.email) \
      #link(person.github_url)[github.com/#person.github] · #link(person.website, person.website.replace("https://", ""))
    ],
  )
  #v(if is-short { 4pt } else { 6pt })
  #line(length: 100%, stroke: 1.4pt + col-accent)
]

// --------------------------------------------------------------- profile --
#section("Profile")
#fill(data.profile.executive_summary, data)

#if not is-short {
  v(6pt)
  grid(
    columns: (1fr, 1fr),
    column-gutter: 14pt,
    row-gutter: 6pt,
    ..data.profile.statements.map(s => [
      #text(font: mono, size: 7.4pt, weight: "bold", fill: col-accent, upper(
        s.category,
      )) \
      #text(size: body-size - 0.4pt, s.text)
    ])
  )
}

// ------------------------------------------------------------ experience --
#section("Experience")
#for (i, role) in data.experience.enumerate() {
  if i > 0 {
    v(if is-short { 5pt } else { 9pt }, weak: true)
    line(length: 100%, stroke: (
      paint: col-rule,
      thickness: 0.4pt,
      dash: "dotted",
    ))
    v(if is-short { 5pt } else { 9pt }, weak: true)
  }
  if is-short {
    block(breakable: false)[
      #role-heading-compact(role)
      #v(1pt)
      #role.short_summary #h(3pt) #tech-line(role.short_tech)
    ]
  } else {
    block(breakable: false, sticky: true, role-heading(role))
    v(4pt)
    list(
      indent: 2pt,
      body-indent: 6pt,
      spacing: 4pt,
      marker: text(fill: col-accent, "▸"),
      ..role.bullets.map(b => [#strong(b.verb) #b.detail]),
    )
    if "note" in role {
      v(4pt)
      block(
        fill: col-wash,
        inset: (x: 7pt, y: 4.5pt),
        radius: 2pt,
        width: 100%,
        text(
          size: body-size - 0.6pt,
          style: "italic",
          fill: col-muted,
        )[#strong[Note:] #role.note],
      )
    }
    v(4pt)
    block(tech-line(role.tech_stack))
  }
}

// ---------------------------------------------------------------- skills --
#section("Skills")
#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 12pt,
  row-gutter: if is-short { 6pt } else { 9pt },
  ..data.skills.map(group => block(breakable: false)[
    #text(
      weight: "bold",
      fill: col-ink,
      size: body-size - 0.2pt,
      group.category,
    ) \
    #text(size: body-size - 0.8pt, fill: col-muted, group.items.join(", "))
  ])
)
