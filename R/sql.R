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

#' Run sql inquiry and get result
#'
#' Inquiry result returned in response content, or saved to file.
#'
#' Calling function without assigning return value will print response status
#' and response content in console. Assigning return value will print response
#' status only.
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

#' Run sql inquiry and save result to file
#'
#' Carto API requires a file name but \code{httr::write_disk} file path will
#' override it. So we can use any dummy file name for API call.
#'
#' @param inquiry sql inquiry string
#' @param filepath output file path
#' @param parameter additional parameter to sql inquiry, like file format, by
#'   default in JSON, could be GeoJSON
#'
#' @return request status
#' @export
#'
#' @examples
#' sql_inquiry_save("SELECT * FROM table_1 limit 2", "e:/testgeo.json", "&format=GeoJSON")
#' sql_inquiry_save("SELECT * FROM table_1 limit 2", "e:/test.json")
sql_inquiry_save <- function(inquiry, filepath, parameter = ""){
  # didn't use get_response because do not need to print or save the response content, and the on disk info is only available when calling get directly.
  httr::GET(build_sql_api_url(inquiry, paste0("filename=dummy", parameter)),
            httr::write_disk(filepath))
}

#' Run sql inquiry and save result file as GeoJSON
#'
#' A wrapper to \code{sql_inquiry_save(inquiry, filepath, "&format=GeoJSON")}
#'
#' @param inquiry sql inquiry string
#' @param filepath output file path
#'
#' @return request status
#' @export
#'
#' @examples
#' sql_inquiry_save_geojson("SELECT * FROM table_1 limit 2", "e:/testgeo.json")
sql_inquiry_save_geojson <- function(inquiry, filepath) {
  sql_inquiry_save(inquiry, filepath, "&format=GeoJSON")
}

#' Run sql inquiry and save result in data frame
#'
#' Calling function without assigning return value will print response status
#' and response content in console. Assigning return value will print response
#' status only.
#'
#' @param inquiry sql inquiry string
#'
#' @return result in data frame
#' @export
sql_inquiry_df <- function(inquiry) {
  res <- sql_inquiry(inquiry)
  cat("----Inquiry Result:----\n")
  return(jsonlite::fromJSON(res)$rows)
}

#' Submit Batch sql inquiry
#'
#' Batch sql inquiry is often used for slow processes which may cause web UI time out. Inquiry job will be submitted and a job id will be returned in response, which can be used to check job status later.
#'
#' @param inquiry sql inquiry string
#'
#' @return inquiry response, including job id
#' @export
sql_batch_inquiry <- function(inquiry){
  # sql_url <- get_sql_batch_url()
  sql_batch_url <- build_sql_batch_url()
  res <- httr::POST(sql_batch_url,
    encode = "json",
    body = list(query = inquiry)
  )
  return(get_response(res))
}

#' Submit Batch sql inquiry and return job id
#'
#' Return batch sql inquiry job id directly so it can be used to check inquiry status later.
#'
#' @param inquiry sql inquiry string
#'
#' @return job id
#' @export
sql_batch_inquiry_id <- function(inquiry){
  res <- sql_batch_inquiry(inquiry)
  # response has been converted to json already. just print it
  cat(res)
  return(jsonlite::fromJSON(res)$job_id)
}

#' Check Batch sql inquiry status
#'
#' Return inquiry status in requst response content. If the job is still running, will also report the time passed since job submitted. Note sometimes the reported time are not accurate enough so the time passed could be negative if checked immediately after submit.
#'
#' @param job_id job id of previously submitted Batch sql inquiry
#'
#' @return inquiry status
#' @export
sql_batch_check <- function(job_id){
  res <- get_response(httr::GET(build_sql_batch_job_url(job_id)))
  cat(res)
  res_list <- jsonlite::fromJSON(res)
  if (res_list$status == "running") {
    created <- lubridate::ymd_hms(res_list$created_at)
    time_passed <- lubridate::now() - created
    cat(paste0("\n", format(time_passed), " passed since job created at ", lubridate::with_tz(created), "\n"))
  }
}

#' Cancel a Batch sql inquiry
#'
#' @param job_id job id of previously submitted Batch sql inquiry
#'
#' @return request status
#' @export
sql_batch_cancel <- function(job_id){
  return(get_response(httr::DELETE(build_sql_batch_job_url(job_id))))
}
