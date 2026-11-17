// Shared helpers for resume.typ and og.typ.
// The web resume (templates/resume.html) and resume/*.jq derive the same
// values from data/resume.yaml; keep the rules in step if you change them.

// Roles marked `hidden: true` stay in the YAML but are dropped here, so the
// PDFs, social cards, years and role counts never see them.
#let resume-data = {
  let data = yaml("/data/resume.yaml")
  data.experience = data.experience.filter(r => {
    not r.at("hidden", default: false)
  })
  data
}

// "2023-07" -> months since year 0, so ranges are a simple subtraction.
#let to-months(ym) = {
  let parts = ym.split("-")
  int(parts.at(0)) * 12 + int(parts.at(1))
}

// The build passes `--input today=YYYY-MM` because devenv pins SOURCE_DATE_EPOCH
// to 1980, which datetime.today() would report. The fallback serves editor previews.
#let today-months = {
  let given = sys.inputs.at("today", default: none)
  if given != none {
    to-months(given)
  } else {
    let t = datetime.today()
    t.year() * 12 + t.month()
  }
}

#let first-start-months(data) = calc.min(..data.experience.map(r => to-months(
  r.start,
)))

// Whole years since the earliest role started.
#let years-experience(data) = calc.div-euclid(
  today-months - first-start-months(data),
  12,
)

// Replace the "{years}" placeholder used in prose fields.
#let fill(text, data) = text.replace("{years}", str(years-experience(data)))

#let month-names = (
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
)

#let fmt-month(ym) = {
  let parts = ym.split("-")
  month-names.at(int(parts.at(1)) - 1) + " " + parts.at(0)
}

// "Jul 2023 – Present"
#let fmt-period(role) = (
  fmt-month(role.start)
    + " – "
    + if role.end == "" { "Present" } else { fmt-month(role.end) }
)
