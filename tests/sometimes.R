# tests that will have side effect, or require envrionment setup
# run read only tests in automated test. run other test here from time to time
# to cover all exposed functions. internal functions are to support exposed functions.

# helper ----
update_env()  # should found user name in environment after update

# import ----
local_import("d:/DataFile/dropbox/Dropbox/bfa_sample_1.csv")
# copy a dropbox file share link to clipboard first
url_sync(convert_dropbox_link())
force_sync(list_sync_tables_df()[1, "id"])
remove_sync(list_sync_tables_df()[1, "id"])
