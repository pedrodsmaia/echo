# Echo Audit Protocol v2

A method for measuring whether civil society input into a multilateral governance process is
*reflected* in that process's agenda and outputs — or recorded and set aside.

Built on Nelson's Computational Grounded Theory framework (Nelson, L.K. 2020. "Computational
Grounded Theory: A Methodological Framework." *Sociological Methods & Research* 49(1):3-42),
extended with a third, accountability-tracking phase.

Pilot: the UN's first Global Dialogue on AI Governance, Geneva, 6-7 July 2026.

---

## What v2 changes

v1 described a method that has since been built and run. It is now behind the analysis it was
meant to document, and on one finding it contradicts it.

1. **Phase 3 is implemented, not manual.** v1 stated that the Echo mapping was hand-curated and
   that "no NLP shortcut for this step has been built or validated." It has been. Phase 3 now
   freezes the topic model and uses it as a fixed measuring instrument.
2. **The outcome scale is replaced.** *Full echo / partial echo / silence* asked only whether a
   theme appeared. It is replaced by **amplified / diluted / engulfed / excluded**, which asks
   what happened to it. On the pilot, the old scale put four of six themes in one bucket.
3. **The v1 environment finding is withdrawn.** See "Correction to v1" below.
4. **The claim is narrowed to match the evidence.** v1 was subtitled "whether civil society input
   *shapes* outcomes." The method measures correspondence between two corpora, not causation.

---

## Scope: what the audit measures, and what it does not

Multilateral processes increasingly invite written input from civil society as a matter of
procedural legitimacy. An invitation to submit is not a mechanism for verifying that the
submission mattered. Human-rights and algorithmic impact assessments evaluate a technology or
policy once deployed; none asks the upstream question — did the process that claims to have
listened change its structure, agenda or output?

Echo Audit answers a narrower version, and the narrowness is the point. It establishes what civil
society wrote, then how much of that content is present in what the institution wrote. A theme
can be present because the institution was responsive, because states pushed it independently, or
because it is house vocabulary. Separating those requires Signal plus process tracing, and is not
delivered by the measurement alone.

**The finding the method delivers cleanly is the negative one.** Absence is not explained away by
convergent framing or institutional style: if a theme carries ten per cent of civil society's
writing and near-zero of the institution's, that gap is real regardless of why the shared themes
are shared.

---

## Overview: three phases

| Phase | Question it answers | Output | Status |
|---|---|---|---|
| **Signal** | Who engaged, when, through what channel, before the governance moment? | Participation checkpoint log | Ad hoc |
| **Voice** | What did participants actually say, independent of what happens to it? | Topic model, named themes, representative-document reading | `R/voice.R` |
| **Echo** | How much of that content is present in what the institution produced? | Per-theme share in each corpus + outcome classification | Implemented |

Voice is a legitimate corpus analysis on its own. The protocol's contribution is chaining the
three: Voice establishes what was said, Echo establishes what became of it.

The design is grounded theory used to **build** the instrument, followed by measurement with that
instrument **held fixed**. Nothing is allowed to emerge from the institutional documents: civil
society's categories are imposed on them deliberately, because the question is precisely whether
the institution's agenda accommodates those categories.

---

## Phase 1: Signal

Track participation in the run-up to the governance moment. Minimum fields per checkpoint: who
(organization or individual), when, channel (written submission / registration / session proposal
/ attendance), and whether the channel required prior resourcing (travel, translation, technical
capacity) that could itself bias who is able to participate at all.

Signal is what would license a causal reading of Echo, and it is the phase still done by hand.
Treat its absence as a limit on interpretation, not a formatting gap.

---

## Phase 2: Voice

The computational grounded theory pass, run via `R/voice.R`'s `run_echo_voice()`.

### Step 2.0 — Corpus assembly
One document = one participant's full input; concatenate multi-question responses into a single
text field. Retain all available metadata as columns — Voice doesn't need it, Echo and any
prevalence covariate will.

Check each metadata column is actually variable before planning to use it. In the pilot,
`Stakeholder category` read "Civil Society" for all 400 rows and was useless; `Region` was well
populated and usable.

### Step 2.1 — Language filtering
Detect language per document (`cld2::detect_language`). Restrict lexical/topic-modeling steps to
the majority language; set the rest aside for separate manual reading. Mixing languages without
filtering produces topics that mean "this document is in language X" rather than a substantive
theme — a real failure mode in the pilot, not a hypothetical one.

