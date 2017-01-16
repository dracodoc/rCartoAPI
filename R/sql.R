#' Build url for sql and batch sql inquiry
#'
#' @param middle the unique part of each individual API call
#'
#' @return sql API url
build_sql_url <- function(middle){
  carto_env <- carto_setup()
  base_url <- paste0("https://", carto_env["carto_acc"], ".carto.com/api/v2/sql",
    middle,
    "api_key=", carto_env["carto_api_key"])
  return(base_url)
}

#' Build url for sql inquiry
#'
#' @param inquiry sql inquiry string
#' @param parameter additional parameter to sql inquiry, like file format or
#'   file name
#'
#' @return encoded url of sql api call
build_sql_api_url <- function(inquiry, parameter = ""){
  base_url <- build_sql_url(paste0("?", parameter, "&", "q=", inquiry, "&"))
  return(URLencode(base_url))
}

#' Build url for creating batch sql inquiry
#'
#' @return encoded url of batch sql inquiry
build_sql_batch_url <- function(){
  return(build_sql_url("/job?"))
}

#' Build url for checking batch sql inquiry
#'
#' @param job_id the job id of batch sql inquiry, returned from request response
#'
#' @return encoded url of checking batch sql inquiry
build_sql_batch_job_url <- function(job_id){
  return(build_sql_url(paste0("/job/", job_id, "?")))
}
# using GET. POST is also OK. https://carto.com/docs/carto-engine/sql-api/making-calls#post-and-get

#' Run sql inquiry
#'
#' @param inquiry sql inquiry string
#' @param parameter additional parameter to sql inquiry, like file format or
#'   file name
#'
#' @return request response in JSON format
#' @export
sql_inquiry <- function(inquiry, parameter = ""){
  return(get_response(httr::GET(build_sql_api_url(inquiry, parameter))))
}

#' Simple sql inquiry used for testing setup
#'
#' After setting Carto user name and API key, this function can be used to test
#' if the setup is successful.
#'
#' It's just a wrapper to \code{sql_inquiry("SELECT 1")}
#'
#' @return request response in JSON format
#' @export
test_connection <- function(){
  return(sql_inquiry("SELECT 1"))
}

#' Run sql inquiry with return format as GeoJSON
#'
#' It's just a wrapper to \code{sql_inquiry(inquiry, "&format=GeoJSON")}
#'
#' @param inquiry sql inquiry string
#'
#' @return request response in JSON format
#' @export
#'
#' @examples
sql_inquiry_geo <- function(inquiry) {
  return(sql_inquiry(inquiry, "&format=GeoJSON"))
}
# g <- sql_inquiry_geo("SELECT * FROM nfpaadmin.bfa_sample_1_1 limit 2")
# this is not working. check the census data in sync table, which used this api

sql_inquiry_file <- function(inquiry, file_path){
  return(sql_inquiry(inquiry, paste0("filename=", file_path)))
}
# seemed have a download named as test.json in chrome. let browser choose location, only used file name part
# sql_inquiry_file("SELECT * FROM nfpaadmin.bfa_sample_1_1 limit 2", "e:/test.txt")

sql_inquiry_dt <- function(inquiry) {
  res <- sql_inquiry(inquiry)
  cat("----Inquiry Result:----\n")
  dt <- data.table(jsonlite::fromJSON(res)$rows)
  return(dt)
}
# sql_inquiry_dt("SELECT 1")
# temp <- sql_inquiry_dt("SELECT * FROM nfpaadmin.bfa_sample_1_1 limit 2")

# usually batch job will need to save result into table, then read result from table in web page, or sql inquiry api. need to know table name. need cartodbfy table to make it appear in data set page.
# real batch job usually are slow, need job id to check status. This function return job_id in console. the id version return job_id.
sql_batch_inquiry <- function(inquiry){
  # sql_url <- get_sql_batch_url()
  sql_batch_url <- build_sql_batch_url()
  res <- httr::POST(sql_batch_url,
    encode = "json",
    body = list(query = inquiry)
  )
  return(get_response(res))
}

# inq <- sql_batch_inquiry("SELECT * FROM nfpaadmin.bfa_sample_1_1 limit 2")
# it's not appropriate to define a dt version, all dt version return results in dt. here is just to get response parameters. no need to write general json->dt function since it's too simple, but need one liner to get jobid since it's too common.

sql_batch_inquiry_id <- function(inquiry){
  res <- sql_batch_inquiry(inquiry)
  # response has been converted to json already. just print it
  cat(res)
  return(jsonlite::fromJSON(res)$job_id)
}
# sql_batch_inquiry_id("SELECT * FROM nfpaadmin.bfa_sample_1_1 limit 2")
# temp <- sql_batch_inquiry_id("SELECT * FROM nfpaadmin.bfa_sample_1_1 limit 2")
# check status, so called read job in documentation
sql_batch_check <- function(job_id){
  res <- get_response(httr::GET(build_sql_batch_job_url(job_id)))
  cat(res)
  res_list <- jsonlite::fromJSON(res)
  if (res_list$status == "running") {
    created <- ymd_hms(res_list$created_at)
    # updated <- ymd_hms(res_list$updated_at)
    time_passed <- now() - created
    cat(paste0("\n", format(time_passed), " passed since job created at ", with_tz(created), "\n"))
  }
}
# sql_batch_check("2a610405-bc22-4ce4-b8d8-0d866d871d56")
# not tested yet, beause no unfinished job
sql_batch_cancel <- function(job_id){
  return(get_response(httr::DELETE(build_sql_batch_job_url(job_id))))
}
