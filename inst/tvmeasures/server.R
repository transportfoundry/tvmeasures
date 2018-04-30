#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)
library(tvmeasures)
library(leaflet)

shinyServer(function(input, output) {


  # Remix output table
  #
  # This returns a datatable with three columns, one for each of the remix-
  # derived measures.
  #
  output$remix_output <- renderDataTable({

    if (is.null(input$remix_file)){
      return (NULL)
    }
    inFile <- input$remix_file


    tryCatch({
      d <- read_csv(inFile$datapath) %>%
        transmute(
          `Project` = project,
          `Efficiency` = asset_mgmt(population, jobs, service_miles),
          `Compatibility` = landuse_comp(population, jobs),
          `Social Equity` = social_equity(pct_minority, pct_poverty)
        )

      DT::datatable(d) %>%
        DT::formatRound(2:3) %>%
        DT::formatPercentage(4)


    }, error = function(e){
      stop(e)

    })

  })

  output$cultural_environmental <- renderDataTable(iris)

  output$conveyal_output <- renderDataTable(iris)


  # Single project
  output$raster_output <- renderLeaflet({

    if (  # check input files
      is.null(input$raster_project) |
      is.null(input$project_shape) |
      is.null(input$raster_base)
    ){

      # if there is nothing supplied, just show a base map
      leaflet() %>%
        leaflet::addPolylines(data = marta_sf,
                              label = ~as.character(marta_sf$route_short_name),
                              color = "grey") %>%
        addProviderTiles("Esri.WorldGrayCanvas") %>%
        setView(-84.3880, 33.7490, zoom = 12)
    } else {

      rasterFile <- input$raster_project
      pr <- read_tiff(rasterFile$datapath)

      shapeFile <- input$project_shape
      shp <- read_project(shapeFile$datapath)

      baseRasterFile <- input$raster_base
      br <- read_tiff(baseRasterFile$datapath)

      leaflet_raster(pr - br, shp, TRUE, cuts = c(10000, 100000))

    }

  })


})