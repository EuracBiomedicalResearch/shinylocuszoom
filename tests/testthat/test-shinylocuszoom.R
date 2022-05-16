test_that("Input as number", {
  expect_error(expect_LocusZoomWidget(10, chr=10, bpstart=114550452, bpend=115067678))
})

get_data <- function(x){
  mydata <- fromJSON(file=x)
  return(mydata[["data"]])
}

process_bed <- function(x){
  x <- "~/work/test_locus_zoom/KG_TM_38_mask_chr10_114550452-115067678.bed"
  mybed <- read.delim(mybed.file, header=FALSE, stringsAsFactors = FALSE) %>%
    rename(chromosome=V1, start=V2, end=V3, state_name=V4) %>%
    mutate(
      id=1,
      public_id='',
      state_id=1)
  return(mybed)

}

test_that("Check defined results", {
  f <- system.file("inst/extdata/td2t_10_114550452-115067678.json", package="shinylocuszoom")
  mybed.file <- "~/work/test_locus_zoom/KG_TM_38_mask_chr10_114550452-115067678.bed"
  mybed <- process_bed(mybed.file)

  mydata <- get_data(x=f)
  res <- LocusZoomWidget(
    mydata,
    chr = 10,
    bpstart = 114550452,
    bpend = 115067678,
    genome_build = "GRCh37",
    main_title = "TD2 association", bed=mybed)
  expect_known_hash(res, hash = "0be008578c")
})
