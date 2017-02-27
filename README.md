# Introduction

This is a R wrapper for Carto.com API. Carto is a web map provider. I used Carto in my project because:

1. With PostgreSQL, PostGIS as backend, you have all the power of SQL and PostGIS functions. With Mapbox you will need to do everything in JavaScript. Because you can run SQL inside the Carto website UI, it's much easier to experiment and update.
2. The new Builder let user to create widgets for map, which let map viewers select range in date or histgram, value in categorical variable, and the map will update dynamically. 

Carto provide [several types of API](https://carto.com/docs/carto-engine/sql-api) for different tasks. It's simple to construct an API call with `curl` but also very cumbersome. You also often need to use some parts of the request response, which means a lot of copy/paste. I try to replace all repetitive manual labor with programs as much as possible, so it's only natural to do this with R.

## Existing similar attempts

There are some R package or function available for Carto API but they don't meet my needs. 

- [cartodb-r](https://github.com/CartoDB/cartodb-r) exist but no longer work, mainly because the domain name changed from `cartodb.com` to `carto.com`. There is fork that fixed this problem. Though this package is more intended for this kind of usage:
  - get data from database tables in Carto
  - convert data into data frames, do some geospatial stuff in R
  - change data in databse tables in Carto by inserting and updating

- [r2cartodb](https://rpubs.com/walkerke/r2cartodb) is a function that upload a spatial or non-spatial data frame to your CartoDB account.

## Package usage cases

I developed my own R functions for every API call I used gradually, then I made it into a R package. 
- upload local file to Carto
- let Carto import a remote file by url 
- let Carto sync with a remote file
- check sync status
- force sync
- remove sync connection
- list all sync tables
- run SQL inquiry
- run time consuming SQL inquiry in Batch mode, check status later

So it's more focused on data import/sync and time consuming SQL inquiries. I have found it saved me a lot of time.

## Installation

```
install.packages("devtools") 
devtools::install_github("dracodoc/rCartoAPI")
```

`devtools` need some dependencies to work, like Rtools in windows, Xcode in Mac. If you have trouble installing it, there are also lightweighted alternatives like [remotes](https://github.com/r-pkgs/remotes). After installing `remotes`, run `remotes::install_github("dracodoc/rCartoAPI")`

### Updates
- 2017.01.23  Corrected the syntax used in `.Renviron`, updated the help messages.

### Carto user name and API key

All the functions in the package currently require an API key from Carto. Without API key you can only do some read only operations with public data. If there is more demand I can add the keyless versions, though I think it will be even better for Carto to just provide API key in free plan.

It's not easy to save sensitive information securely and conveniently at the same time. After checking [this summary](http://blog.revolutionanalytics.com/2015/11/how-to-store-and-use-authentication-details-with-r.html) and [the best practices vignette](https://cran.r-project.org/web/packages/httr/vignettes/api-packages.html) from `httr`, I chose to save them in system environment and minimize the exposure of user name and API key. After reading from system environment, the user name and API key only exist inside the package functions, which are further wrapped in package environment, not visible from global environment.

- To save user name and API key in R system environment, run

```
file.edit("~/.Renviron")
```

Add these lines:

```
# for Carto
carto_acc = "your user name"
carto_api_key = "your api key"
```

Then run `setup_key()`. 

Note if you want to remove the key and just deleted the lines from`~/.Renviron`, the key could still exist in environment. Restart R session to make sure it was removed. For adding key or changing key value, editing and runing `setup_key()` is enough.

Many references I found in this usage used `.Rprofile`, while I think [`.Renviron` is more suitable for this need](https://csgillespie.github.io/efficientR/3-3-r-startup.html#renviron). If you want to update variables and reload them, you don't need to touch the other part in `.Rprofile`. 

## Usage
Function summary:
- `update_env`, update environment variables after changes to Carto user name and API key
- `local_import`, upload local file
- `url_import`, import a remote file by url
- `convert_dropbox_link`, convert dropbox shared link into direct file link. Can take windows clipboard if no parameter provided.
- `url_sync`, let Carto to sync with a remote file by url
- `check_sync_status`, check status of a sync file
- `force_sync`, force sync a file instead of by schedule
- `list_sync_tables`, list all files in sync in account
- `list_sync_tables_df`, return sync file information in data frame
- `remove_sync`, remove sync relationship but keep the data file
- `sql_inquiry`, run sql inquiry
- `test_connection`, simple read only call just to test connection is working. Both this and `list_sync_tables` can be used to test if the Carto user name and API key is working at intended
- `sql_inquiry_df`, run sql inquiry and return result in data frame
- `sql_inquiry_save`, run sql inquiry and return result in file
- `sql_inquiry_save_geojson`, run sql inquiry and return result in GEOJson format in file
- `sql_batch_inquiry`, submit Batch sql inquiry
- `sql_batch_inquiry_id`, submit Batch sql inquiry and return job id
- `sql_batch_check`, check Batch sql inquiry status by job id
- `sql_batch_cancel`, cancel Batch sql inquiry

See help on individual function for details. Check Carto API document for more information about the API call and parameters.

### Some usage tips

I wrote about some tips in [my blog post](http://dracodoc.github.io/2017/01/21/rCarto/), which include:
- csv column type guessing
- update data after a map is created
- upload Gigabyte sized file to Carto in automated workflow
  + split data frame into small chunks csv
  + upload csv to dropbox, sync with Carto. Thus I can update the data file later and let Carto sync with it. If I upload a local file again will create a new table and it will not work with existing maps
  + merge chunks into one table in Carto with Batch sql inquiry
  + maintaince on the result table to make it usable for Carto
  + optimize huge data set for better performance
  + update the data set later with Batch sql inquiry
