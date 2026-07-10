# Echo Audit Protocol v1

A methodology for measuring whether civil society input into a multilateral governance
process is reflected in that process's agenda, deliberations, and outputs — or just recorded.

Built on Nelson's Computational Grounded Theory framework (Nelson, L.K. 2020. "Computational
Grounded Theory: A Methodological Framework." *Sociological Methods & Research* 49(1):3-42),
extended with a third, accountability-tracking phase.

## Overview: three phases

| Phase | Question it answers | Output |
|---|---|---|
| **Signal** | Who engaged, when, through what channel, before the governance moment? | Participation checkpoint log |
| **Voice** | What did participants actually say, independent of what happens to it? | Topic model + labeled themes + representative-document reading |
| **Echo** | Did Voice reach the room and show up in what got decided or produced? | Echo Score: full echo / partial echo / silence, per topic |

Each phase can run independently — Voice is a legitimate corpus analysis on its own, without
Signal or Echo — but the protocol's value is in chaining them: Voice tells you what was said,
Echo tells you whether saying it mattered.

---

## Phase 1: Signal

Track participation in the run-up to the governance moment. Minimum fields per checkpoint:
who (organization/individual), when, channel (written submission / registration / session
proposal / attendance), and whether the channel required prior resourcing (travel, translation,
technical capacity) that could itself bias who shows up.

*Not yet generalized into reusable code as of this version — currently ad hoc per project.*

---

## Phase 2: Voice

The computational grounded theory pass, run via `R/voice.R`'s `run_echo_voice()`.

### Step 2.0 — Corpus assembly
One document = one participant's full input (concatenate multi-question responses into a
single text field if the source data has them). Keep whatever metadata exists (organization
name, region, stakeholder type, submission channel) as columns alongside the text — Voice
doesn't require this metadata, but Echo and any prevalence-covariate analysis will want it.

### Step 2.1 — Language filtering
Detect language per document (`cld2::detect_language`). Restrict lexical/topic-modeling steps
to the majority language; set the rest aside for separate manual reading. Mixing languages
without filtering produces topics that are really just "this document is in language X," not
substantive themes — this was a real failure mode in the pilot run, not a hypothetical one.

### Step 2.2 — Near-duplicate detection
Cosine similarity on a bag-of-words DFM, threshold **0.85**. Flag pairs above threshold before
any lexical or topic analysis. Duplicate or near-duplicate submissions (coordinated campaigns,
joint-signatory coalition letters filed under multiple names) inflate apparent topic prevalence
and can masquerade as independent convergence. Decide explicitly whether to dedupe, downweight,
or analyze the cluster as its own category — don't let the topic model absorb it silently.

**This is not a hypothetical risk.** Two independent instances were found in the pilot corpora:
a "Stop AI" campaign-style petition cluster and a Future of Life Institute joint-signatory
submission cross-filed under 4 different organization names, which would have inflated one
topic's measured prevalence by roughly 4x if not caught.

### Step 2.3 — Lexical selection (difference of proportions)
Monroe, Colaresi & Quinn (2008) difference-of-proportions score between two natural subgroups
in the corpus (e.g., by region, by submission channel). Requires an actual meaningful two-group
split in the metadata — if none exists (as with the 55-document concept-note corpus, where the
side-event/thematic-cluster distinction wasn't reliably labeled), skip this step rather than
force a noisy proxy grouping and report it as a finding.

### Step 2.4 — Structural Topic Model + model selection
Fit STM across a range of candidate K values, **scaled to corpus size** — not a fixed range.
Rule of thumb from the two pilot runs: K should keep documents-per-topic somewhere in the
6–20 range. Below ~5 docs/topic, forcing a higher K collapses topics into generic frame-word
repetition (empirically confirmed: forcing K=20 on a 55-document corpus produced topics that
were almost all "govern, global, session, will" with no differentiator — see the CN_pilot
stress test in `examples/`).

Apply Nelson's two failure signs to pick K from the candidates, reading `labelTopics()` output
for each:
- **Too few topics**: distinct issues merge into one (a topic with no clear differentiator
  beyond corpus-wide frame words).
- **Too many topics**: one issue splits across near-duplicate topics (two topics whose
  highest-probability word lists are nearly identical).

Model selection is a qualitative judgment call, not a statistic — document it with the specific
evidence (which topics merged/split at which K) rather than asserting the choice.

### Step 2.5 — Guided deep reading
`findThoughts()` (or the theta-sorted equivalent) pulls the highest-weight documents per topic.
Read them — this is where "list of words" becomes "an actual argument someone is making."
Weight (theta) close to 1.0 means a document is a clean, nearly-monothematic example of that
topic; weight near 0.3–0.5 means a blended, more ambiguous case. `findThoughts()` deliberately
surfaces the high-weight end, so a topic that's incoherent even at its purest examples is a
signal to reconsider K, not just a hard-to-read topic.

### Step 2.6 — Pattern confirmation
Once steps 2.4–2.5 suggest a real pattern (not a template placeholder), test it deductively
across the *whole* corpus — not just the documents read closely. Readability/lexical-diversity
metrics (`quanteda.textstats`) are a lightweight, dictionary-free option; topic-weight-based
grouping (rather than raw metadata grouping) is often more informative once you have a
specific topic in mind.

---

## Phase 3: Echo

Cross-check Voice's topics against what the governance process actually did:

1. Map each Voice topic (or a curated shortlist of its highest-prevalence topics) onto the
   process's real program structure — official thematic clusters, session titles, whatever
   agenda document exists.
2. Classify each mapping as:
   - **Full echo** — topic got a dedicated session/cluster.
   - **Partial echo** — topic is diffused into a broader cluster with no dedicated slot.
   - **Silence** — topic has no corresponding cluster at all, despite measurable prevalence
     in Voice.
3. Cross-check against any outcome document, closing statement, or Co-Chairs' summary —
   does the topic appear in what actually got decided, or only in what was said?
4. Compute an **Echo Score**: share of prevalence-weighted Voice topics landing in each of the
   three categories. This is the number that goes on a poster.

*Not yet generalized into reusable code as of this version — currently a manual mapping
exercise per project (see `examples/geneva_2026_echo_table.md` for the worked example).*

---

## Known limitations (v1)

- Signal and Echo are still manual/ad hoc; only Voice is packaged as reusable code.
- Model selection (Step 2.4) requires human judgment reading `labelTopics()` output — it is
  deliberately not automated, per Nelson's own framework, and shouldn't be forced into a single
  metric (e.g., don't just pick the K that maximizes some coherence score without reading the
  actual topics).
- The near-duplicate threshold (0.85 cosine) and docs-per-topic guidance (6–20) are heuristics
  validated on two corpora (N=379 and N=55) — recalibrate if applying to very different corpus
  sizes or genres.
- Echo Score currently requires a human-curated mapping between Voice topics and the process's
  program structure; no NLP shortcut for this step has been built or validated yet.
