# Echo Audit -- install everything needed to run the pipeline.
#   Rscript setup.R
#
# Note on tm and SnowballC: they are not called directly anywhere in this
# repository, but stm::textProcessor() requires both (SnowballC for stemming).
# Omitting them is the first error a new user hits.

options(repos = c(CRAN = "https://cloud.r-project.org"))

pkgs <- c(
  "stm",                  # structural topic model, alignCorpus, fitNewDocuments
  "tm", "SnowballC",      # required by stm::textProcessor()
  "quanteda",             # tokenisation, document-feature matrices
  "quanteda.textstats",   # cosine similarity for near-duplicate detection
  "cld2",                 # language detection
  "LDAvis",               # interactive topic browser
  "dplyr", "readr", "tidyr", "stringr"
)

missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) == 0) {
  cat("All packages already installed.\n")
} else {
  cat("Installing:", paste(missing, collapse = ", "), "\n")
  install.packages(missing)
}

cat("\n--- versions ---\n")
for (p in pkgs) {
  ok <- requireNamespace(p, quietly = TRUE)
  cat(sprintf("%-20s %s\n", p, if (ok) as.character(packageVersion(p)) else "FAILED"))
}
cat("\nR:", R.version.string, "\n")
cat("\nVerified on R 4.6.1 with stm 1.3.8, quanteda 4.5.0, tm 0.7.18,\n")
cat("SnowballC 0.7.1, quanteda.textstats 0.97.2, LDAvis 0.3.2.\n")
