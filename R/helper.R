#' Setup Carto user name and API key
#'
#' All functions need a Carto user name and API key.
#'
#' 1. To add user name and API key in console or script, run \code{carto_env <-
#' c(carto_acc = "your user name", carto_api_key = "your api key")}
#'
#' 2. To save them in R user profile so it's more permanent and not exposed in
#' script, run \code{file.edit("~/.Rprofile")} and add
#' \code{Sys.setenv(carto_acc = "your user name")};
#' \code{Sys.setenv(carto_api_key = "your api key")}
#'
#' Check package readme for more details about two approaches.
#'
#' @return a named vector holding user name and API key
#'
carto_setup <- function(){
  # checking 1. if vector exist 2. vector names 3. vector element length
  found_carto_env <- function(){
    ifelse((exists("carto_env") &&
              identical(sort(names(carto_env)), c("carto_acc", "carto_api_key")) &&
              all(nchar(carto_env) != 0)),
           TRUE, FALSE)
  }
  # read from global environment first. so new assignment will override sys env.
  if (found_carto_env()) {
    return(carto_env)
  } else {
    # then check sys environment
    carto_env <- Sys.getenv(c("carto_acc", "carto_api_key"))
    if (found_carto_env()) {
      return(carto_env)
    } else {
      return(message("Carto user name or API key not found, check `?carto_setup` for details"))
    }
  }
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
