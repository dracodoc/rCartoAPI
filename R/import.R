#' Build url for import and sync API call
#'
#' The import and sync API url are very similar. This function capture the
#' shared parts. The individual API call will add its special part as parameter
#' to build its url.
#'
#' Called by \code{\link{local_import}}, \code{\link{url_common}}
#'
#' @param middle the unique part of each individual API type
#' @return API url
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
#' calling function without assigning return value will print response status
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


# url import. this is very similar to sync table in syntax, but as one time import, still useful. also have type guessing control.
# type guessing: the content guessing is about geocoding, not implemented fully, leave it as is.
# we still want general type guessing to get number as number, especially lat/lon as coordinates.
# just disable guessing for quoted field so we can keep string column as string. Number formated string will stay as string instead of number and lost leading zeros. With quoted guessing disabled, date will not be converted automatically, use sql to convert when needed.
# if there is no need for this case, enable quoted guessing to accept default behavior.



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
#' If calling function without assigning return value, both request status and
#' reponse will be printed in console. If assigning a return value to variable,
#' only status will be printed.
#'
#' Note the time in response is UTC time. To convert it into local time, use
#' \code{with_tz(ymd_hms(time))}
#'
#' @return request response in JSON format
#' @export
list_sync_tables <- function(){
  base_url <- build_url("synchronizations/")
  res <- httr::GET(base_url)
  return(get_response(res))
}

#' Get the sync files table in data.table
#'
#' If calling function without assigning return value, both request status and
#' reponse will be printed in console. If assigning a return value to variable,
#' only status will be printed.
#'
#' Note the time in response is UTC time. To convert it into local time, use
#' \code{with_tz(ymd_hms(time))}
#'
#' @return A data.table holding sync file table
#' @export
list_sync_tables_dt <- function(){
  # don't need content in json format no matter what.
  res <- list_sync_tables()
  dt <- data.table(jsonlite::fromJSON(res)$synchronizations)
  return(dt)
}

# tables_dt <- list_sync_tables_dt()
# check time in local time zone
# with_tz(ymd_hms(dt[8, created_at]))
# some data from Carto data library actually call api directly to return a file for sync
# some table name have original file name with table prefix. duplicate file have _1 postfix.

# check sync status. it's the same url for force sync, one use GET, one use PUT
build_sync_table_url <- function(table_id) {
  return(build_url(paste0("synchronizations/", table_id, "/sync_now")))
}
# some empty link or not finished link report success too. not really useful, the state column of sync table provided more infor, plus other columns of the table.
check_sync_status <- function(table_id) {
  res <- httr::GET(build_sync_table_url(table_id))
  return(get_response(res))
}
# check_sync_status(dt[name == "tn_sample", id])
# check_sync_status(dt[15, id])

# finished sync tables appear in data set page, should manage, delete from there. empty, wrong sync tables doesn't appear in that page, so cannot delete from web page.
# remove sync relation, not removing data set.
remove_sync <- function(table_id) {
  base_url <- build_url(paste0("synchronizations/", table_id))
  res <- httr::DELETE(base_url)
  get_response(res, print_only = TRUE)
}
# tables_dt <- list_sync_tables_dt()
# remove_sync(tables_dt[2, id])


# force sync directly. it may fail if less than 15 min since last sync. if there is "sync now" button in data set view, it should be possible. this function is used internally.
force_sync_without_time_check <- function(table_id){
  res <- PUT(build_sync_table_url(table_id))
  return(get_response(res))
}

# force_sync_without_time_check(dt[2, id])

# force sync with time check
# id is in the url_sync response, or list_sync_tables
force_sync <- function(table_id){
  cat("Checking last sync time for table ...\n")
  tables_dt <- list_sync_tables_dt()
  last_sync_time <- ymd_hms(tables_dt[id == table_id, updated_at])
  time_passed <- now() - last_sync_time
  cat(paste0("\n\n", format(time_passed), " passed since last sync at ", with_tz(last_sync_time), "\n"))
  if (time_passed < dminutes(15)) {
    stop("\nCarto require at least 15 mins wait since last sync")
  } else {
    cat("\nForce syncing ...\n")
    return(force_sync_without_time_check(table_id))
  }
}
