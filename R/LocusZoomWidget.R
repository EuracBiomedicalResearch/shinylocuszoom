require(rjson)

#' Create an interactive locusZoom Plot
#'
#' This function implements a HTML widget for the integration of LocusZoom plots
#' into a shinyapp or Rmd document. It can work either with a JSON blob input or
#' a custom REST API server.
#'
#'
#' @param x  could be either a `character` or `data.frame` or `tibble` object that
#' can be serialize to JSON format.
#' In case if `x` is a character it should contain a valid REST API endpoint
#' where to retrieve json data from a summary statistic .
#' If `x` is a `data.frame` it will be Jsonize using [toJSON()][rjson::toJSON()]
#' function. The `data.frame` **must** contain the following **named** columns:
#'
#' **Mandatory**
#'
#' * `analysis`: a custom string/numeric value
#' * `variant` : format "{chr}:{pos}_{ref}/{alt}, it is used to look for LD
#' * `chromosome`: chromosome number
#' * `position`: position of the variant in BP
#' * `log_pvalue`: -log10(p_value)
#'
#'
#' **Optional**
#'
#' * `ref_allele`: reference allele
#' * `p_value`: raw p_value
#' * `beta`: effect of the allele either beta or OR
#' * `alt_allele`: alternate allele
#' * `ref_allele_freq`: frequency of the ref_allele
#' * `score_test_stat`: z-score
#' * `se`: standar deviation of the effect beta/OR
#'
#' See [https://portaldev.sph.umich.edu/docs/api/v1/?shell#single-variant-statistics](https://portaldev.sph.umich.edu/docs/api/v1/?shell#single-variant-statistics)
#' for further details on the format of the `data.frame` columns or either of
#' the JSON blob returned by the custom REST API endpoint.
#'
#' @param chr either a `character` or `integer` for the chromosome where to filter
#' for the variant
#' @param bpstart integer, plot variants located in chromosome `chr` where `bp>=bpstart`
#' @param bpend integer, plot variants located in chromosome `chr` where `bp<=bpend`
#' @param genome_build character specifying the genome build of the input data.
#' Should be one of "GRCh37" (default) or "GRCh38" **case-sensitive**. The genome build version
#' is used to merge with LD, recombination and gene position data.
#' @param bed data.frame, default is NULL, if provided an interval custom annotation track is added to the plot
#' @param main_title character, title of the locuszoom plot
#' @param elementId character, element identifier where the plot should be inserted, do not change it, it will be handled by Rmd or shiny
#'
#' @details In case a `url` of a REST API is given as input, the API should accept
#' GET requests. The base url of the API should accept 3 parameter, namely `chr`
#' `start` and `end`. Suppose the base `url` `http://myapi.com/api/v1`, the request
#' should work with the following command:
#'
#' `curl -G  http://myapi.com/api/v1/?chr=1&start=2088708&end=2135898`
#'
#' **NB** Provide the API url without the trailing slash.
#' 
#' **NB** This package is meant to be used in batch, but it makes some API 
#' requests on external servers. If multiple instance of the package run 
#' simultaneously or if multiple plots should be produced within a for cycle, 
#' please consider inserting a `sleep` timeout between requests in order to 
#' avoid server faults.
#'
#' Bed-like data.frame provided through the `bed` parameter should have a minimun of 4 columns named
#' exactly and ordered as follows:
#' `chromosome`, `start`, `end` and `state_name`
#' @return HTLM/Javascript to render in a shinyapp or any Rmd html-based notebook.
#'
#' @examples
#'
#' \dontrun{
#' jsonfile <- system.file("extdata/td2t_10_114550452-115067678.json", package="shinylocuszoom")
#' jsondata <- fromJSON(file=jsonfile)
#'
#' LocusZoomWidget(
#'  jsondata[["data"]],
#'  chr = 10,
#'  bpstart = 114550452,
#'  bpend = 115067678,
#'  genome_build = "GRCh37",
#'  main_title = "TD2 association")
#'
#'
#' # In the server.R:
#'
#' output$locuszoom <- renderLocusZoomWidget({
#'
#'   x <- get_mydata(
#'     chr = input$chr,
#'     bpstart = input$bpstart,
#'     bpend = input$bpend)
#'
#'   # Using JSON blob
#'   LocusZoomWidget(x,
#'                   chr = input$chr,
#'                   bpstart = input$bpstart,
#'                   bpend = input$bpend,
#'   )
#'   # Using API url
#'   url <- "http://myapi.com/api/v1/sumstat"
#'   LocusZoomWidget(url,
#'                   chr = input$chr,
#'                   bpstart = input$bpstart,
#'                   bpend = input$bpend,
#'   )

