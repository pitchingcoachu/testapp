library(readr)
library(dplyr)
library(lubridate)
library(glue)
library(rlang)
library(tibble)

SUPPORTED_SESSION_COLS <- c(
  "session_id", "SessionID", "session", "Session", "GameUID", "GameID"
)
SELECTED_COLS <- c(
  SUPPORTED_SESSION_COLS, "PlayID", "PitchNo", "UTCDateTime", "Date", "UTCTime"
)

extract_public_id <- function(url) {
  if (!nzchar(url)) return(NA_character_)
  cleaned <- sub("\\?.*$", "", url)
  parts <- strsplit(cleaned, "/upload/", fixed = TRUE)[[1]]
  if (length(parts) < 2) return(NA_character_)
  pid <- parts[[2]]
  sub("\\.[^.]*$", "", pid)
}

parse_session_timestamp <- function(x) {
  if (is.null(x)) return(rep(NA_real_, length(x)))
  x <- trimws(as.character(x))
  parsed <- suppressWarnings(lubridate::ymd_hms(x, tz = "UTC"))
  needs <- is.na(parsed) & nzchar(x)
  if (any(needs)) {
    parsed[needs] <- suppressWarnings(lubridate::mdy_hms(x[needs], tz = "UTC"))
  }
  parsed
}

list_session_csvs <- function(data_dir) {
  csvs <- list.files(
    path = data_dir,
    pattern = "\\.csv$",
    recursive = TRUE,
    full.names = TRUE
  )
  csvs[grepl("(?i)(/practice/|/v3/)", csvs)]
}

read_session_rows <- function(path, session_lookup) {
  df <- tryCatch({
    readr::read_csv(
      path,
      col_types = readr::cols(.default = readr::col_character()),
      show_col_types = FALSE
    )
  }, error = function(err) {
    message(glue("Skipping {path}: {err$message}"))
    return(tibble::tibble())
  })

  if (!nrow(df)) return(df)

  session_cols <- intersect(SUPPORTED_SESSION_COLS, names(df))
  if (!length(session_cols)) return(tibble::tibble())

  for (col in session_cols) {
    values <- df[[col]]
    norm <- tolower(trimws(as.character(values)))
    match_rows <- which(norm == session_lookup & nzchar(norm))
    if (length(match_rows)) {
      relevant <- df[match_rows, , drop = FALSE]
      relevant <- relevant %>%
        dplyr::mutate(
          session_id = relevant[[col]]  # keep original casing
        )
      required <- intersect(names(relevant), SELECTED_COLS)
      relevant <- relevant[, unique(c(required, "session_id")), drop = FALSE]
      return(relevant)
    }
  }

  tibble::tibble()
}

find_session_rows <- function(data_dir, session_id) {
  target <- tolower(trimws(session_id))
  csvs <- list_session_csvs(data_dir)
  if (!length(csvs)) {
    stop(glue("No CSV files found under {data_dir} matching /practice/ or /v3/"), call. = FALSE)
  }

  for (csv in csvs) {
    rows <- read_session_rows(csv, target)
    if (nrow(rows)) {
      return(rows)
    }
  }

  tibble::tibble()
}

order_session_rows <- function(df) {
  if (!nrow(df)) return(df)
  df %>%
    dplyr::mutate(
      PitchNo = suppressWarnings(as.integer(PitchNo)),
      timestamp = parse_session_timestamp(UTCDateTime),
      timestamp = dplyr::coalesce(timestamp, parse_session_timestamp(Date))
    ) %>%
    dplyr::arrange(
      is.na(PitchNo), PitchNo,
      is.na(timestamp), timestamp,
      PlayID
    )
}

load_manifest <- function(manifest_path) {
  manifest_path <- path.expand(manifest_path)
  if (!file.exists(manifest_path)) {
    stop(glue("Manifest file not found: {manifest_path}"), call. = FALSE)
  }
  manifest <- readr::read_csv(
    manifest_path,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )
  if (!"cloudinary_url" %in% names(manifest)) {
    stop("Manifest CSV must include a 'cloudinary_url' column.", call. = FALSE)
  }
  manifest <- manifest %>%
    dplyr::mutate(
      cloudinary_url = trimws(cloudinary_url)
    ) %>%
    dplyr::filter(nzchar(cloudinary_url))

  if (!"cloudinary_public_id" %in% names(manifest)) {
    manifest$cloudinary_public_id <- NA_character_
  }

  manifest %>%
    dplyr::mutate(
      cloudinary_public_id = dplyr::coalesce(
        cloudinary_public_id,
        vapply(cloudinary_url, extract_public_id, FUN.VALUE = character(1))
      )
    )
}

load_existing_map <- function(map_path) {
  map_path <- path.expand(map_path)
  if (!file.exists(map_path)) {
    return(tibble::tibble(
      session_id = character(),
      play_id = character(),
      camera_slot = character(),
      camera_name = character(),
      camera_target = character(),
      video_type = character(),
      azure_blob = character(),
      azure_md5 = character(),
      cloudinary_url = character(),
      cloudinary_public_id = character(),
      uploaded_at = character()
    ))
  }
  readr::read_csv(
    map_path,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )
}

map_manifest_to_session <- function(session_rows,
                                   manifest,
                                   session_id,
                                   slot = "VideoClip2",
                                   name = "ManualCamera",
                                   target = "ManualUpload",
                                   type = "ManualVideo",
                                   map_path = "data/video_map.csv") {
  if (!nrow(session_rows)) {
    stop("No TrackMan rows found for the requested session.", call. = FALSE)
  }
  target_count <- min(nrow(session_rows), nrow(manifest))
  if (target_count == 0) {
    stop("No pitches or clips available to map.", call. = FALSE)
  }
  if (nrow(manifest) > nrow(session_rows)) {
    warning(glue(
      "Manifest has {nrow(manifest)} clips but the session only has {nrow(session_rows)} pitches. ",
      "Only the first {nrow(session_rows)} clips will be assigned."
    ))
  }
  if (nrow(session_rows) > nrow(manifest)) {
    message(glue(
      "Session has {nrow(session_rows)} pitches but manifest provided {nrow(manifest)} clips. ",
      "The first {nrow(manifest)} pitches will be mapped."
    ))
  }
  session_rows <- session_rows %>% dplyr::slice_head(n = target_count)
  manifest <- manifest %>% dplyr::slice_head(n = target_count)

  timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  media_rows <- tibble::tibble(
    session_id = session_rows$session_id,
    play_id = session_rows$PlayID,
    camera_slot = slot,
    camera_name = name,
    camera_target = target,
    video_type = type,
    azure_blob = NA_character_,
    azure_md5 = NA_character_,
    cloudinary_url = manifest$cloudinary_url,
    cloudinary_public_id = manifest$cloudinary_public_id,
    uploaded_at = timestamp
  )

  existing <- load_existing_map(map_path)
  deduped <- existing %>%
    dplyr::filter(!(
      session_id %in% media_rows$session_id &
        camera_slot == slot &
        play_id %in% media_rows$play_id
    ))

  combined <- dplyr::bind_rows(deduped, media_rows)
  readr::write_csv(combined, path.expand(map_path))

  message(glue(
    "Mapped {nrow(media_rows)} clips to session {session_id} and saved to {path.expand(map_path)}"
  ))
  invisible(media_rows)
}
