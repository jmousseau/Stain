context("SlurmJob")


test_that("SlurmJob initializer sets main_file property.",  {
    sj <- SlurmJob$new("main.R")
    expect_equal(sj$main_file, "main.R")
    expect_error(SlurmJob$new())
})
