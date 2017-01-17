.onAttach <- function(libname, pkgname) {
  # packageStartupMessage(ifelse(found_carto_env(),
  #                              "Carto user name",
  #                              # paste0("Carto user name ",
  #                              #        carto_env["carto_acc"],
  #                              #        " and API key found in environment"),
  #                              "Carto user name and API key not found in environment or invalid, check `help carto_setup` for details"
  #                              ))
}
