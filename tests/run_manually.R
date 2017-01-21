# tests that will have side effect, or require envrionment setup
# these have to be run manually with preparations and clean up
# this plus test_that should cover all exposed functions. internal functions are to support exposed functions.

# helper ----
update_env()  # should found user name in environment after update

# import ----
local_import("d:/DataFile/dropbox/Dropbox/bfa_sample_1.csv")
# copy a dropbox file share link to clipboard first
url_sync(convert_dropbox_link())
force_sync(list_sync_tables_df()[1, "id"])
remove_sync(list_sync_tables_df()[1, "id"])

# sql ----
sql_inquiry_save("SELECT * FROM bfa_sample_1 limit 2", "e:/test.json")
sql_inquiry_save_geojson("SELECT * FROM table_1 limit 2", "e:/testgeo.json")
job <- sql_batch_inquiry_id("SELECT * FROM bfa_sample_1 limit 2")
sql_batch_check(job)
sql_batch_cancel(job)
