# Corrections to `cso_un_dialogue_report.docx`

Two passages to replace before the report circulates. Neither changes the
report's conclusions; both correct statements that do not survive checking.

---

## 1. Replace the passage headed "The copy-paste submissions"

**Why.** The current text describes "thirteen near-identical submissions from
different organizations, apparently a coordinated campaign." Checked against the
data, that is wrong in three ways. The near-duplicate detection that produced it
was computed on a raw word-count matrix with function words retained, which on a
corpus of responses to one structured questionnaire flagged 10,768 of 71,631
possible pairs — 15% of the corpus. Thirteen is the number of *organizations*
signing one coalition submission, not the number of documents. And the "Stop AI"
petition cluster referred to elsewhere does not exist as described: there are two
Stop AI submissions and they share about a third of their vocabulary.

With stopwords removed and the matrix tf-idf weighted, the detector prints
**8 pairs** above the 0.85 threshold. Those 8 pairs involve **8 distinct
documents** in **3 groups** — the two counts coinciding by accident, which is
the kind of ambiguity that produced "thirteen" in the first place. Keep the
three numbers apart:

| | Documents | Pairs |
|---|---|---|
| AI-safety coalition | 1412, 1425, 1592, 1619 | 6 |
| Asociación Chilena de IA | 505, 60 | 1 |
| Partial overlap (0.888) | 1087, 1062 | 1 |
| **Total** | **8 documents** | **8 pairs** |

A third number applies if you decide to deduplicate: keeping one document per
group removes **4** (n = 375), or **5** if the 0.888 pair is also treated as
duplicate (n = 374). The effect reported below was measured both ways and is
the same.

**Replacement text:**

> **Repeat filings.** Some submissions are near-identical to others, and we chose
> to keep them all. Corrected detection identifies eight such documents, in three
> groups.
>
> The largest is a joint submission by a coalition of thirteen organizations
> working on AI safety, filed four separate times: once under the Future of Life
> Institute's name, once under The Future Society's, once under Pour Demain's,
> and once under AI Safety Connect's alone. The four documents are 99.8%
> identical. Three of them name the full coalition openly in the organization
> field; the fourth does not, which is why groups like this have to be found by
> comparing text rather than by reading the names organizations file under. The
> second group is a Chilean association that submitted the same document twice.
> The third is a pair of submissions sharing about half their wording.
>
> None of this is misconduct. Filing a coalition's agreed text under several
> signatories' names is ordinary practice, and most of these filings say so. But
> it matters for measurement. A theme's percentage is meant to indicate how much
> of civil society's writing concerns it, and one argument filed four times
> counts four times. Coordinating thirteen signatories and filing repeatedly
> requires the kind of organizational capacity that most civil society
> organizations report lacking, so leaving repeat filings uncorrected would
> quietly weight the analysis toward the best-resourced submitters — the
> opposite of what this report is trying to see.
>
> We measured the effect. Keeping one copy of each group and dropping the
> redundant filings moves no theme by more than 0.11 percentage points, and
> changes the ordering of the themes not at all — with one exception. The
> exception is the theme these submissions are themselves about — frontier AI
> and existential risk — which falls from [A]% to [B]%, a reduction of roughly
> a quarter. The four coalition documents alone account for a third of that
> theme's measured size.
>
> This cuts against one of our own findings rather than for it. The contraction
> of frontier-risk language between civil society's submissions and the official
> programme is somewhat smaller than the headline comparison suggests, because
> the civil society side of that comparison is inflated by repeat filing. No
> other finding in this report is affected.

**The affected theme is "Frontier AI & existential risk."** It was identified in
a refitted model, so confirm the correspondence against your own before
publishing, but the identification is not in doubt: after the four coalition
filings, the documents loading most heavily on it are AI Safety Asia, CeSIA,
Concordia AI, PauseAI Global, the Center for AI Risk Management & Alignment,
MIRI and CAIDP — the same population the report describes under that theme. Its
distinctive words are *capable, frontier, incident, safety, coordination,
channel, voluntary, autonomous, member, catastrophic, rapid*.

Note for anyone reading the coalition submission itself: it never uses the word
"frontier." It writes about cross-border incident communication and response —
"cross-border" meaning risks that cross jurisdictions, not border control — and
about risks from advanced AI systems. The frontier vocabulary in this theme
comes from the other organizations loading on it. The two registers are the same
concern expressed differently, which is why the model groups them.

### Fill [A] and [B] from your own model, not from this note

[A] is the theme's published share (4.2% in the report as it stands). [B] must
be computed on the model the report was built from — the figures quoted while
this correction was being prepared, 3.1% falling to 2.3%, come from a refitted
model and do not match the published table. It is one line, not a refit:

```r
ids  <- as.character(voice$meta$.doc_id)
drop <- which(ids %in% c("1425", "1592", "1619", "60"))   # keep one per group
round(colMeans(final$chosen_model$theta[-drop, ]) * 100, 2)
```

Read [B] off the frontier theme's column. Add `"1062"` to `drop` if you also
treat the 0.888 pair as duplicate; on the refitted model that changed nothing
beyond the second decimal.

**Table 4 needs rebuilding** on the same basis: eight documents in three groups,
not thirteen, and the per-theme differences above.

---

## 3. DEFERRED to the final report — report both numbers where the claim is about breadth

**Not for this version.** Recorded here so it is not lost.

The report defines a theme's percentage as the share of *text*, not the share of
organizations, and under that definition every filing counts and the published
figure is correct. But the report also uses these percentages for a different
claim — that frontier risk "sits eleventh", read as evidence about what civil
society prioritises. That is a claim about breadth of concern, which the
definition does not license once one argument is filed four times.

For the final report: give this one theme both figures side by side — all
filings, and one copy per group — and say which supports which claim. The first
answers "how much of the text"; the second answers "how widely held". Put the
caveat in §6.2 beside the "eleventh" sentence, not only in "Checking the
analysis", because percentages travel without their methods section.

This keeps the information complete and lets a reader reverse the judgement,
which is the practical test. It costs one extra column on one theme and two
sentences; it does not require recomputing the report.

---

## 2. Fix the derivation of 379 in the Methodology section

**Why.** The report says 379 English-language submissions were obtained by
"filtering 20 non-English submissions from an initial 400." That subtraction
gives 380. The missing step is a minimum-length filter applied before language
detection.

Verified chain: 400 published rows; one document falls below the 50-character
minimum (submission 253, Citizen Digital Foundation, 44 characters, consisting
only of checkbox residue — "x Safe, secure and trustworthy AI; x"); of the
remaining 399, cld2 detects 20 as non-English (9 Spanish, 8 French, 1 Russian,
2 Chinese); 379 remain.

**Replacement text:**

> Of the 400 submissions published, one was excluded for containing no prose —
> only the residue of the form's checkboxes — and a further 20 were set aside as
> non-English, leaving 379 for analysis.

**And qualify the sampling claim.** The sentence "The 379 submissions are not a
sample: they are every English-language civil society submission the UN
published" should read "every English-language civil society submission the UN
published that contained analysable text."

The side-event count needs the same treatment where it appears: 56 concept notes
were published and 55 analysed, the exclusion being a Spanish-language proposal
from IAméricas.
