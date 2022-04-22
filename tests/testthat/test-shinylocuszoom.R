test_that("Input as number", {
  expect_error(expect_LocusZoomWidget(10, chr=10, bpstart=114550452, bpend=115067678))
})

get_data <- function(x){
  mydata <- fromJSON(file=x)
  return(mydata[["data"]])
}

test_that("Check defined results", {
  f <- system.file("inst/extdata/td2t_10_114550452-115067678.json", package="shinylocuszoom")
  mydata <- get_data(x=f)
  res <- LocusZoomWidget(
    mydata,
    chr = 10,
    bpstart = 114550452,
    bpend = 115067678,
    genome_build = "GRCh37",
    main_title = "TD2 association")
  expect_known_hash(res, hash = "0be008578c")
})
