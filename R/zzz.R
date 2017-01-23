# check user name and API key in environment.
.onAttach <- function(libname, pkgname) {
  packageStartupMessage(check_carto_setup())
}