**Record the count of documents set aside and reconcile it against the corpus total.** This
reconciliation failed in the pilot; see Open corrections.

### Step 2.2 — Near-duplicate detection
Cosine similarity on a bag-of-words DFM, threshold **0.85**, before any lexical or topic
analysis. Coordinated campaigns and joint-signatory letters filed under several names inflate a
theme's apparent prevalence and can masquerade as independent convergence. Decide explicitly
whether to drop, downweight, or treat the cluster as its own category — then test that the
decision does not carry a finding.

Not hypothetical: the pilot corpora contained a "Stop AI" campaign-style petition cluster and a
Future of Life Institute joint-signatory submission cross-filed under 4 organization names, which
would have inflated one topic's measured prevalence roughly 4x if not caught.

### Step 2.3 — Lexical selection (difference of proportions)
Monroe, Colaresi & Quinn (2008) difference-of-proportions between two substantively meaningful
subgroups. Requires a reliably populated two-group split; where none exists, skip the step and
report that as a finding rather than forcing a noisy proxy.

In the pilot this was skipped for the 55 concept notes, which had no dependable split. It should
**not** have been skipped for the submissions, where `Region` supports a Global South / Western
Europe and Other States contrast directly relevant to the research question.

### Step 2.4 — Structural Topic Model and choice of K
Fit STM across candidate K scaled to corpus size, not a fixed range. Target roughly **6-20
documents per topic**. Below about five, a higher K collapses topics into frame-word repetition —
confirmed by forcing K=20 onto a 55-document corpus, which produced twenty topics reducible to
"govern, global, session, will."

Choose K by reading `labelTopics()` against Nelson's two failure signs:
- **Too few topics:** distinct issues merge, with no differentiator beyond corpus-wide frame words.
- **Too many topics:** one issue splits across topics whose highest-probability word lists are
  near-identical.

**Then corroborate the reading with held-out likelihood, and report both.** The judgment stays
primary — a coherence maximum without reading the topics is a known failure mode — but a
convergence between the two is worth far more than either alone, and a divergence is information.

### Step 2.5 — Guided deep reading
For each retained topic, surface and read its highest-weight documents in full (`findThoughts()`
or the theta-sorted equivalent). This is where a ranked word list becomes an argument someone is
making, and where the theme gets its name. Weight near 1.0 = clean, near-monothematic example;
0.3-0.5 = blended case. A topic incoherent even at its purest examples is a signal to revisit K.

Topics that turn out to be artifacts of the collection instrument — checkbox fragments, form
boilerplate — are identified here, excluded, and their combined share reported.

### Step 2.6 — Pattern confirmation
Test the pattern deductively across the entire corpus, not the documents read closely: how large
each theme really is, which themes co-occur, and whether an apparent pattern is carried by a few
vivid submissions or by many. Grouping by topic weight is usually more informative than grouping
by raw metadata once a specific hypothesis is in hand.

---

## Phase 3: Echo

Freeze the model. Align each institutional corpus to the fitted vocabulary and score every
document for its share of each civil society theme, using identical preprocessing throughout.
Because one instrument measures all corpora, their percentages are directly comparable.

| Parameter | Value | Note |
|---|---|---|
| Instrument | Frozen STM | Fitted on the civil society corpus only, then applied unchanged. |
| Vocabulary coverage | Report per corpus | Pilot: 86% of proposals, 98% of official notes. |
| Missing-theme check | Independent model | Fit a separate model to the institutional corpus to confirm it holds no major theme the instrument would miss. |
| Substantial engagement | > 15% of a document | 3x the 5% uniform share at K=20. Report sensitivity at 10% and 20%. |

### Four outcomes

A share that shrinks does not say *how* a theme was lost. Classify on the mechanism, using the
shares together with the close reading.

| Outcome | Definition | Evidence required |
|---|---|---|
| **Amplified** | Larger share of the institutional corpus than of civil society's. | Share ratio above 1, plus a reading of whether the framing survived the enlargement. |
| **Diluted** | Keeps its place, but its demands are softened. | The subject is named; the specific instrument asked for is replaced by a weaker one. |
| **Engulfed** | Absorbed into a larger agenda that changes what it is about. | Vocabulary of the theme appears only in service of a different question. |
| **Excluded** | No meaningful presence. | Near-zero share **and** a lexical check: the theme's defining terms do not occur. |

