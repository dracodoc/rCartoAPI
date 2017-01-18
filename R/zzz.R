.onAttach <- function(libname, pkgname) {
  packageStartupMessage(check_carto_setup())
}
