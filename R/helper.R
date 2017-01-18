#' Setup Carto user name and API key
#'
#' All functions need a Carto user name and API key.
#'
#' 1. run \code{file.edit("~/.Renviron")} and add \code{Sys.setenv(carto_acc =
#' "your user name")}; \code{Sys.setenv(carto_api_key = "your api key")}
#'
#' 2. run \code{readRenviron("~/.Renviron")} or \code{update_api_key()} to
#' update environment variables.
#'
#' Check package readme for more details.
#'
#' @return a named vector holding user name and API key
carto_setup <- function(){
  carto_env <- Sys.getenv(c("carto_acc", "carto_api_key"))
  if (identical(sort(names(carto_env)), c("carto_acc", "carto_api_key")) &&
      all(nchar(carto_env) != 0)) {
    return(carto_env)
  } else {
    return(message("Carto user name or API key not found, check `?carto_setup` for details"))
  }
}

#' Check if carto user name and API key is available
#'
#' @return setup status message string
check_carto_setup <- function(){
  carto_env <- carto_setup()
  ifelse(typeof(carto_env) == "character",
                paste0("Carto API key for user ", carto_env["carto_acc"],
                       " found in environment"),
                "Carto user name and API key not found in environment or invalid, check `help carto_setup` for details")
}

#' Update environment variables
#'
#' \code{readRenviron("~/.Renviron")} then check if the setup is correct
#'
#' @return setup status message
#' @export
update_env <- function(){
  readRenviron("~/.Renviron")
  cat(check_carto_setup(), "\n")
}

#' Print or return the API call response
#'
#' There are two parts in response: response status and response content. The status report whether the request is sucess, and the content have more information about the request may be useful later.
#'
#' Run function without assigning return value will print both status and response in console. Assigning return value will only print the status in console, then save the content in prettified json format.
#'
#' @param res response object
#' @param print_only If TRUE, only print the status, no returning of content. Default FALSE.
#'
#' @return If \code{print_only} is FALSE, the response object in prettified json format
get_response <- function(res, print_only = FALSE) {
  stop_for_status(res)
  cat("\n----Request Status:----\n")
  cat(jsonlite::toJSON(http_status(res), pretty = TRUE))
  cat("\n-----------------------\n")
  if (!print_only) {
    response <- prettify(content(res, "text"))
    return(response)
  }
}
