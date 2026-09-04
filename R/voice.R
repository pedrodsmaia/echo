# Echo Audit -- Phase 2: Voice
# Generalized, parameterized computational grounded theory pipeline.
# See protocol/ECHO_AUDIT_PROTOCOL.md for the methodology this code implements.
#
# Usage:
#   source("R/voice.R")
#   result <- run_echo_voice(
#     csv_path = "some_corpus.csv",
#     text_cols = c("Q1", "Q2", "Q3"),   # or a single already-combined column
#     id_col = "ID",
#     meta_cols = c("Organization", "Region"),
#     k_candidates = c(10, 15, 20, 25),
#     prevalence_covariate = "Region",   # NULL if no reliable covariate exists
#     output_dir = "voice_output"
#   )
#   result$chosen_model   # set this after reading labelTopics() output -- see below
#   result$topic_table

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(stringr)
  library(stm)
  library(quanteda)
  library(quanteda.textstats)
  library(cld2)
})

#' Run the Voice phase of an Echo Audit on a corpus of written submissions.
#'
#' @param csv_path Path to a CSV with one row per document.
#' @param text_cols Character vector of column names to concatenate into the
#'   analysis text (use a single column name if the corpus already has one
#'   combined text field).
#' @param id_col Column to use as a document identifier. If NULL, row number
#'   is used.
#' @param meta_cols Additional metadata columns to retain and pass through
#'   (e.g. organization, region, stakeholder category).
#' @param k_candidates Integer vector of topic counts to fit and compare.
#'   Scale to corpus size: aim for roughly 6-20 documents per topic per
#'   candidate K (see protocol doc). The function warns if any candidate
#'   implies fewer than 5 docs/topic.
#' @param prevalence_covariate Optional single column name (from meta_cols) to
#'   use as an STM prevalence covariate. Leave NULL if no metadata column is a
#'   reliable, well-populated grouping variable -- forcing a noisy proxy
#'   covariate produces misleading diff-of-proportions/STM prevalence results.
#' @param min_doc_length Minimum character length for a document to be kept.
#' @param near_dup_threshold Cosine similarity threshold for flagging
#'   near-duplicate documents (default 0.85, per protocol).
#' @param output_dir Directory to write LDAvis output and per-topic reading
#'   files into (created if it doesn't exist).
#' @param seed Random seed for STM fitting (default 1234).
#'
#' @return A list with: df (English-only corpus after filtering), non_english
#'   (set-aside rows), near_duplicates (flagged pairs, may be empty), docs/
#'   vocab/meta (prepDocuments output), stm_models (named list by k), and a
#'   helper you call manually: pick_topic_model(result, k) to finalize choice
#'   after reading labelTopics() output for each candidate.
run_echo_voice <- function(csv_path,
                            text_cols,
                            id_col = NULL,
                            meta_cols = character(0),
                            k_candidates = c(10, 15, 20, 25),
                            prevalence_covariate = NULL,
                            min_doc_length = 50,
                            near_dup_threshold = 0.85,
                            output_dir = "voice_output",
                            seed = 1234) {

  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

  raw <- read_csv(csv_path, show_col_types = FALSE)

  keep_cols <- unique(c(id_col, meta_cols, text_cols))
  missing_cols <- setdiff(keep_cols, names(raw))
  if (length(missing_cols) > 0) {
    stop("Columns not found in CSV: ", paste(missing_cols, collapse = ", "))
  }

  df_all <- raw
  if (length(text_cols) > 1) {
    df_all <- df_all %>%
      mutate(across(all_of(text_cols), ~replace_na(as.character(.), ""))) %>%
      unite("text_string", all_of(text_cols), sep = " ", remove = FALSE)
  } else {
    df_all$text_string <- as.character(df_all[[text_cols]])
  }

  if (!is.null(id_col)) {
    df_all$.doc_id <- df_all[[id_col]]
  } else {
    df_all$.doc_id <- seq_len(nrow(df_all))
  }

  df_all <- df_all %>% filter(str_length(text_string) > min_doc_length)

  # --- language filtering ---
  df_all$lang <- detect_language(df_all$text_string)
  lang_table <- table(df_all$lang, useNA = "ifany")
  cat("Language distribution:\n"); print(lang_table)

  non_english <- df_all %>% filter(is.na(lang) | lang != "en")
  if (nrow(non_english) > 0) {
    cat("\nSet aside", nrow(non_english), "non-English document(s) for manual reading.\n")
  }
  df <- df_all %>% filter(lang == "en")
  cat("\nDocuments (English only):", nrow(df), "\n")

  # --- near-duplicate detection ---
  # Stopwords are removed and the matrix is tf-idf weighted BEFORE the cosine.
  # Without this the threshold measures genre rather than duplication: in a
  # corpus of responses to the same structured questionnaire, every document
  # shares the form's vocabulary. On the pilot corpus (379 docs, 71,631 pairs)
  # the raw matrix put 10,768 pairs (15% of all pairs) above 0.85, against 8
  # after tf-idf -- while the 7 genuinely near-identical pairs were found by
  # both. See protocol Step 2.2.
  dfm_check <- df$text_string %>%
    tokens(remove_punct = TRUE, remove_numbers = TRUE) %>%
    tokens_tolower() %>%
    tokens_remove(stopwords("en")) %>%
    dfm() %>%
    dfm_tfidf()
  sim <- textstat_simil(dfm_check, method = "cosine")
  sim_df <- as.data.frame(sim) %>%
    filter(document1 != document2, cosine > near_dup_threshold) %>%
    arrange(desc(cosine))

  near_duplicates <- tibble()
  if (nrow(sim_df) > 0) {
    cat("\nNear-duplicate documents detected (cosine >", near_dup_threshold, "):\n")
    near_duplicates <- sim_df %>%
      mutate(
        idx1 = as.integer(str_remove(as.character(document1), "^text")),
        idx2 = as.integer(str_remove(as.character(document2), "^text")),
        id1 = df$.doc_id[idx1],
        id2 = df$.doc_id[idx2]
      ) %>%
      select(id1, id2, cosine)
    print(as.data.frame(near_duplicates))
    cat("\nDecide explicitly whether to dedupe, downweight, or analyze this",
        "\ncluster separately -- see protocol Step 2.2.\n")
  } else {
    cat("\nNo near-duplicates detected above threshold", near_dup_threshold, ".\n")
  }

  # --- k_candidates sanity check ---
  docs_per_topic <- nrow(df) / k_candidates
  if (any(docs_per_topic < 5)) {
    warning("Candidate K values imply fewer than 5 docs/topic for k=",
            paste(k_candidates[docs_per_topic < 5], collapse = ","),
            " -- results at this K are likely to be data-starved (see protocol Step 2.4).")
  }

  # --- STM preprocessing ---
  temp <- textProcessor(
    documents = df$text_string,
    metadata = df,
    removestopwords = TRUE,
    removenumbers = TRUE,
    stem = TRUE
  )
  out <- prepDocuments(temp$documents, temp$vocab, temp$meta, lower.thresh = 2)
  docs  <- out$documents
  vocab <- out$vocab
  meta  <- out$meta
  cat("\nDocuments after prep:", length(docs), " Vocab size:", length(vocab), "\n")

  # --- STM fitting across k candidates ---
  prevalence_formula <- if (!is.null(prevalence_covariate)) {
    as.formula(paste("~", prevalence_covariate))
  } else {
    NULL
  }

  stm_models <- lapply(k_candidates, function(k) {
    if (!is.null(prevalence_formula)) {
      stm(docs, vocab, K = k, prevalence = prevalence_formula, data = meta,
          init.type = "Spectral", seed = seed, verbose = FALSE)
    } else {
      stm(docs, vocab, K = k, init.type = "Spectral", seed = seed, verbose = FALSE)
    }
  })
  names(stm_models) <- paste0("k", k_candidates)

  cat("\nFit", length(k_candidates), "candidate models: k =",
      paste(k_candidates, collapse = ", "), "\n")
  cat("Next: read labelTopics(result$stm_models[[\"kN\"]]) for each candidate,\n")
  cat("apply the two model-selection signs from the protocol, then call\n")
  cat("finalize_topic_model(result, k = <chosen K>) to produce topic_table +\n")
  cat("per-topic reading files + LDAvis.\n")

  list(
    df = df,
    non_english = non_english,
    near_duplicates = near_duplicates,
    docs = docs, vocab = vocab, meta = meta,
    k_candidates = k_candidates,
    stm_models = stm_models,
    output_dir = output_dir
  )
}

