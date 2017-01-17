.onAttach <- function(libname, pkgname) {
  carto_env <- carto_setup()
  packageStartupMessage(ifelse(typeof(carto_env) == "character",
                               # "Carto user name",
                               paste0("Carto user name ",
                                      carto_env["carto_acc"],
                                      " and API key found in environment"),
                               "Carto user name and API key not found in environment or invalid, check `help carto_setup` for details"
                               ))
  # packageStartupMessage("test")
}
