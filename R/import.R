#' Build url for import and sync API call
#'
#' The import and sync API url are very similar. This function capture the
#' shared parts. The individual API call will add its special part as parameter
#' to build its url.
#'
#' Called by \code{\link{local_import}}, \code{\link{url_common}}
#'
#' @param middle the unique part of each individual API call
#' @return import and sync API url
build_url <- function(middle){
  carto_env <- carto_setup()
  base_url <- paste0("https://",
    carto_env["carto_acc"],
    ".carto.com/api/v1/",
    middle,
    "?api_key=",
    carto_env["carto_api_key"])
  return(base_url)
}

#' Upload local file to Carto
#'
#' Calling function without assigning return value will print response status
#' and response content in console. Assigning return value will print response
#' status only.
#'
#' @param file_name the local file path
#'
#' @return request response
#' @export
#'
local_import <- function(file_name){
  base_url <- build_url("imports/")
  res <- httr::POST(base_url,
    encode = "multipart",
    body = list(file = upload_file(file_name))
  )
  return(get_response(res))
}

#' Convert dropbox share link into direct access file url
#'
#' @param link the dropbox share link. Will take clipboard content if not
#'   provided in call.
#'
#' @return dropbox direct access file url
#' @export
#'
convert_dropbox_link <- function(link = readClipboard()){
  return(str_replace(link, "www.dropbox.com", "dl.dropboxusercontent.com"))
}

#' The commong part of url to call import or sync API with a remote link
#'
#' Used \code{\link{build_url}}. Called by \code{\link{url_import}},
#' \code{\link{url_sync}} Note the API call to list sync table used different
#' format
#'
#' @param link remote file link
#' @param quoted_guessing If TRUE, Carto will also guess quoted columns. Default
#'   FALSE.
#' @param api import or sync API name
#'
#' @return request response
url_common <- function(link, quoted_guessing = FALSE, api){
  base_url <- build_url(api)
  res <- httr::POST(base_url,
    encode = "json",
    body = list(url = link, quoted_fields_guessing = quoted_guessing)
  )
  return(get_response(res))
}

#' Import a remote file link into Carto
#'
#' Calling function without assigning return value will print response status
#' and response content in console. Assigning return value will print response
#' status only.
#'
#' @param link remote file link
#' @param quoted_guessing If TRUE, Carto will also guess quoted columns. Default
#'   FALSE.
#'
#' @return request response
#' @export
url_import <- function(link, quoted_guessing = FALSE){
  return(url_common(link, quoted_guessing, "imports/"))
}

#' Sync with a remote file link
#'
#' Calling function without assigning return value will print response status
#' and response content in console. Assigning return value will print response
#' status only.
#'
#' @param link remote file link
#' @param quoted_guessing If TRUE, Carto will also guess quoted columns. Default
#'   FALSE.
#'
#' @return request response
#' @export
url_sync <- function(link, quoted_guessing = FALSE){
  return(url_common(link, quoted_guessing, "synchronizations/"))
}

#' List all files in sync
#'
#' Calling function without assigning return value will print response status
#' and response content in console. Assigning return value will print response
#' status only.
#'
#' Note the time in response is UTC time. To convert it into local time, use
#' \code{lubridate::with_tz(lubridate::ymd_hms(time))}
#'
#' @return request response in JSON format
#' @export
list_sync_tables <- function(){
  base_url <- build_url("synchronizations/")
  res <- httr::GET(base_url)
  return(get_response(res))
}

#' Get the sync files table and convert to data.table
#'
#' Calling function without assigning return value will print response status
#' and response content in console. Assigning return value will print response
#' status only.
#'
#' Note the time in response is UTC time. To convert it into local time, use
#' \code{lubridate::with_tz(lubridate::ymd_hms(time))}
#'
#' @return A data.table holding sync file table
#' @export
#' @import data.table
list_sync_tables_dt <- function(){
  # don't need content in json format no matter what.
  res <- list_sync_tables()
  dt <- data.table(jsonlite::fromJSON(res)$synchronizations)
  return(dt)
}

#' Build url for checking sync status or force sync
#'
#' The url is same for two commands, except GET or PUT
#'
#' @param table_id the sync table id from the sync request response
#'
#' @return API url
build_sync_url <- function(table_id) {
  return(build_url(paste0("synchronizations/", table_id, "/sync_now")))
}

#' Check sync status
#'
#' Sometimes there are empty link or unfinished sync reported as success in
#' request status. The table of all sync files actually provids more information
#' about status than this function.
#'
#' Calling function without assigning return value will print response status
#' and response content in console. Assigning return value will print response
#' status only.
#'
#' @param table_id the sync table id from the sync request response
#'
#' @return request response in JSON format
#' @export
check_sync_status <- function(table_id) {
  res <- httr::GET(build_sync_url(table_id))
  return(get_response(res))
}

#' Remove sync for remote file
#'
#' Just remove the sync schedule, not the existing table in Carto.
#'
#' Finished sync tables should appear in Carto.com data set page. Empty or wrong
#' sync tables will not appear and cannot be delete from web UI.
#'
#' @param table_id  the sync table id from the sync request response
#'
#' @return request response in JSON format
#' @export
remove_sync <- function(table_id) {
  base_url <- build_url(paste0("synchronizations/", table_id))
  res <- httr::DELETE(base_url)
  get_response(res, print_only = TRUE)
}

#' Force sync a sync table
#'
#' There is a 15 mins wait limit since last sync. Depend on last sync time the
#' force sync may fail. When force sync is possible there should be a "sync now"
#' button in data set view page.
#'
#' @param table_id  the sync table id from the sync request response
#'
#' @return request response in JSON format
force_sync_without_time_check <- function(table_id){
  res <- httr::PUT(build_sync_url(table_id))
  return(get_response(res))
}

#' Force Sync with time check
#'
#' Since there is a 15 mins wait limit since last sync, this function will check
#' last sync time first, and only run force sync when it's possible.
#'
#' @param table_id the sync table id from the sync request response
#'
#' @return request response if force sync is run
#' @export
force_sync <- function(table_id){
  cat("Checking last sync time for table ...\n")
  tables_dt <- list_sync_tables_dt()
  # has similar code in sql_batch_check, but difficult to abstract since two variables are needed
  last_sync_time <- lubridate::ymd_hms(tables_dt[id == table_id, updated_at])
  time_passed <- lubridate::now() - last_sync_time
  cat(paste0("\n\n", format(time_passed), " passed since last sync at ", lubridate::with_tz(last_sync_time), "\n"))
  if (time_passed < lubridate::dminutes(15)) {
    stop("\nCarto require at least 15 mins wait since last sync")
  } else {
    cat("\nForce syncing ...\n")
    return(force_sync_without_time_check(table_id))
  }
}
