# Prepare for CRAN ----

# Update dependencies in DESCRIPTION
# install.packages('attachment', repos = 'https://thinkr-open.r-universe.dev')
attachment::att_amend_desc()

# Check package coverage
covr::package_coverage()
covr::report()

# Run tests
devtools::test()
testthat::test_dir("tests/testthat/")

# Run examples
devtools::run_examples()

# autotest::autotest_package(test = TRUE)

# Check package as CRAN using the correct CRAN repo
withr::with_options(list(repos = c(CRAN = "https://cloud.r-project.org/")), {
  callr::default_repos()
  rcmdcheck::rcmdcheck(args = c("--no-manual", "--as-cran"))
})
# devtools::check(args = c("--no-manual", "--as-cran"))

# Check content
# install.packages('checkhelper', repos = 'https://thinkr-open.r-universe.dev')
# All functions must have either `@noRd` or an `@export`.
checkhelper::find_missing_tags()

# Check that you let the house clean after the check, examples and tests
# If you used parallel testing, you may need to avoid it for the next check with `Config/testthat/parallel: false` in DESCRIPTION
all_files_remaining <- checkhelper::check_clean_userspace()
all_files_remaining
# If needed, set back parallel testing with `Config/testthat/parallel: true` in DESCRIPTION

# Check spelling - No typo
# usethis::use_spell_check()
spelling::spell_check_package()

# Check URL are correct
# install.packages('urlchecker', repos = 'https://r-lib.r-universe.dev')
urlchecker::url_check()
urlchecker::url_update()

# check on other distributions
# _rhub v2
rhub::rhub_setup() # Commit, push, merge
rhub::rhub_doctor()
rhub::rhub_platforms()
rhub::rhub_check() # launch manually


# _win devel CRAN
devtools::check_win_devel()
# _win release CRAN
devtools::check_win_release()
# _macos CRAN
# Need to follow the URL proposed to see the results
devtools::check_mac_release()

# Check reverse dependencies
# remotes::install_github("r-lib/revdepcheck")
usethis::use_git_ignore("revdep/")
usethis::use_build_ignore("revdep/")

devtools::revdep()
library(revdepcheck)
# In another session because Rstudio interactive change your config:
id <- rstudioapi::terminalExecute(
  "Rscript -e 'revdepcheck::revdep_check(num_workers = 4)'"
)
rstudioapi::terminalKill(id)
# if [Exit Code] is not 0, there is a problem !
# to see the problem: execute the command in a new terminal manually.

# See outputs now available in revdep/
revdep_details(revdep = "pkg")
revdep_summary() # table of results by package
revdep_report()
# Clean up when on CRAN
revdep_reset()

# Update NEWS
# Bump version manually and add list of changes

# Add comments for CRAN
usethis::use_cran_comments(open = rlang::is_interactive())

# Upgrade version number
usethis::use_version(which = c("patch", "minor", "major", "dev")[1])

# Verify you're ready for release, and release
devtools::release()
