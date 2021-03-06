% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/import.R
\name{force_sync}
\alias{force_sync}
\title{Force Sync with time check}
\usage{
force_sync(table_id)
}
\arguments{
\item{table_id}{the sync table id from the sync request response}
}
\value{
request response if force sync is run
}
\description{
Since there is a 15 mins wait limit since last sync, this function will check
last sync time first, and only run force sync when it's possible.
}
