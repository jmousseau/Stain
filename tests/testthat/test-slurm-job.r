context("SlurmJob")


test_that("SlurmJob initializer sets main_file property.",  {
    expect_error(SlurmJob$new())
})
