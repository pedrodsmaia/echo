# Echo Audit -- Geneva 2026 pilot, end to end.
#
#   Rscript examples/geneva_2026/run.R
#
# Run this first. It reproduces the published analysis from the raw CSVs and
# prints the diagnostics your install should match. If your numbers differ from
# expected_output.txt, something in your environment differs from the versions
# recorded in setup.R -- check that before running the method on your own data.
#
# Runtime: roughly 3-6 minutes, most of it the topic model.

if (!dir.exists("R")) {
  stop("Run this from the repository root:\n  Rscript examples/geneva_2026/run.R")
}

source("R/voice.R")
source("R/echo.R")

DATA <- "examples/geneva_2026/data"
OUT  <- "examples/geneva_2026/output"
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)

submissions <- file.path(DATA, "cso_ai_dialogue_submissions.csv")
sessions    <- file.path(DATA, "un_sessions.csv")
proposals   <- file.path(DATA, "side_event_proposals.csv")

# The submission form asked eleven open questions; every column that is not
# identifying metadata is part of the document (protocol Step 2.0).
meta_names <- c("ID", "Organization", "Stakeholder category", "Region")
text_cols  <- setdiff(names(readr::read_csv(submissions, n_max = 0,
                                            show_col_types = FALSE)), meta_names)

cat("\n==================== PHASE 2: VOICE ====================\n")
# prevalence_covariate is NULL, not "Region": the published analysis fitted the
# model without a covariate. `Stakeholder category` is constant across all 400
# rows ("Civil Society") and must never be used -- see protocol Step 2.0.
voice <- run_echo_voice(
  csv_path             = submissions,
  text_cols            = text_cols,
  id_col               = "ID",
  meta_cols            = c("Organization", "Region"),
  k_candidates         = 20,
  prevalence_covariate = NULL,
  output_dir           = OUT,
  seed                 = 1234
)

# In a first pass you would fit several candidates and read labelTopics() for
# each before choosing. K = 20 is fixed here because this script reproduces a
# published result; the choice itself is documented in the protocol, §5.
final <- finalize_topic_model(voice, k = 20)

cat("\nTop themes by prevalence:\n")
print(as.data.frame(head(final$topic_table[, c("topic", "prevalence_pct")], 10)))

cat("\n==================== PHASE 3: ECHO =====================\n")
official <- echo_project(voice, final, sessions,
                         text_cols = "text_string", id_col = "ID",
                         collection_name = "Official programme")

side <- echo_project(voice, final, proposals,
                     text_cols = "text_string", id_col = "ID",
                     collection_name = "Side events")

cat("\n==================== COMPARISON ========================\n")
comparison <- echo_compare(voice, final, list(official, side))
print(as.data.frame(comparison))

cat("\n=============== LEXICAL CHECK (exclusion) ==============\n")
# The published finding is that the strand of submissions calling for a halt to
# AI development has no presence in the official programme. With seven short
# documents a near-zero share is weakly powered; the absence of the defining
# terms is the evidence that claim rests on.
lex <- echo_lexical_check(sessions, "text_string",
                          c("ban", "moratorium", "catastrophic", "halt"))

saveRDS(list(voice = voice, final = final, official = official,
             side = side, comparison = comparison, lexical = lex),
        file.path(OUT, "geneva_2026_result.rds"))

cat("\n==================== EXPECTED ==========================\n")
cat("Official programme  vocabulary coverage : 98.4%\n")
cat("Side events         vocabulary coverage : 87.2%\n")
cat("Side events         56 published, 55 scored (1 non-English dropped)\n")
cat("Submissions         400 rows -> 399 above min_doc_length -> 379 English\n")
cat("Lexical check       ban / moratorium / catastrophic all absent\n")
cat("\nWritten to", OUT, "\n")
