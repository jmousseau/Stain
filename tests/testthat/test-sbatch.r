context("sbatch")


test_that("All options are formated correctly", {
    expect_equal(sbatch_opts$begin("00:00:01"), "--begin=00:00:01")
    expect_equal(sbatch_opts$cpus_per_task(12), "--cpus-per-task=12")
    expect_equal(sbatch_opts$mail_user("user@address"),
                 "--mail-user=user@address")
    expect_equal(sbatch_opts$memory(1200), "--mem=1200")
    expect_equal(sbatch_opts$memory("16g"), "--mem=16g")
    expect_equal(sbatch_opts$nodes(1), "--nodes=1")
    expect_equal(sbatch_opts$ouput("file.txt"), "--ouput=file.txt")
    expect_equal(sbatch_opts$time("00:00:01"), "--time=00:00:01")
})

test_that("sbatch_opt creates a new key-value option.", {
    expect_equal(sbatch_opt("key")("value"), "--key=value")
})

test_that("Options equality is base on option keys.", {
    a <- sbatch_opt("a")("true")
    b <- sbatch_opt("b")("false")
    a_ <- sbatch_opt("a")("false")

    expect_true(sbatch_opts_equal(a, a_))
    expect_false(sbatch_opts_equal(a, b))

    expect_equal(sbatch_opts_insert(a_, c(a, b)), c(a_, b))
    expect_equal(sbatch_opts_insert(a, c(b)), c(b, a))
})

test_that("Multiple sbatch mail type options are combined while other options
          remain the same.", {
    # Note that the option duplication is on purpose.
    opts <- c(
        sbatch_mail_type_opts$begin,
        sbatch_mail_type_opts$begin,
        sbatch_mail_type_opts$end,
        sbatch_mail_type_opts$fail,
        sbatch_opts$memory("16g")
    )

    expected <- c(
        sbatch_opts$memory("16g"),
        sbatch_opt("mail-type")("BEGIN,END,FAIL")
    )

    expect_equal(sbatch_mail_type_combine(opts), expected)
})
