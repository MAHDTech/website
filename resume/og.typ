// Social preview cards (1200x630 PNG when compiled with --ppi 144).
// Inputs:
//   kind=site                         -> home page / fallback card
//   kind=resume                       -> /resume/ card
//   kind=post post=/content/posts/x.md -> one card per blog post
// Built by the `generate` devenv script into static/og/.

#import "lib.typ": resume-data, years-experience

#let kind = sys.inputs.at("kind", default: "site")
#let person = resume-data.basics

#let col-bg = rgb("#070B12")
#let col-grid = rgb("#16213A")
#let col-ink = rgb("#ECF3FF")
#let col-muted = rgb("#93A6C4")
#let col-cyan = rgb("#38BDF8")
#let col-emerald = rgb("#34D399")

#set page(width: 600pt, height: 315pt, margin: 0pt, fill: col-bg)
#set text(font: "Inter", fill: col-ink)

// Read a post's YAML frontmatter (between the first two "---" lines).
#let frontmatter(path) = {
  let parts = read(path).split("\n---")
  yaml(bytes(parts.at(0).trim("---").trim()))
}

// Blueprint grid and accent strip shared by every card.
#let backdrop = {
  for x in range(0, 600, step: 24) {
    place(dx: x * 1pt, line(start: (0pt, 0pt), end: (0pt, 315pt), stroke: 0.5pt + col-grid))
  }
  for y in range(0, 315, step: 24) {
    place(dy: y * 1pt, line(start: (0pt, 0pt), end: (600pt, 0pt), stroke: 0.5pt + col-grid))
  }
  place(
    bottom,
    rect(width: 100%, height: 4pt, fill: gradient.linear(col-cyan, col-emerald)),
  )
}

#let brand = grid(
  columns: (auto, auto),
  column-gutter: 8pt,
  align: horizon,
  image("/static/images/logo.svg", width: 22pt),
  text(font: "JetBrains Mono", size: 11pt, weight: "bold")[MAHDTech],
)

#let chip(label) = box(
  stroke: 0.6pt + col-cyan,
  radius: 3pt,
  inset: (x: 6pt, y: 3.5pt),
  text(font: "JetBrains Mono", size: 7.5pt, fill: col-cyan, upper(label)),
)

#let footer-line(left) = grid(
  columns: (1fr, auto),
  text(size: 9pt, fill: col-muted, left),
  text(font: "JetBrains Mono", size: 9pt, fill: col-cyan, person.website.replace("https://", "")),
)

// Shrink long titles so they always fit in three lines.
#let title-size(title) = if title.len() > 80 { 24pt } else if title.len() > 50 { 28pt } else { 34pt }

#backdrop
#pad(x: 36pt, top: 30pt, bottom: 28pt)[
  #block(height: 100%)[
    #if kind == "post" {
      let fm = frontmatter(sys.inputs.at("post"))
      let category = fm.at("extra", default: (:)).at("category", default: "Blog")
      block(brand)
      v(1fr)
      block(chip(category))
      v(10pt)
      block(text(size: title-size(fm.title), weight: "bold", tracking: -0.02em, hyphenate: false, fm.title))
      if "description" in fm {
        v(8pt)
        block(width: 92%, text(size: 11pt, fill: col-muted, fm.description))
      }
      v(1fr)
      footer-line(person.name + " · " + str(fm.date))
    } else if kind == "resume" {
      block(brand)
      v(1fr)
      block(chip("Resume"))
      v(10pt)
      block(text(size: 38pt, weight: "bold", tracking: -0.02em, person.name))
      v(6pt)
      block(text(size: 15pt, fill: col-cyan, person.subtitle))
      v(14pt)
      block(text(
        font: "JetBrains Mono",
        size: 10pt,
        fill: col-muted,
        str(years-experience(resume-data)) + "+ years · " + str(resume-data.experience.len()) + " roles · Full and short PDF editions",
      ))
      v(1fr)
      footer-line(person.location)
    } else {
      block(brand)
      v(1fr)
      block(text(size: 38pt, weight: "bold", tracking: -0.02em, person.name))
      v(6pt)
      block(text(size: 15pt, fill: col-cyan, person.subtitle))
      v(14pt)
      block(text(size: 11pt, fill: col-muted, "Engineering notes and resume: Kubernetes, immutable infrastructure, Rust, NixOS and AI harnesses."))
      v(1fr)
      footer-line("Blog · Resume")
    }
  ]
]
