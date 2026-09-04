# Echo Audit -- Phase 3: Echo
# Freeze the Voice model and use it as a fixed measuring instrument on the
# documents the institution itself produced.
#
# See protocol/ECHO_AUDIT_PROTOCOL.md, Phase 3.
#
# Usage:
#   source("R/voice.R"); source("R/echo.R")
#   voice <- run_echo_voice(...)
#   final <- finalize_topic_model(voice, k = 20)
#
#   sessions <- echo_project(voice, final, "un_sessions.csv",
#                            text_cols = "text_string", id_col = "ID",
#                            collection_name = "Official programme")
#   echo_compare(voice, final, list(sessions))

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(stringr)
  library(stm)
  library(cld2)
})

#' Project a new collection into a frozen Voice model.
#'
#' Applies exactly the preprocessing voice.R applied to the source corpus,
#' aligns the result to the fitted vocabulary, and scores every document for
#' its share of each Voice theme. Nothing is allowed to emerge from the new
#' documents: this is measurement with the instrument held fixed.
#'
#' @param voice  The list returned by run_echo_voice().
#' @param final  The list returned by finalize_topic_model().
#' @param csv_path,text_cols,id_col,meta_cols As in run_echo_voice(); use the
#'   same text-assembly rule for the new collection.
#' @param collection_name Label used in the returned tables.
#' @param min_doc_length Minimum character length, matching voice.R's default.
#'   Documents below it are dropped and reported, never dropped silently.
#' @param language_filter Keep only documents cld2 detects as English, as in
#'   Voice. Set FALSE only if the institutional corpus is known to be
#'   single-language already.
#' @param prevalence_prior Passed to stm::fitNewDocuments. "None" is the
#'   correct choice whenever the new collection has no value for the
#'   covariate the Voice model was fitted with -- which is the normal case,
#'   since institutional documents have no Region, stakeholder type, and so on.
#'
#' @return A list with theta (per-document topic shares), doc_shares,
#'   shares (per-topic, unweighted and length-weighted), coverage
#'   diagnostics, and a drop log.
echo_project <- function(voice,
                         final,
                         csv_path,
                         text_cols,
                         id_col = NULL,
                         meta_cols = character(0),
                         collection_name = "collection",
                         min_doc_length = 50,
                         language_filter = TRUE,
                         prevalence_prior = "None") {

  model <- final$chosen_model
  K <- model$settings$dim$K

  raw <- read_csv(csv_path, show_col_types = FALSE)
  missing_cols <- setdiff(unique(c(id_col, meta_cols, text_cols)), names(raw))
  if (length(missing_cols) > 0) {
    stop("Columns not found in CSV: ", paste(missing_cols, collapse = ", "))
  }

  df <- raw
  if (length(text_cols) > 1) {
    df <- df %>%
      mutate(across(all_of(text_cols), ~replace_na(as.character(.), ""))) %>%
      unite("text_string", all_of(text_cols), sep = " ", remove = FALSE)
  } else {
    df$text_string <- as.character(df[[text_cols]])
  }
  df$.doc_id <- if (!is.null(id_col)) df[[id_col]] else seq_len(nrow(df))

  n_published <- nrow(df)

  # --- drop log: every subtraction is recorded, none is silent -------------
  drop_log <- tibble(stage = character(), n_removed = integer(), ids = character())
  record <- function(log, stage, removed_ids) {
    bind_rows(log, tibble(stage = stage,
                          n_removed = length(removed_ids),
                          ids = paste(removed_ids, collapse = "; ")))
  }

  too_short <- df %>% filter(str_length(text_string) <= min_doc_length)
  drop_log <- record(drop_log, sprintf("min_doc_length <= %d chars", min_doc_length),
                     too_short$.doc_id)
  df <- df %>% filter(str_length(text_string) > min_doc_length)

  if (language_filter) {
    df$lang <- detect_language(df$text_string)
    non_english <- df %>% filter(is.na(lang) | lang != "en")
    drop_log <- record(drop_log, "non-English (cld2)", non_english$.doc_id)
    df <- df %>% filter(!is.na(lang) & lang == "en")
  }

  if (nrow(df) == 0) stop("No documents left in '", collection_name, "' after filtering.")

  # --- identical preprocessing to voice.R ---------------------------------
  temp <- textProcessor(
    documents = df$text_string,
    metadata  = df,
    removestopwords = TRUE,
    removenumbers   = TRUE,
    stem            = TRUE,
    verbose         = FALSE
  )
  if (length(temp$docs.removed) > 0) {
    drop_log <- record(drop_log, "empty after textProcessor",
                       df$.doc_id[temp$docs.removed])
  }

  # --- vocabulary coverage, computed before alignment ----------------------
  # Share of running tokens in this collection that the instrument recognizes.
  # This is the diagnostic reported in the protocol (pilot: 86% / 98%).
  in_vocab <- temp$vocab %in% final$chosen_model$vocab
  tok_total <- sum(vapply(temp$documents, function(d) sum(d[2, ]), numeric(1)))
  tok_known <- sum(vapply(temp$documents, function(d) {
    sum(d[2, in_vocab[d[1, ]]])
  }, numeric(1)))
  coverage <- if (tok_total > 0) tok_known / tok_total else NA_real_

  # --- align to the frozen vocabulary and project --------------------------
  aligned <- alignCorpus(new = temp, old.vocab = model$vocab, verbose = FALSE)
  if (length(aligned$docs.removed) > 0) {
    kept_ids <- temp$meta$.doc_id
    drop_log <- record(drop_log, "no shared vocabulary (alignCorpus)",
                       kept_ids[aligned$docs.removed])
  }

  fitted <- fitNewDocuments(
    model            = model,
    documents        = aligned$documents,
    prevalencePrior  = prevalence_prior,
    returnPosterior  = FALSE,
    test             = TRUE,
    verbose          = FALSE
  )
  theta <- fitted$theta
  colnames(theta) <- paste0("topic_", seq_len(K))

  meta <- aligned$meta
  doc_len <- vapply(aligned$documents, function(d) sum(d[2, ]), numeric(1))

  doc_shares <- as_tibble(theta) %>%
    mutate(.doc_id = meta$.doc_id, .n_tokens = doc_len, .before = 1)

  # Unweighted mean is the headline figure; the length-weighted mean is
  # reported alongside it because with a handful of institutional documents
  # of very unequal length the two can differ materially.
  unweighted <- colMeans(theta)
  weighted   <- as.numeric(crossprod(doc_len, theta) / sum(doc_len))

  shares <- tibble(
    topic              = seq_len(K),
    share_pct          = round(unweighted * 100, 2),
    share_weighted_pct = round(weighted * 100, 2),
    n_substantial      = colSums(theta > 0.15)
  )

  cat("\n=== Echo projection:", collection_name, "===\n")
  cat("Published documents      :", n_published, "\n")
  cat("Scored documents         :", nrow(theta), "\n")
  if (nrow(drop_log) > 0 && sum(drop_log$n_removed) > 0) {
    cat("Dropped:\n")
    for (i in seq_len(nrow(drop_log))) {
      if (drop_log$n_removed[i] > 0) {
        cat(sprintf("  %-38s %3d   [%s]\n", drop_log$stage[i], drop_log$n_removed[i],
                    substr(drop_log$ids[i], 1, 70)))
      }
    }
  }
  cat(sprintf("Vocabulary coverage      : %.1f%% of running tokens\n", coverage * 100))
  cat("Document length (tokens) : min", min(doc_len), " median", median(doc_len),
      " max", max(doc_len), "\n")
  if (max(doc_len) / max(1, min(doc_len)) > 3) {
    cat("  NOTE: documents differ in length by more than 3x -- read\n",
        "  share_weighted_pct alongside share_pct before reporting.\n")
  }

  list(
    collection    = collection_name,
    n_published   = n_published,
    n_scored      = nrow(theta),
    drop_log      = drop_log,
    coverage      = coverage,
    theta         = theta,
    doc_shares    = doc_shares,
    doc_len       = doc_len,
    shares        = shares
  )
}

