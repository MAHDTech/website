// Authoritative Typst Dual-Variant Resume Generator for Matthew Duncan (MAHDTech)
// Single Source of Truth: /data/resume.yaml
// Variants:
//   --input variant=full  -> Detailed Dossier (< 5 pages target -> 3 pages)
//   --input variant=short -> Condensed Executive Brief (< 2 pages target -> 1 page)

#let data = yaml("/data/resume.yaml")
#let variant = sys.inputs.at("variant", default: "full")
#let is_short = variant == "short"

// Palette
#let col_obsidian = rgb("#090D16")
#let col_ink = rgb("#0F172A")
#let col_body = rgb("#1E293B")
#let col_muted = rgb("#475569")
#let col_subtle = rgb("#64748B")
#let col_border = rgb("#CBD5E1")
#let col_surface = rgb("#F8FAFC")
#let col_accent = rgb("#0284C7")
#let col_cyan_bright = rgb("#38BDF8")

#set document(
  title: data.basics.name + " - " + data.basics.title + (if is_short { " (Executive Summary)" } else { " (Full Resume)" }),
  author: data.basics.name,
)

#set page(
  paper: "a4",
  margin: if is_short {
    (top: 0mm, bottom: 9.5mm, left: 0mm, right: 0mm)
  } else {
    (top: 12.5mm, bottom: 13mm, left: 14.5mm, right: 14.5mm)
  },
  header: context {
    if not is_short and here().page() > 1 {
      set text(font: "JetBrains Mono", size: 7.2pt, fill: col_subtle)
      grid(
        columns: (1fr, auto),
        align(left)[#upper(data.basics.name) \/\/ PLATFORM ENGINEER DOSSIER],
        align(right)[#data.basics.email · github.com/#data.basics.github],
      )
      v(-2pt)
      line(length: 100%, stroke: 0.5pt + col_border)
    }
  },
  footer: context {
    let pad_x = if is_short { 13mm } else { 0mm }
    pad(x: pad_x)[
      #line(length: 100%, stroke: 0.5pt + col_border)
      #v(2pt)
      #set text(font: "JetBrains Mono", size: 7pt, fill: col_subtle)
      #grid(
        columns: (1fr, auto),
        align(left)[
          #data.basics.website · Generated from canonical YAML via Typst (#if is_short { "Executive Edition" } else { "Full Dossier" })
        ],
        align(right)[
          Page #counter(page).display("1 / 1", both: true)
        ],
      )
    ]
  },
)

#set text(
  font: "Inter",
  size: if is_short { 8pt } else { 8.75pt },
  fill: col_body,
  lang: "en",
)

#set par(
  justify: false,
  leading: if is_short { 0.44em } else { 0.50em },
)

#let section_heading(code, title) = {
  v(if is_short { 4.5pt } else { 7pt })
  block(breakable: false, width: 100%)[
    #grid(
      columns: (auto, 1fr),
      column-gutter: 6pt,
      align: horizon,
      box(
        fill: col_obsidian,
        inset: (x: 4.5pt, y: 1.8pt),
        radius: 2pt,
      )[
        #text(font: "JetBrains Mono", size: if is_short { 6.4pt } else { 7pt }, weight: "bold", fill: col_cyan_bright)[#code]
      ],
      text(
        font: "JetBrains Mono",
        size: if is_short { 8.6pt } else { 9.8pt },
        weight: "bold",
        tracking: 0.06em,
        fill: col_ink,
      )[#upper(title)],
    )
    #v(-2.5pt)
    #line(length: 100%, stroke: 0.8pt + col_accent)
    #v(if is_short { 2pt } else { 3.5pt })
  ]
}