The lexical check carries more weight than the share for exclusion claims: with a handful of
short institutional documents a 0.0% projection is weakly powered, whereas a term that appears
nowhere is direct evidence.

An outcome classification is an interpretive act and must be recorded as one: written decision
rules, applied by a second reader, with agreement between the two reported.

---

## Robustness protocol

Five checks. The first four were run in the pilot; the fifth was not, and is the one a reviewer
will ask for first.

1. **Held-out likelihood across K.** Hold back a tenth of the text and score each candidate.
   Report the curve alongside the reading-based choice.
2. **Re-run the full comparison at neighbouring K.** Locate each theme's counterpart by vocabulary
   similarity. A finding that does not survive is reported as not surviving — in the pilot the
   direction of change for gender was inconsistent across K, so no size claim is made for it.
3. **Remove the near-duplicate cluster and refit.** Report both the re-measured shares and whether
   every theme reappears in a model rebuilt without those documents.
4. **Rebuild without stemming.** State which themes reappear with recognizable vocabulary and
   which do not, rather than claiming the set as a whole is robust.
5. **Institutional-style control.** Run session notes from an *unrelated* process by the same
   institution through the same fixed instrument. Without it, an amplified theme cannot be
   distinguished from house vocabulary.

**Why check 5 is safe to run:** the test is asymmetric. If the control shows the same enlargement
in an unrelated process, the *amplification* findings are lost. The *reduction* findings are
untouched, because institutional style does not explain absences. Since the central claim rests on
the reductions, the worst case costs a secondary result — a reason to run the control, not to
defer it.

---

## Worked application: Geneva 2026

Three corpora from one process: the English-language civil society written submissions; the
concept notes proposing side events, from outside organizations; and the seven session notes
written by the UN secretariat (four thematic clusters, the session on governance initiatives, two
plenaries). A 20-topic model was fitted on the submissions — 18 substantive topics, two checkbox
fragments — then frozen and applied to the other two corpora.

| Theme | CSO submissions | Official programme | Ratio |
|---|---:|---:|---:|
| Environment & sustainability | 4.5% | 11.1% | x2.5 |
| Implementation & interoperability | 8.9% | 20.9% | x2.3 |
| Structural inclusion & capacity | 11.9% | 25.8% | x2.2 |
| Gender & labour justice | 4.4% | 3.4% | not robust |
| Grassroots inclusion & youth | 7.3% | 2.9% | x0.40 |
| Data rights & corporate power | 10.9% | 3.5% | x0.32 |
| Legal & administrative accountability | 6.1% | 1.7% | x0.28 |
| Frontier AI & existential risk | 4.2% | 1.0% | x0.24 |

The ordering is itself a finding. Civil society's largest theme is a demand for participation, not
a warning about a specific technology; catastrophic risk from advanced systems — the theme most
visible in public debate — sits eleventh of eighteen. And the filtering is not where one would
expect it: the side-event proposals track the submissions reasonably well, while the sharpest
re-weighting happens in the secretariat's own framing documents.

| Theme | Outcome | What happened |
|---|---|---|
| Structural inclusion | Amplified | Enlarged at every stage, but reframed: the submissions treat inclusion as a question of power ("a real voice"), the official notes as a programme of assistance. |
| Environment & sustainability | Amplified | The one theme both the side events and the official programme enlarge. Carried by a high-level session co-organized by Campaign for Nature with the French government, UNEP, ITU and UNESCO. |
| Data rights & corporate power | Engulfed | The second-largest theme of the submissions is the core subject of no side-event proposal. In the official notes its subject matter survives only as access gaps and open-source policy. Ownership, compensation and moratorium do not occur. |
| Legal accountability | Diluted | Carried upward by the side events, where governments were among its advocates, then softened into due diligence, impact assessments and the UN Guiding Principles, with much of the discussion routed through child protection. Binding rules are not discussed. |
| Frontier AI risk | Diluted, demand excluded | The side events swapped moratorium activists for safety institutes; the official notes kept "safe, secure and trustworthy" and attached it to a session on interoperability. "Ban", "moratorium" and "catastrophic" occur in none of the seven notes. |
| Grassroots inclusion & youth | Diluted | From participation to protection. Youth-led side events preserved the participatory framing; the official programme treats young people as subjects of protection and targets of capacity-building. |
| Gender & labour justice | Reframed | Volume roughly unchanged and not robust across K, so no size claim is made. What changes is kind: a structural analysis of power becomes a listing of vulnerable groups. |

