#' Read Carto user name and API key from environment
#'
#' The design goal is 1. hide details and varibles from user, only expose update
#' function,2. put help details in update function, 3. report error in all
#' functions, 4. report user name in success reading, only in package loading
#' and after update.
#'
#' That means carto_setup only report error, and a separate function to provide
#' message string of reporting success or failure. Package loading and updating
#' will message this string. That function need to suppress carto_setup message
#' and use its own copy because the return result is a message string, not
#' printing message immediately.
#'
#' @return a named vector holding user name and API key
carto_setup <- function(){
  carto_env <- Sys.getenv(c("carto_acc", "carto_api_key"))
  if (identical(sort(names(carto_env)), c("carto_acc", "carto_api_key")) &&
      all(nchar(carto_env) != 0)) {
    return(carto_env)
  } else {
    return(message("Carto user name or API key not found or invalid, check ?rCartoAPI::setup_key for details"))
  }
}

#' Message string of user name found in env
#'
#' If user name is not found, error message is reported from all the
#' functions. If user name is found, this only need to be reported in package
#' loading or after updating the environment, not in normal function usage.
#'
#' @return message string
check_carto_setup <- function(){
  carto_env <- suppressMessages(carto_setup())
  ifelse(typeof(carto_env) == "character",
                paste0("Carto API key for user ", carto_env["carto_acc"],
                       " found in environment"),
                "Carto user name or API key not found or invalid, check ?rCartoAPI::setup_key for details")
}

#' Set up Carto user name and API key with environment
#'
#' All functions need a Carto user name and API key.
#'
#' \enumerate{
#'   \item run \code{file.edit("~/.Renviron")} to edit the environment
#' variable file
#'   \item add two lines
#'     \itemize{ \item \code{carto_acc = "your
#' user name"}
#'     \item \code{carto_api_key = "your api key"}
#'     }
#'   \item run \code{setup_key()}.
#'  }
#'
#' Note if you want to remove the key and deleted the lines from
#' \code{~/.Renviron}, the key could still exist in environment. Restart R
#' session to make sure it was removed.
#'
#' For adding key or changing key value, edit and run \code{setup_key()} is
#' enough.
#' @param env_path path of environment file. Default as `~/.Renviron`.
#'
#' @return setup status message
#' @export
setup_key <- function(env_path = "~/.Renviron"){
  readRenviron(env_path)
  message(check_carto_setup())
}

#' Print or return the API call response
#'
#' There are two parts in response: response status and response content. The
#' status report whether the request is success, and the content is the return
#' value of API call.
#'
#' Run function without assigning return value will print both status and
#' response in console. Assigning return value will only print the status in
#' console, then save the content in prettified json format.
#'
#' Function will stop for http error.
#'
#' @param res response object
#' @param content_echo whether to print request content in console
#'
#' @return The response object in prettified json format
get_response <- function(res, content_echo = TRUE) {
  httr::stop_for_status(res)
  cat("\n----Request Status:----\n")
  cat(jsonlite::toJSON(httr::http_status(res), pretty = TRUE))
  cat("\n-----------------------\n")
  response <- invisible(jsonlite::prettify(httr::content(res, "text")))
  if (content_echo) {
    response
  }
  return(response)
}