// ============================================================================
// VARIANT 1: SHORTENED EXECUTIVE EDITION (< 2 PAGES -> STRICTLY 1 PAGE)
// ============================================================================
#if is_short [
  #block(
    width: 100%,
    fill: col_obsidian,
    inset: (x: 13mm, top: 6.8mm, bottom: 5.8mm),
    below: 0pt,
  )[
    #grid(
      columns: (1fr, auto),
      align: (left + horizon, right + horizon),
      [
        #text(font: "Inter", size: 16.5pt, weight: "bold", fill: white, tracking: -0.02em)[#data.basics.name]
        #h(6pt)
        #box(
          stroke: 0.6pt + col_cyan_bright,
          radius: 2pt,
          inset: (x: 5pt, y: 1.6pt),
        )[
          #text(font: "JetBrains Mono", size: 6.5pt, weight: "semibold", fill: col_cyan_bright)[EXECUTIVE BRIEF]
        ]
        #v(2pt)
        #text(font: "Inter", size: 9.4pt, style: "italic", fill: col_cyan_bright)[#data.basics.subtitle]
      ],
      [
        #set text(font: "JetBrains Mono", size: 7.2pt, fill: rgb("#E2E8F0"))
        #stack(
          dir: ttb,
          spacing: 2.8pt,
          [#text(fill: col_cyan_bright)[LOC \/\/] #data.basics.location],
          [#text(fill: col_cyan_bright)[MAIL \/\/] #link("mailto:" + data.basics.email)[#data.basics.email]],
          [#text(fill: col_cyan_bright)[GH \/\/] #link(data.basics.github_url)[github.com/#data.basics.github] · #link(data.basics.website)[mahdtech.com]],
        )
      ],
    )
  ]
  #block(width: 100%, height: 1.6pt, fill: col_cyan_bright, above: 0pt, below: 0pt)[]

  #pad(x: 13mm, top: 2.2mm)[
    #section_heading("01", "Executive Profile")
    #text(size: 7.95pt, fill: col_body)[#data.profile.executive_summary]

    #section_heading("02", "Work Experience")
    #stack(
      dir: ttb,
      spacing: 3.8pt,
      ..data.experience.map(role => {
        block(breakable: false, width: 100%)[
          #grid(
            columns: (1fr, auto),
            column-gutter: 8pt,
            [
              #text(weight: "bold", size: 8.3pt, fill: col_ink)[#role.company]
              #text(fill: col_subtle)[ · ]
              #text(style: "italic", weight: "semibold", size: 8pt, fill: col_accent)[#role.role (#role.employment_type)]
            ],
            align(right)[
              #text(font: "JetBrains Mono", size: 7pt, fill: col_muted)[#role.period | #role.location]
            ],
          )
          #v(1pt)
          #text(size: 7.65pt, fill: col_body)[
            #role.short_summary
            #h(4pt)
            #text(font: "JetBrains Mono", size: 6.5pt, fill: col_muted)[[#role.short_tech.join(" · ")]]
          ]
        ]
      })
    )

    #section_heading("03", "Core Technical Capabilities")
    #grid(
      columns: (1fr, 1fr, 1fr),
      column-gutter: 6.5pt,
      row-gutter: 4.5pt,
      ..data.skills.map(group => {
        block(
          breakable: false,
          width: 100%,
          fill: col_surface,
          stroke: 0.5pt + col_border,
          radius: 2.5pt,
          inset: (x: 5.5pt, y: 3.6pt),
        )[
          #text(font: "JetBrains Mono", size: 6.7pt, weight: "bold", fill: col_accent)[[#group.code] ]
          #text(font: "Inter", size: 7.4pt, weight: "bold", fill: col_ink)[#group.category]
          #v(1.2pt)
          #text(size: 7pt, fill: col_muted)[#group.items.join(", ")]
        ]
      })
    )
  ]
] else [
  // ============================================================================
  // VARIANT 2: FULL ENGINEERING DOSSIER (< 5 PAGES TARGET -> 3 PAGES)
  // ============================================================================
  #block(
    width: 100%,
    fill: col_obsidian,
    radius: 4pt,
    inset: (x: 15pt, y: 12pt),
  )[
    #grid(
      columns: (1fr, auto),
      column-gutter: 12pt,
      align: (left + horizon, right + horizon),
      [
        #text(font: "Inter", size: 20pt, weight: "bold", fill: white, tracking: -0.02em)[#data.basics.name]
        #v(2.5pt)
        #text(font: "Inter", size: 10.8pt, style: "italic", fill: col_cyan_bright)[#data.basics.title]
        #v(2pt)
        #text(font: "JetBrains Mono", size: 7.4pt, fill: rgb("#94A3B8"))[#data.basics.subtitle]
      ],
      [
        #set text(font: "JetBrains Mono", size: 7.6pt, fill: rgb("#E2E8F0"))
        #stack(
          dir: ttb,
          spacing: 3.5pt,
          [#text(fill: col_cyan_bright)[LOCATION \/\/] #data.basics.location],
          [#text(fill: col_cyan_bright)[EMAIL \/\/] #link("mailto:" + data.basics.email)[#data.basics.email]],
          [#text(fill: col_cyan_bright)[GITHUB \/\/] #link(data.basics.github_url)[github.com/#data.basics.github]],
          [#text(fill: col_cyan_bright)[WEB \/\/] #link(data.basics.website)[mahdtech.com/resume]],
        )
      ],
    )
  ]

  #section_heading("01", "Profile")
  #stack(
    dir: ttb,
    spacing: 3.5pt,
    ..data.profile.statements.map(stmt => {
      grid(
        columns: (114pt, 1fr),
        column-gutter: 8pt,
        text(font: "JetBrains Mono", size: 7.3pt, weight: "bold", fill: col_accent)[#stmt.category],
        text(size: 8.65pt, fill: col_body)[#stmt.text],
      )
    })
  )

  #section_heading("02", "Work Experience")
  #stack(
    dir: ttb,
    spacing: 7pt,
    ..data.experience.map(role => {
      block(width: 100%)[
        #block(breakable: false, width: 100%)[
          #grid(
            columns: (1fr, auto),
            column-gutter: 8pt,
            text(size: 9.8pt, weight: "bold", fill: col_ink)[#role.company],
            align(right)[
              #text(font: "JetBrains Mono", size: 7.6pt, weight: "medium", fill: col_muted)[#role.period | #role.location]
            ],
          )
          #v(0.8pt)
          #text(size: 8.7pt, style: "italic", weight: "semibold", fill: col_accent)[
            #role.role (#role.employment_type)
          ]
          #v(2.2pt)
        ]
        #stack(
          dir: ttb,
          spacing: 2.5pt,
          ..role.bullets.map(b => {
            grid(
              columns: (7pt, 1fr),
              column-gutter: 4pt,
              text(font: "JetBrains Mono", size: 7.5pt, fill: col_accent)[▸],
              text(size: 8.5pt, fill: col_body)[#strong(b.verb) #b.detail],
            )
          })
        )
        #if "note" in role [
          #v(2.5pt)
          #block(
            fill: col_surface,
            stroke: (left: 2pt + col_accent),
            inset: (left: 6.5pt, right: 6pt, y: 2.8pt),
            width: 100%,
          )[
            #text(size: 8pt, style: "italic", fill: col_muted)[#strong[Note:] #role.note]
          ]
        ]
        #v(2.8pt)
        #block(
          breakable: false,
          fill: col_surface,
          stroke: 0.5pt + col_border,
          radius: 2.5pt,
          inset: (x: 6.5pt, y: 2.8pt),
          width: 100%,
        )[
          #text(font: "JetBrains Mono", size: 7.2pt, weight: "bold", fill: col_ink)[Tech Stack: ]
          #text(font: "Inter", size: 7.9pt, fill: col_muted)[#role.tech_stack.join(", ").]
        ]
      ]
    })
  )

  #section_heading("03", "Skills & Capabilities")
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 7pt,
    row-gutter: 5.5pt,
    ..data.skills.map(group => {
      block(
        breakable: false,
        width: 100%,
        fill: col_surface,
        stroke: 0.5pt + col_border,
        radius: 2.5pt,
        inset: (x: 6.5pt, y: 5pt),
      )[
        #text(font: "JetBrains Mono", size: 6.8pt, weight: "bold", fill: col_accent)[[#group.code] ]
        #text(font: "Inter", size: 8.3pt, weight: "bold", fill: col_ink)[#group.category]
        #v(2pt)
        #if "details" in group [
          #stack(
            dir: ttb,
            spacing: 1.8pt,
            ..group.details.map(d => text(size: 7.7pt, fill: col_body)[• #d])
          )
        ] else [
          #text(size: 7.8pt, fill: col_body)[#group.items.join(", ").]
        ]
      ]
    })
  )
]