#' })
#'
#' # In the ui.R
#' ui <- fluidPage(
#'
#' # Application title
#' titlePanel("Locus zoom test"),
#'
#' sidebarLayout(
#'   sidebarPanel(
#'     selectInput(
#'       inputId = "chr",
#'       label = "Chromosome",
#'       choices = 1:22,
#'       selected = 1
#'     ),
#'     numericInput(
#'       inputId = "bpstart",
#'       label = "Bp from",
#'       value = 0
#'     ),
#'     numericInput(
#'       inputId = "bpend",
#'       label = "Bp to",
#'       value = 0
#'      )
#'   ),
#'
#'   mainPanel(
#'      LocusZoomWidgetOutput("locuszoom")
#'    )
#'  )
#')
#'}
#' @name LocusZoomWidget
#'
#' @rdname LocusZoomWidget-shiny
#'
#' @import htmlwidgets
#' @import rjson
#' @export
LocusZoomWidget <- function(
  x,
  chr,
  bpstart,
  bpend,
  genome_build = "GRCh37",
  main_title="Custom Locuszoom",
  bed=NULL,
  width = NULL, height = NULL, elementId = NULL) {

  #---- Prepare list of input parameters ----
  params <- list()
  params[["chr"]] <- chr
  params[["bpstart"]] <- bpstart
  params[["bpend"]] <- bpend
  params[["title"]] <- main_title
  params[["build"]] <- genome_build

  if (is.data.frame(x) | is.list(x)){
    mylist <- list(data=x, lastPage=NULL)
    params[["url"]] <- NULL
    params[["blob"]] <- toJSON(mylist)
    if (!is.null(bed)){
      interval_list <- list(data=bed, lastPage=NULL)
      params[["bed"]] <- toJSON(interval_list)
    }
  } else if (is.character(x)) {
    params[["url"]] <- x
    params[["blob"]] <- NULL
  } else {
    stop("Please provide a valid data.frame or valid url")
  }

  # create widget
  htmlwidgets::createWidget(
    name = 'LocusZoomWidget',
    params,
    width = width,
    height = height,
    package = 'shinylocuszoom',
    elementId = elementId
  )
}


#' Shiny bindings for LocusZoomWidget
#'
#' Output and render functions for using LocusZoomWidget within Shiny
#' applications and interactive Rmd documents.
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit (like \code{'100\%'},
#'   \code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
#'   string and have \code{'px'} appended.
#' @param expr An expression that generates a LocusZoomWidget
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Is \code{expr} a quoted expression (with \code{quote()})? This
#'   is useful if you want to save an expression in a variable.
#'
#' @name LocusZoomWidget-shiny
#'
#' @export
LocusZoomWidgetOutput <- function(outputId, width = '100%', height = '400px'){
  htmlwidgets::shinyWidgetOutput(outputId, 'LocusZoomWidget', width, height, package = 'shinylocuszoom')
}

#' @rdname LocusZoomWidget-shiny
#' @export
renderLocusZoomWidget <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) { expr <- substitute(expr) } # force quoted
  htmlwidgets::shinyRenderWidget(expr, LocusZoomWidgetOutput, env, quoted = TRUE)
}
