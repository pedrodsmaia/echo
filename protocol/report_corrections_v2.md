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

With stopwords removed and the matrix tf-idf weighted, eight documents in three
groups sit above the 0.85 threshold.

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
> exception is the theme these submissions are themselves about: frontier AI
> safety, incident reporting and voluntary coordination, which falls from 3.1%
> to 2.3%, a reduction of roughly a quarter. The four coalition documents alone
> account for a third of that theme's measured size.
>
> This cuts against one of our own findings rather than for it. The contraction
> of frontier-safety language between civil society's submissions and the
> official programme is somewhat smaller than the headline comparison suggests,
> because the civil society side of it is inflated by repeat filing. No other
> finding in this report is affected.

**Before publishing, confirm one mapping.** The affected theme was identified in
a refitted model, where it carries the words *frontier, incident, safety,
coordination, voluntary, autonomous, capable*. Check which of the report's
labelled themes it corresponds to — most likely "Frontier AI & existential risk"
or a neighbour of it — and use that label in the replacement text, so the
passage and Table 1 agree.

**Table 4 needs rebuilding** on the same basis: eight documents in three groups,
not thirteen, and the per-theme differences above.

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
