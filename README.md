# Echo Audit

A methodology and toolkit for measuring whether civil society input into a
multilateral governance process is reflected in that process's agenda,
deliberations, and outputs — or just recorded.

Piloted on the UN's first Global Dialogue on AI Governance (Geneva, 6-7 July 2026).

## What's here

- **`protocol/ECHO_AUDIT_PROTOCOL.md`** — the full methodology, in Markdown.
- **`protocol/Echo_Audit_Methodology.docx`** — the same methodology as a
  formatted document, including the Geneva 2026 case study.
- **`Echo_Audit_Presentation.pptx`** — a 12-slide deck introducing the project
  for a non-technical audience.
- **`R/voice.R`** — the reusable, parameterized implementation of the
  Voice phase (see below).
- **`examples/`** — worked example runs.

## The three phases

| Phase | Question it answers | Status |
|---|---|---|
| **Signal** | Who engaged, when, through what channel, before the governance moment? | Manual/ad hoc |
| **Voice** | What did participants actually say, independent of what happens to it? | Reusable code (`R/voice.R`) |
| **Echo** | Did Voice reach the room and show up in what got decided or produced? | Manual/ad hoc |

Full detail on all three phases, including the model-selection criteria and
near-duplicate detection thresholds, is in `protocol/ECHO_AUDIT_PROTOCOL.md`.

## Quick start (Voice phase)

Requires R with: `stm`, `quanteda`, `quanteda.textstats`, `dplyr`, `readr`,
`tidyr`, `stringr`, `LDAvis`, `cld2`.

```r
source("R/voice.R")

result <- run_echo_voice(
  csv_path = "your_corpus.csv",       # one row per document
  text_cols = "text_string",           # column(s) to analyze
  id_col = "ID",
  meta_cols = c("Organization"),       # optional metadata to retain
  k_candidates = c(5, 8, 10),          # candidate topic counts -- scale to corpus size
  prevalence_covariate = NULL,         # set if you have a reliable grouping variable
  output_dir = "voice_output"
)

# Read labelTopics(result$stm_models[["kN"]]) for each candidate, apply the
# two model-selection signs in the protocol doc, then:
final <- finalize_topic_model(result, k = 8)
final$topic_table   # ranked themes with FREX words and prevalence
```

This writes an interactive topic browser (LDAvis) and per-topic representative-
document reading files to `output_dir`.

## License

TODO -- add a license before making this repository public.