#' Finalize the chosen topic model: writes topic_table, per-topic reading
#' files, and an LDAvis browser to result$output_dir. Call this after manually
#' inspecting labelTopics() for each candidate and picking a K.
finalize_topic_model <- function(result, k, n_read = 3, n_frex = 10) {
  chosen_model <- result$stm_models[[paste0("k", k)]]
  if (is.null(chosen_model)) stop("No fitted model for k=", k, " -- check k_candidates used in run_echo_voice().")

  prevalence <- colMeans(chosen_model$theta)
  labs <- labelTopics(chosen_model, n = n_frex)

  topic_table <- tibble(
    topic = 1:k,
    prevalence_pct = round(prevalence * 100, 2),
    frex = apply(labs$frex, 1, paste, collapse = ", "),
    label = NA_character_
  ) %>% arrange(desc(prevalence_pct))

  ldavis_dir <- file.path(result$output_dir, paste0("ldavis_k", k))
  stm::toLDAvis(chosen_model, result$docs, out.dir = ldavis_dir)

  reading_dir <- file.path(result$output_dir, "topic_reading")
  dir.create(reading_dir, showWarnings = FALSE)
  for (t in 1:k) {
    top_docs <- result$meta %>%
      mutate(weight = chosen_model$theta[, t]) %>%
      arrange(desc(weight)) %>%
      slice(1:n_read)
    thoughts <- findThoughts(chosen_model, texts = result$meta$text_string, n = n_read, topics = t)$docs[[1]]
    out_txt <- paste0(
      "=== TOPIC ", t, " ===\n",
      "FREX words: ", apply(labs$frex, 1, paste, collapse = ", ")[t], "\n\n",
      paste(sprintf("--- doc_id=%s (weight=%.2f) ---\n%s\n",
                     top_docs$.doc_id, top_docs$weight, thoughts), collapse = "\n")
    )
    writeLines(out_txt, file.path(reading_dir, sprintf("topic_%02d.txt", t)))
  }

  cat("Wrote topic_table, LDAvis (", ldavis_dir, ") and per-topic reading files (",
      reading_dir, ")\n")

  list(chosen_model = chosen_model, topic_table = topic_table,
       ldavis_dir = ldavis_dir, reading_dir = reading_dir)
}
