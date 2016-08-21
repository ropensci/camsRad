context("cams_api")

test_that("Calling CAMS radiation service works", {
  skip_on_cran()

  username=Sys.getenv("CAMS_USERNAME")

  if(username=="") skip("need CAMS_USERNAME to be set")

  r <- cams_api(username, 60, 15, "2016-06-01", "2016-06-10",
                format = "application/csv")

  expect_is(r, "list")
  expect_equal(length(r),2)
  expect_equal(r$ok, TRUE)
  expect_equal(httr::has_content(r$respone), TRUE)
  expect_equal(httr::http_type(r$respone), "text/csv")
  expect_equal(r$respone$status_code, 200)
  expect_gt(length(readr::read_lines((rawToChar(r$respone$content)))), 250)
})