#' Build the Echo comparison table: the Voice corpus beside one or more
#' projected collections, with the ratio that drives the outcome reading.
#'
#' @param voice,final As in echo_project().
#' @param projections A list of echo_project() results.
#' @param labels Optional character vector of theme labels, length K, in topic
#'   order. Supply the names you gave the topics in Step 2.5.
echo_compare <- function(voice, final, projections, labels = NULL) {
  model <- final$chosen_model
  K <- model$settings$dim$K
  base <- colMeans(model$theta) * 100

  out <- tibble(
    topic = seq_len(K),
    label = if (is.null(labels)) NA_character_ else labels,
    civil_society_pct = round(base, 2)
  )

  for (pr in projections) {
    nm <- make.names(pr$collection)
    out[[paste0(nm, "_pct")]]   <- pr$shares$share_pct
    out[[paste0(nm, "_ratio")]] <- round(pr$shares$share_pct / base, 2)
  }

  out %>% arrange(desc(civil_society_pct))
}

#' Lexical check for exclusion claims.
#'
#' A near-zero projected share is weakly powered when the institutional
#' collection is small. A defining term that occurs nowhere in it is direct
#' evidence. Run this before classifying any theme as excluded.
#'
#' @param csv_path,text_cols The institutional collection, read as in
#'   echo_project().
#' @param terms Character vector of the theme's defining terms.
echo_lexical_check <- function(csv_path, text_cols, terms) {
  raw <- read_csv(csv_path, show_col_types = FALSE)
  txt <- if (length(text_cols) > 1) {
    apply(raw[text_cols], 1, function(r) paste(replace_na(as.character(r), ""), collapse = " "))
  } else {
    as.character(raw[[text_cols]])
  }
  txt <- str_to_lower(txt)

  # Whole-word matching only. Substring matching silently produces false
  # positives that invert the finding: searching for "ban" as a substring
  # matches "urban", which occurs in the pilot's own official notes.
  pat <- paste0("\\b", str_replace_all(str_to_lower(terms), "([.^$*+?()\\[\\]{}|\\\\])", "\\\\\\1"), "\\b")
  res <- tibble(
    term      = terms,
    n_docs    = vapply(pat, function(p) sum(str_detect(txt, p)), integer(1), USE.NAMES = FALSE),
    n_hits    = vapply(pat, function(p) sum(str_count(txt, p)), integer(1), USE.NAMES = FALSE)
  )
  cat("\n=== Lexical check over", length(txt), "documents ===\n")
  print(as.data.frame(res))
  absent <- res$term[res$n_hits == 0]
  if (length(absent) > 0) {
    cat("\nAbsent entirely:", paste(absent, collapse = ", "), "\n")
    cat("This is the evidence an exclusion claim rests on -- cite it ahead of the share.\n")
  }
  res
}
