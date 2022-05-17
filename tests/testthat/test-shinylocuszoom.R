test_that("Input as number", {
  expect_error(expect_LocusZoomWidget(10, chr=10, bpstart=114550452, bpend=115067678))
})

get_data <- function(x){
  mydata <- fromJSON(file=x)
  return(mydata[["data"]])
}

test_that("Check defined results", {
  f <- system.file("inst/extdata/td2t_10_114550452-115067678.json", package="shinylocuszoom")
  mybed.file <- system.file("inst/extdata/interval_td2t_10_114550452-115067678.json", package="shinylocuszoom")
  mybed <- get_data(x=mybed.file)
  mydata <- get_data(x=f)
  res <- LocusZoomWidget(
    mydata,
    chr = 10,
    bpstart = 114550452,
    bpend = 115067678,
    genome_build = "GRCh37",
    main_title = "TD2 association", bed=mybed)
  expect_known_hash(res, hash = "f748d13162")
})
