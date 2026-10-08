# Safe, conservative use of the externally cleaned lookup. Do not infer which
# conflicting name is correct, forward-fill, or turn unmatched names into "other".
reconcile_commanders <- function(data, lookup) {
  keys <- c("ross_inc_id", "sitnum", "time_since_disco")
  stopifnot(all(c(keys, "ic_name") %in% names(data)),
            all(c(keys, "ic_name") %in% names(lookup)))
  if (anyNA(lookup[keys])) stop("Commander lookup has missing keys")
  if (anyDuplicated(data[c("incident_number", "report_date")]))
    stop("Source has duplicate fire-days; resolve upstream before joining")
  # Identical repeated corrections are safe; distinct nonblank corrections conflict.
  lookup$ic_name <- as.character(lookup$ic_name)
  lookup$ic_name[!is.na(lookup$ic_name) & trimws(lookup$ic_name) == ""] <- NA_character_
  resolved <- lookup |>
    dplyr::group_by(dplyr::across(dplyr::all_of(keys))) |>
    dplyr::summarise(
      n_candidates = dplyr::n_distinct(ic_name, na.rm = TRUE),
      clean_name = if (dplyr::n_distinct(ic_name, na.rm = TRUE) == 1L)
        unique(ic_name[!is.na(ic_name)])[1] else NA_character_, .groups = "drop")
  data$.commander_row <- seq_len(nrow(data))
  out <- dplyr::left_join(data, resolved, by = keys, relationship = "many-to-one", na_matches = "never")
  stopifnot(nrow(out) == nrow(data), identical(out$.commander_row, data$.commander_row))
  use_clean <- !is.na(out$clean_name)
  raw <- as.character(out$ic_name)
  out$ic_name <- ifelse(use_clean, out$clean_name, raw)
  audit <- data.frame(status = c("input_rows", "output_rows", "lookup_conflicting_keys",
    "cleaned_rows", "conflicting_rows_retained", "unmatched_or_empty_rows_retained", "missing_names_after"),
    n = c(nrow(data), nrow(out), sum(resolved$n_candidates > 1L), sum(use_clean),
      sum(out$n_candidates > 1L, na.rm = TRUE), sum(!use_clean & (is.na(out$n_candidates) | out$n_candidates == 0L)),
      sum(is.na(out$ic_name))))
  out <- dplyr::select(out, -.commander_row, -n_candidates, -clean_name)
  attr(out, "commander_audit") <- audit
  out
}
