# shinylocuszoom

[![R build status](https://github.com/EuracBiomedicalResearch/shinylocuszoom/actions/workflows/check-standard.yaml/badge.svg?branch=main)](https://github.com/EuracBiomedicalResearch/shinylocuszoom/actions/workflows/check-standard.yaml/badge.svg?branch=main)


shinylocuszoom is a package based on [htmlwidgets](https://www.htmlwidgets.org/) to integrate LocusZoom plots into a shiny app or Rmd notebook.

It is based on the [LocusZoom.js](https://statgen.github.io/locuszoom) library.

## Installation 

Using `devtools` to install the package (**recommended**)

```r
devtools::install_url("https://github.com/EuracBiomedicalResearch/shinylocuszoom.git")
```

Or clone the repository, build the package and install it:

```
git clone https://github.com/EuracBiomedicalResearch/shinylocuszoom.git
R CMD build shinylocuszoom
R CMD INSTALL shinylocuszoom_<latest>.tar.gz # Change version according to the last version
```
----- 

## Usage

Once installed you can test if the package works correctly with the following commands within `R`

Load the package and get a JSON file
```r
library(shinylocuszoom)

# Get a json file included in the package already formatted
jsonfile <- system.file("extdata/td2t_10_114550452-115067678.json", package="shinylocuszoom")
jsondata <- fromJSON(file=jsonfile)
```

Alternatively you can provide a `data.frame` formatted as specified in the `R` help as input 
of the `LocusZoomWidget` function. 

Within `Rstudio` a LocusZoom plot appears in the Window panel, otherwise using standard `R` a new page in
a web browser will pop-up with the LocusZoom plot.

```r
LocusZoomWidget(
 jsondata[["data"]],
 chr = 10,
 bpstart = 114550452,
 bpend = 115067678,
 genome_build = "GRCh37",
 main_title = "TD2 association")
```

### Integration with `shinyapp`

In the `ui.R` file or in the `ui` variable in the `app.R` file.

```r
ui <- fluidPage(

# Application title
titlePanel("Locus zoom test"),

sidebarLayout(
  # Sidebar 
  sidebarPanel(

    # Chromosome selection
    selectInput(
      inputId = "chr",
      label = "Chromosome",
      choices = 1:22,
      selected = 1
    ),

    # Interval selection in BP
    numericInput(
      inputId = "bpstart",
      label = "Bp from",
      value = 0
    ),
    numericInput(
      inputId = "bpend",
      label = "Bp to",
      value = 0
     )
  ),

  mainPanel(
     # Rendering of the LocusZoom Plot
     LocusZoomWidgetOutput("locuszoom")
   )
 )
)

```

In the `server.R` file or in the `server` variable in the `app.R` file.

```r

get_mydata <- function(chr, bpstart, bpend){
   # Write your own code to read a summary
   # statistic file and format as described
   # in the manual of the function 
   # LocusZoomWidget
}

output$locuszoom <- renderLocusZoomWidget({

  x <- get_mydata(
    chr = input$chr,
    bpstart = input$bpstart,
    bpend = input$bpend)

  # Using JSON blobs
  LocusZoomWidget(x,
                  chr = input$chr,
                  bpstart = input$bpstart,
                  bpend = input$bpend,
  )

  # Using API url
  url <- "http://myapi.com/api/v1/sumstat"
  LocusZoomWidget(url,
                  chr = input$chr,
                  bpstart = input$bpstart,
                  bpend = input$bpend,
  )
})

```

For further feature and how to integrate with shiny see the full example in the manual of the R function.
See also

```r
?LocusZoomWidget
```

# Authors 
[Michele Filosi](mailto:michele.filosi@eurac.edu)