Themes that ask for constraints on corporations, governments or developers were reduced, softened
or absorbed. The theme asking for participation was enlarged.

### Correction to v1

v1 reported the environmental and biodiversity theme as **silence** — "no cluster existed" — and
presented two organizations' pre-event prediction that "there is not even an option to select
ecological impacts of AI" as confirmed by the agenda.

**That classification is withdrawn.** The theme accounts for 11.1% of the official programme as
one of Cluster 1's five lenses, and it is the single theme that *grows* across both institutional
corpora. It is amplified, not silent.

The v1 reading mistook the absence of a dedicated cluster for the absence of the theme — precisely
the error the four-outcome scale exists to prevent. Note also what the corrected finding costs the
organizations concerned: the theme grew where it acquired state and inter-governmental sponsors,
which is a claim about the price of admission, not about responsiveness.

---

## Open corrections (blocking)

To resolve before any version of the pilot circulates.

1. **The corpus counts do not reconcile.** The published files hold **400** submissions and **56**
   proposals, with no empty rows and no duplicate identifiers; the analysis reports 379 and 55.
   The stated derivation (400 minus 20 non-English) gives 380, not 379. Likely cause: documents
   silently dropped when the vocabulary is pruned — check `prepDocuments()$docs.removed`. Until
   resolved, the claim that the corpus is "not a sample" but every published submission cannot be
   made.
2. **The institutional-style control has not been run.** Check 5 of the robustness protocol.
3. **Document weighting is unstated.** The seven official notes range from about 1,700 to 8,400
   characters. Whether a corpus share is a plain mean of document shares or weighted by length
   changes the headline figures at this n. Report both.
4. **The no-stemming rebuild is oversold.** Two of six themes did not reappear with recognizable
   vocabulary. One is informative rather than fatal: legal accountability resolved into a Latin
   American and African vocabulary, consistent with the side events, where the argument was
   carried by Costa Rica's MICITT with ECLAC and by African policy institutes. That is a lead
   about who carries the demand, and should be pursued rather than reported as noise.
5. **Interpretive coding is single-reader.** Theme naming and outcome classification were done by
   one person. Written rules, a second reader, and reported agreement are the standard next step.

---

## Standing limitations

- **Self-selection.** Only organizations that knew about the consultation and had the capacity to
  respond appear. The corpus represents civil society as it reached the institution, not civil
  society.
- **Institutional prose, not proceedings.** Session notes describe how an agenda is framed, not
  what is said in the rooms.
- **Proposals are offers, not selections.** Side-event concept notes show what was pitched, not
  what the institution accepted.
- **The instrument is bounded by its source.** It can only detect themes civil society raised. The
  independent-model check bounds this, it does not remove it.
- **Shares are of text, not of organizations.** A theme at 11.9% accounts for that share of what
  was written, not the proportion of organizations that mentioned it.
- **Small institutional corpora.** With seven documents, percentages are descriptions, not
  estimates; no confidence interval should be attached to them.
- **Heuristics are calibrated on two corpora.** The 0.85 threshold and the 6-20 documents-per-topic
  guidance should be recalibrated for substantially different sizes or genres.

---

## Reproduction

R with: `stm`, `quanteda`, `quanteda.textstats`, `dplyr`, `readr`, `tidyr`, `stringr`, `LDAvis`,
`cld2`. One CSV per corpus, one row per document, an identifier column and one or more text
columns.

```r
source("R/voice.R")

result <- run_echo_voice(
  csv_path             = "submissions.csv",
  text_cols            = c("q1", "q2", "q3"),   # concatenated per Step 2.0
  id_col               = "ID",
  meta_cols            = c("Organization", "Region"),
  k_candidates         = c(10, 15, 20, 25),     # scale to corpus size
  prevalence_covariate = "Region",
  output_dir           = "voice_output",
  seed                 = 1234
)

# Read labelTopics() for each candidate, apply the two failure signs,
# corroborate against held-out likelihood, then fix K:
final <- finalize_topic_model(result, k = 20)
final$topic_table
```

Phase 3 then aligns each institutional corpus to `final`'s vocabulary, scores it against the
frozen model, and reports vocabulary coverage per corpus. The outcome classification is read off
the shares together with the close reading — it is not produced by the code, and should not be.
