library(rCartoAPI)
context("**** import and sql ****")

test_that("import", {
  expect_output(list_sync_tables(), "Success")
  expect_true(is.data.frame(list_sync_tables_df()))
  # there may not be a valid sync pair.
  # expect_match(check_sync_status(list_sync_tables_df()[1, "id"]), "state")
})

test_that("sql", {
  expect_match(test_connection(), "total_rows")
  expect_equal(sql_inquiry_df("select 1")[1, 1], 1)
})
