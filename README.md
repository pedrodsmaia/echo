# Echo Audit

A methodology and toolkit for measuring whether civil society input into a
multilateral governance process is **reflected** in that process's agenda and
outputs — or recorded and set aside.

Piloted on the UN's first Global Dialogue on AI Governance (Geneva, 6–7 July 2026),
where it found that the theme asking for participation was enlarged at every stage
while the themes asking for constraints on corporations, governments and AI
developers were reduced, softened or absorbed.

## The three phases

| Phase | Question it answers | Status |
|---|---|---|
| **Signal** | Who engaged, when, through what channel, before the governance moment? | Manual — see protocol §4.1 |
| **Voice** | What did participants actually say, independent of what happens to it? | `R/voice.R` |
| **Echo** | How much of that content is present in what the institution produced? | `R/echo.R` |

Voice discovers the themes from civil society's own words. The model is then
**frozen** and used as a fixed instrument to measure the institution's own
documents, so all collections are scored on one scale and are directly
comparable. Each theme is finally classified as **amplified**, **diluted**,
**engulfed** or **excluded**.

## What's here

- **`protocol/ECHO_AUDIT_PROTOCOL.md`** — the full methodology (v2), including
  the five required robustness checks and the open corrections.
- **`protocol/Echo_Audit_Methodology.docx`** — the same methodology as a
  formatted document, with the Geneva 2026 case study.
- **`R/voice.R`** — Phase 2. `run_echo_voice()`, `finalize_topic_model()`.
- **`R/echo.R`** — Phase 3. `echo_project()`, `echo_compare()`,
  `echo_lexical_check()`.
- **`examples/geneva_2026/`** — the pilot, end to end, with its data and its
  expected output. Run this first to confirm your install reproduces it.
- **`Echo_Audit_Presentation.pptx`** — a 12-slide introduction for a
  non-technical audience.

## Install

```bash
Rscript setup.R
```

Verified on R 4.6.1 with stm 1.3.8, quanteda 4.5.0, tm 0.7.18, SnowballC 0.7.1,
quanteda.textstats 0.97.2, cld2, LDAvis 0.3.2.

`tm` and `SnowballC` are not called anywhere in this repository, but
`stm::textProcessor()` requires both. Installing only the packages this code
imports directly is the first error a new user hits.

## Run the pilot

```bash
Rscript examples/geneva_2026/run.R
```

This reproduces the published analysis from the raw CSVs and prints the
diagnostics you should see: **98.4%** vocabulary coverage on the seven official
session notes, **87.2%** on the side-event proposals, and 56 proposals published
against 55 scored — the one dropped being a Spanish-language submission.

## Run it on your own process

You need three CSVs, one row per document:

1. **The civil society input** — what was submitted to the consultation.
2. **The institution's own documents** — session notes, agenda, outcome text.
3. Optionally, whatever sits between them (side events, working papers).

```r
source("R/voice.R"); source("R/echo.R")

voice <- run_echo_voice(
  csv_path             = "submissions.csv",
  text_cols            = c("q1", "q2", "q3"),   # concatenated into one document
  id_col               = "ID",
  meta_cols            = c("Organization", "Region"),
  k_candidates         = c(10, 15, 20, 25),     # scale to corpus size
  prevalence_covariate = "Region",
  output_dir           = "voice_output"
)

# Read the topics, choose K, then freeze the model:
final <- finalize_topic_model(voice, k = 20)

official <- echo_project(voice, final, "sessions.csv",
                         text_cols = "text_string", id_col = "ID",
                         collection_name = "Official programme")

echo_compare(voice, final, list(official))
```

### Two steps you have to do yourself

The method deliberately keeps a human in the loop at two points, and no
version of this toolkit will remove them.

**Choosing K.** Read `labelTopics()` for each candidate and apply the two
failure signs in the protocol — distinct issues merging, or one issue splitting
across near-identical topics. Corroborate with held-out likelihood, but do not
let a coherence score choose for you without reading the topics.

**Classifying outcomes.** Amplified / diluted / engulfed / excluded is a
reading, not a computation. The shares tell you how much moved; only the
documents tell you what happened to it. For any exclusion claim, run
`echo_lexical_check()` first — with a small institutional corpus a near-zero
share is weakly powered, while a defining term that occurs nowhere is direct
evidence.

## Licence

Code (`R/`, `examples/`) is MIT. The protocol and methodology documents
(`protocol/`) are CC BY 4.0. The pilot corpora are public UN documents,
redistributed for verification; rights in each submission remain with its
author. See [LICENSE](LICENSE).

## Citation

See [CITATION.cff](CITATION.cff).
