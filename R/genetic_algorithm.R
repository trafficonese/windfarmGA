#' @title Run a Genetic Algorithm to optimize a wind farm layout
#' @name genetic_algorithm
#' @description Run a Genetic Algorithm to optimize the layout of wind turbines
#'   on a given area. The algorithm works with a fixed amount of turbines, a
#'   fixed rotor radius and a mean wind speed value for every incoming wind
#'   direction.
#'
#' @export
#'
#' @param Polygon1 The considered area as SpatialPolygon, SimpleFeature Polygon
#'   or coordinates as matrix/data.frame
#' @param GridMethod Should the polygon be divided into rectangular or hexagonal
#'   grid cells? The default is "Rectangular" grid. Hexagonal grids
#'   are computed when assigning "h" or "hexagon" to this input variable.
#' @param Rotor The rotor radius in meter
#' @param n The amount of turbines
#' @param fcrR A numeric value used for grid spacing. Default is \code{5}
#' @param referenceHeight The height at which the incoming wind speeds were
#'   measured. Default is \code{RotorHeight}
#' @param RotorHeight The height of the turbine hub
#' @param SurfaceRoughness A surface roughness length in meters.
#'   With the terrain effect model, a surface roughness is calculated for every
#'   grid cell using the elevation and land cover data. Default is \code{0.3}
#' @param sourceCCL The path to the Corine Land Cover raster (.tif). Only
#'   required when the terrain effect model is activated.
#' @param sourceCCLRoughness The source to the adapted Corine Land Cover legend
#'   as .csv file. Only required when terrain effect model is activated. As
#'   default a .csv file within this package (\file{~/extdata}) is taken that
#'   was already adapted manually.
#' @param Proportionality A numeric value used for the grid calculation, as it
#'   determines the percentage a grid cell must overlay the area.
#'   Default is \code{1}
#' @param iteration The number of iterations. Default is \code{20}
#' @param mutr A numeric mutation rate. Default is \code{0.008}
#' @param vdirspe A data.frame containing the wind speeds, directions and
#'   probabilities. See \code{\link{windata_format}}.
#' @param topograp Boolean value, which indicates if the terrain effect model
#'   should be enabled or not. Default is \code{FALSE}
#' @param elitism Boolean value, which indicates whether elitism should be
#'   activated or not. Default is \code{TRUE}
#' @param nelit If \code{elitism} is TRUE, this input determines the amount
#'   of individuals in the elite group. Default is 7
#' @param selstate Determines which selection method is used, "FIX" selects a
#'   constant percentage and "VAR" selects a variable percentage, depending on
#'   the development of the fitness values. Default is "FIX"
#' @param crossPart1 Determines which crossover method is used, "EQU" divides
#'   the genetic code at equal intervals and "RAN" divides the genetic code at
#'   random locations. Default is \code{"EQU"}
#' @param trimForce If \code{TRUE} the algorithm will use a probabilistic
#'   approach to correct the windfarms to the desired amount of turbines.
#'   If \code{FALSE} the adjustment will be random. Default is \code{FALSE}
#' @param Projection A spatial reference system. Depending on your PROJ-version,
#'   it should either be a numeric `EPSG-code` or a `Proj4-string`.
#'   Default is \code{EPSG:3035}
#' @param weibull A boolean value that specifies whether to take Weibull
#'   parameters into account. If \code{TRUE}, the wind speed values
#'   of \code{vdirspe} are ignored. The algorithm will calculate the mean
#'   wind speed for every wind turbine according to the Weibull parameters.
#'   Default is \code{FALSE}
#' @param weibullsrc A list of Weibull parameter rasters, where the first list
#'   item must be the shape parameter raster `k` and the second item must be the
#'   scale parameter raster `a` of the Weibull distribution. If no list is
#'   given, then rasters included in the package are used instead, which
#'   currently only cover Austria. This variable is only used
#'   if \code{weibull = TRUE}.
#' @param Parallel A boolean value, indicating whether parallel processing
#'   should be used. The *parallel* and *doParallel* packages are used for
#'   parallel processing. Default is \code{FALSE}
#' @param numCluster If \code{Parallel} is TRUE, this variable defines the
#'   number of clusters to be used. Default is \code{2}
#' @param verbose If TRUE it will print information for every generation.
#'   Default is \code{FALSE}
#' @param plotit If TRUE it will plot the best windfarm of every generation.
#'   Default is \code{FALSE}
#'
#' @family Genetic Algorithm Functions
#' @return The result is a matrix with aggregated values per generation; the
#'   best individual regarding energy and efficiency per generation, some fuzzy
#'   control variables per generation, a list of all fitness values per
#'   generation, the amount of individuals after each process, a matrix of all
#'   energy, efficiency and fitness values per generation, the selection and
#'   crossover parameters, a matrix with the generational difference in maximum
#'   and mean energy output, a matrix with the given inputs, a dataframe with
#'   the wind information, the mutation rate per generation and a matrix with
#'   all tested wind farm layouts.
#'
#' @details A terrain effect model can be included in the optimization process.
#'   Therefore, a digital elevation model will be downloaded automatically via
#'   the \code{elevatr::get_elev_raster} function. A land cover raster can also
#'   downloaded automatically from the EEA-website, or the path to a raster file
#'   can be passed to \code{sourceCCL}. The algorithm uses an adapted version of
#'   the Raster legend ("clc_legend.csv"), which is stored in the package
#'   directory \file{~/inst/extdata}. To use other values for the land cover
#'   roughness lengths, insert a column named \strong{"Rauhigkeit_z"} to the
#'   .csv file, assign a surface roughness length to all land cover types. Be
#'   sure that all rows are filled with numeric values and save the file with
#'   \strong{";"} separation. Assign the path of the file to the input variable
#'   \code{sourceCCLRoughness} of this function.
#'
#' @examples \dontrun{
#' ## Create a random rectangular shapefile
#' library(sf)
#'
#' Polygon1 <- sf::st_as_sf(sf::st_sfc(
#'   sf::st_polygon(list(cbind(
#'     c(4498482, 4498482, 4499991, 4499991, 4498482),
#'     c(2668272, 2669343, 2669343, 2668272, 2668272)
#'   ))),
#'   crs = 3035
#' ))
#'
#' ## Create a uniform and unidirectional wind data.frame and plot the
#' ## resulting wind rose
#' data.in <- data.frame(ws = 12, wd = 0)
#' windrosePlot <- plot_windrose(
#'   data = data.in, spd = data.in$ws,
#'   dir = data.in$wd, dirres = 10, spdmax = 20
#' )
#'
#' ## Runs an optimization run for 20 iterations with the
#' ## given shapefile (Polygon1), the wind data.frame (data.in),
#' ## 12 turbines (n) with rotor radii of 30m (Rotor) and rotor height of 100m.
#' result <- genetic_algorithm(
#'   Polygon1 = Polygon1,
#'   n = 12,
#'   vdirspe = data.in,
#'   Rotor = 30,
#'   RotorHeight = 100
#' )
#' plot_windfarmGA(result = result, Polygon1 = Polygon1)
#' }
genetic_algorithm <- function(Polygon1, GridMethod, Rotor, n, fcrR,
                              referenceHeight, RotorHeight, SurfaceRoughness,
                              Proportionality, iteration, mutr, vdirspe,
                              topograp, elitism, nelit, selstate, crossPart1,
                              trimForce, Projection, sourceCCL,
                              sourceCCLRoughness, weibull, weibullsrc,
                              Parallel, numCluster, verbose = FALSE,
                              plotit = FALSE) {

  ## set Graphic Params ###############
  if (plotit) {
    oldpar <- graphics::par(no.readonly = TRUE)
    on.exit(par(oldpar))
    plot.new()
    graphics::par(ask = FALSE)
  }

  ## MISSING ARGUMENTS ###############
  if (missing(fcrR)) {
    fcrR <- 5
  }
  if (missing(topograp)) {
    topograp <- FALSE
  }
  if (missing(GridMethod)) {
    GridMethod <- "Rectangular"
  }
  if (missing(Parallel)) {
    Parallel <- FALSE
  }
  if (missing(numCluster)) {
    numCluster <- 2
  }
  if (missing(weibull)) {
    weibull <- FALSE
  }
  if (missing(selstate)) {
    selstate <- "FIX"
  }
  if (missing(crossPart1)) {
    crossPart1 <- "EQU"
  }
  if (missing(SurfaceRoughness)) {
    SurfaceRoughness <- 0.3
  }
  if (missing(Proportionality)) {
    Proportionality <- 1
  }
  if (missing(mutr)) {
    mutr <- 0.008
  }
  if (missing(elitism)) {
    elitism <- TRUE
    if (missing(nelit)) {
      nelit <- 7
    }
  }
  if (missing(trimForce)) {
    trimForce <- FALSE
  }
  if (missing(RotorHeight)) {
    stop("The variable 'RotorHeight' is not defined. Assign the turbine heights to 'RotorHeight'.")
  }
  if (missing(referenceHeight)) {
    referenceHeight <- RotorHeight
  }
  if (missing(iteration)) {
    iteration <- 20
  }
  if (missing(Projection)) {
    if (utils::compareVersion(sf::sf_extSoftVersion()[[3]], "6") > 0) {
      ProjLAEA <- 3035
    } else {
      ProjLAEA <- "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
    }
  } else {
    ProjLAEA <- Projection
  }
  if (missing(vdirspe)) {
    stop("No Winddata is given.")
  }
  if (missing(n)) {
    stop("The variable 'n' is not defined. Assign the number of turbines to 'n'.")
  }
  if (missing(Rotor)) {
    stop("The variable 'Rotor' is not defined. Assign the rotor radius to 'Rotor'.")
  }


  ## INIT VARIABLES 1 #################
  selstate <- toupper(selstate)
  crossPart1 <- toupper(crossPart1)

  ## Is the Polygon Spatial / SF / coordinates - It will transform to sf-Polygons
  Polygon1 <- isSpatial(Polygon1, ProjLAEA)
  if (is.na(st_crs(Polygon1))) {
    stop("The input area is not projected.")
  }

  ## Grid size calculation
  resol2 <- fcrR * Rotor

  ## Max Amount of individuals in the Crossover-Method
  CrossUpLimit <- getOption("windfarmGA.max_population")

  ## Start Parallel Cluster ###############
  ## Is Parallel processing activated? Check the max number of cores and set to max-1 if value exceeds.
  if (Parallel) {
    if (!is_parallel_installed()) {
      stop(
        "The package 'parallel' is required for this function, but it is not installed.\n",
        "Please install it with `install.packages('parallel')`"
      )
    }
    if (!is_doparallel_installed()) {
      stop(
        "The package 'doParallel' is required for this function, but it is not installed.\n",
        "Please install it with `install.packages('doParallel')`"
      )
    }
    if (!is_foreach_installed()) {
      stop(
        "The package 'foreach' is required for this function, but it is not installed.\n",
        "Please install it with `install.packages('foreach')`"
      )
    }
    max_cores <- parallel::detectCores()
    if (numCluster > max_cores) {
      warning("Maximum number of cores is: ", max_cores, "\n'numCluster' will be set to: ", max_cores - 1)
      numCluster <- max_cores - 1
    }
    type_cluster <- "PSOCK" ## TODO - should this be available as option too?
    cl <- parallel::makeCluster(numCluster, type = type_cluster)
    doParallel::registerDoParallel(cl)
  }

  ## WEIBULL ###############
  ## Is Weibull activated? If no source is given, take values from package
  if (weibull) {
    if (verbose) message("Weibull Distribution is used.")

    if (missing(weibullsrc)) {
      stop(
        "No weibull data is given in `weibullsrc`.\nIt must be a list of 2 rasters:\n",
        "  - shape parameter raster\n", "  - scale parameter raster"
      )
    } else {
      if (verbose) message("Weibull data is used.\n")

      ## Project Shapefile to raster, Crop/Mask and project raster back
      if (!inherits(weibullsrc[[1]], "SpatRaster")) {
        weibullsrc[[1]] <- terra::rast(weibullsrc[[1]])
      }
      if (!inherits(weibullsrc[[2]], "SpatRaster")) {
        weibullsrc[[2]] <- terra::rast(weibullsrc[[2]])
      }
    }
    ## Project Shapefile to raster proj, Crop/Mask and project raster back
    shape_project <- st_transform(Polygon1, crs = st_crs(weibullsrc[[2]]))
    weibl_k <- terra::crop(x = weibullsrc[[1]], y = shape_project, mask = TRUE)

    a <- weibullsrc[[1]]
    terra::crop(x = a, y = shape_project, mask = TRUE)
    weibl_a <- terra::crop(x = weibullsrc[[2]], y = shape_project, mask = TRUE)

    estim_speed_raster <- weibl_a * gamma(1 + (1 / values(weibl_k)))
    estim_speed_raster <- terra::project(
      estim_speed_raster,
      terra::crs(Polygon1)
    )
  } else {
    estim_speed_raster <- FALSE
  }

  ## CHECK INPUTS ###############
  ## Check if Input Data is correct and prints it out.
  if (crossPart1 != "EQU" && crossPart1 != "RAN") {
    crossPart1 <- readinteger()
  }
  if (selstate != "FIX" && selstate != "VAR") {
    selstate <- readintegerSel()
  }
  topgraphie_text <- topograp
  if (inherits(topograp, "SpatRaster") ||
    inherits(topograp, "RasterLayer") ||
    inherits(topograp, "stars")) {
    topgraphie_text <- TRUE
  }
  inputData <- list(
    Input_Data = rbind(
      "Rotorradius" = Rotor,
      "Number of turbines" = n,
      "Grid Shape Factor" = fcrR,
      "Iterations" = iteration,
      "Mutation Rate" = mutr,
      "Percentage of Polygon" = Proportionality,
      "Topographie" = topgraphie_text,
      "Elitarism" = elitism,
      "Selection Method" = selstate,
      "Trim Force Method Used" = trimForce,
      "Crossover Method Used" = crossPart1,
      "Reference Height" = referenceHeight,
      "Rotor Height" = RotorHeight,
      "Resolution" = resol2,
      "Parallel Processing" = Parallel,
      "Number Clusters" = numCluster,
      "Active Weibull" = weibull,
      "Grid Method" = GridMethod,
      "Projection" = ProjLAEA
    )
  )

  inputWind <- list(Windspeed_Data = vdirspe)
  if (verbose) {
    print(inputData)
    print(inputWind)
  }

  ## Winddata Formatting #######################
  winddata <- windata_format(vdirspe)

  #######################
  ## Project Polygon ###############
  if (utils::compareVersion(sf::sf_extSoftVersion()[[3]], "6") > 0) {
    if (suppressWarnings(!isTRUE(all.equal(
      st_crs(Polygon1),
      st_crs(ProjLAEA)
    )))) {
      Polygon1 <- sf::st_transform(Polygon1, ProjLAEA)
    }
  } else {
    if (as.character(terra::crs(Polygon1)) != ProjLAEA) {
      Polygon1 <- sf::st_transform(Polygon1, ProjLAEA)
    }
  }

  ## Make GRID ###############
  ## Calculate a Grid and an indexed data.frame with coordinates and grid cell Ids.
  GridMethod <- toupper(GridMethod)
  ## Decide if the space division should be rectangular or in hexagons.
  if (GridMethod != "HEXAGON" && GridMethod != "H") {
    # Calculate a Grid and an indexed data.frame with coordinates and grid cell Ids.
    Grid1 <- grid_area(Polygon1, resol2, Proportionality)
    Grid <- Grid1[[1]]
    grid_filtered <- Grid1[[2]]
  } else {
    # Calculate a Grid with hexagonal grid cells
    Grid1 <- hexa_area(Polygon1, resol2)
    Grid <- Grid1[[1]]
    grid_filtered <- Grid1[[2]]
  }
  n_gridcells <- nrow(Grid)

  ## INIT VARIABLES 2 ###############
  ## Determine the amount of initial individuals and create initial population.
  nStart <- (n_gridcells * n) / iteration
  if (nStart < 100) {
    nStart <- 100
  }
  if (nStart > 300) {
    nStart <- 300
  }
  nStart <- ceiling(nStart)
  startsel <- init_population(Grid, n, nStart)
  ## Initialize all needed variables as list.
  maxParkwirkungsg <- 0
  allparkcoeff <- vector("list", iteration)
  bestPaEn <- vector("list", iteration)
  bestPaEf <- vector("list", iteration)
  fuzzycontr <- vector("list", iteration)
  fitnessValues <- vector("list", iteration)
  nindiv <- vector("list", iteration)
  clouddata <- vector("list", iteration)
  selcross <- vector("list", iteration)
  beorwor <- vector("list", iteration)
  mut_rate <- vector("list", iteration)
  allCoords <- vector("list", iteration)

  ## TERRAIN EFFECT MODEL ###############
  ## Checks if terrain effect model is activated, and makes necessary caluclations.
  if (isFALSE(topograp)) {
    if (verbose) {
      message("Topography and orography are not taken into account.")
    }
    srtm_crop <- ""
    cclRaster <- ""
  } else {
    terrain_data <- terrain_model(topograp, Polygon1, sourceCCL, sourceCCLRoughness, plotit, verbose)
    srtm_crop <- terrain_data$srtm_crop
    cclRaster <- terrain_data$cclRaster
    topograp <- TRUE
  }


  ## GENETIC ALGORITHM #################
  if (verbose) {
    message("\nStart Genetic Algorithm ...")
  }
  rbPal <- grDevices::colorRampPalette(c("red", "green"))
  i <- 1
  while (i <= iteration) {
    if (!verbose) {
      message(".", appendLF = FALSE)
    }
    ## FITNESS (and get_grids) ###############
    if (i == 1) {
      fit <- fitness(
        selection = startsel, referenceHeight = referenceHeight,
        RotorHeight = RotorHeight,
        SurfaceRoughness = SurfaceRoughness,
        Polygon = Polygon1, resol1 = resol2, rot = Rotor,
        dirspeed = winddata, srtm_crop = srtm_crop,
        topograp = topograp, cclRaster = cclRaster,
        weibull = estim_speed_raster,
        Parallel = Parallel, numCluster = numCluster
      )
    } else {
      getRectV <- get_grids(mut1, Grid)
      fit <- fitness(
        selection = getRectV, referenceHeight = referenceHeight,
        RotorHeight = RotorHeight,
        SurfaceRoughness = SurfaceRoughness,
        Polygon = Polygon1, resol1 = resol2, rot = Rotor,
        dirspeed = winddata, srtm_crop = srtm_crop,
        topograp = topograp, cclRaster = cclRaster,
        weibull = estim_speed_raster,
        Parallel = Parallel, numCluster = numCluster
      )
    }

    ## Fitness Result Processing ###############
    allparks <- do.call("rbind", fit)
    allparksUni <- subset.matrix(allparks,
      subset = !duplicated(allparks[, "Run"])
    )

    allCoords[[i]] <- allparks
    maxparkfitness <- round(max(allparksUni[, "Parkfitness"]), 4)
    meanparkfitness <- round(mean(allparksUni[, "Parkfitness"]), 3)
    minparkfitness <- round(min(allparksUni[, "Parkfitness"]), 3)
    MaxEnergyRedu <- round(max(allparksUni[, "EnergyOverall"]), 2)
    MeanEnergyRedu <- round(mean(allparksUni[, "EnergyOverall"]), 2)
    MinEnergyRedu <- round(min(allparksUni[, "EnergyOverall"]), 2)
    maxParkwirkungsg <- round(max(allparksUni[, "EfficAllDir"]), 2)
    meanParkwirkungsg <- round(mean(allparksUni[, "EfficAllDir"]), 2)
    minParkwirkungsg <- round(min(allparksUni[, "EfficAllDir"]), 2)
    allparkcoeff[[i]] <- cbind(
      maxparkfitness, meanparkfitness, minparkfitness,
      MaxEnergyRedu, MeanEnergyRedu, MinEnergyRedu,
      maxParkwirkungsg, meanParkwirkungsg, minParkwirkungsg
    )

    clouddata[[i]] <- subset.matrix(allparksUni,
      select = c(
        "EfficAllDir",
        "EnergyOverall",
        "Parkfitness"
      )
    )

    if (verbose) {
      message(c(
        "\n\n", i, ": Round. Max Energy ", allparkcoeff[[i]][, "MaxEnergyRedu"],
        " W and Efficiency ", allparkcoeff[[i]][, "maxParkwirkungsg"], " %"
      ))
    }

    ## Highest Energy Output
    xd <- max(allparks[, "EnergyOverall"])
    ind <- allparks[, "EnergyOverall"] == xd
    bestPaEn[[i]] <- allparks[ind, ][1:n, , drop = FALSE]
    ## Highest Efficiency
    xd1 <- max(allparks[, "EfficAllDir"])
    ind1 <- allparks[, "EfficAllDir"] == xd1
    bestPaEf[[i]] <- allparks[ind1, ][1:n, , drop = FALSE]

    # Print out most relevant information on Generation i
    afvs <- allparks[allparks[, "EnergyOverall"] == max(
      allparks[, "EnergyOverall"]
    ), ]
    if (verbose) {
      message(paste("How many individuals exist: ", length(fit)))
      message(paste(
        "How many parks are in local Optimum: ",
        (length(afvs[, 1]) / n)
      ))
    }
    nindivfit <- length(fit)

    if (plotit) {
      lebre <- length(unique(bestPaEn[[i]][, "AbschGesamt"]))
      if (lebre < 2) {
        Col <- "green"
      } else {
        Col <- rbPal(lebre)[as.numeric(cut(-bestPaEn[[i]][, "AbschGesamt"],
          breaks = lebre
        ))]
      }
      lebre2 <- length(unique(bestPaEf[[i]][, "AbschGesamt"]))
      if (lebre2 < 2) {
        Col1 <- "green"
      } else {
        Col1 <- rbPal(lebre2)[as.numeric(cut(-bestPaEf[[i]][, "AbschGesamt"],
          breaks = lebre2
        ))]
      }
    }

    x <- round(bestPaEn[[i]][, "EnergyOverall"][[1]], 2)
    y <- round(bestPaEn[[i]][, "EfficAllDir"][[1]], 2)
    e <- bestPaEn[[i]][, "EfficAllDir"]
    x1 <- round(bestPaEf[[i]][, "EnergyOverall"][[1]], 2)
    y1 <- round(bestPaEf[[i]][, "EfficAllDir"][[1]], 2)
    e1 <- bestPaEf[[i]][, "EfficAllDir"]
    ##################

    if (plotit) {
      graphics::par(mfrow = c(1, 2))
      plot(st_geometry(Polygon1),
        col = "lightblue",
        main = paste(
          i, "Round \n Best Energy Output: ", x,
          "W/h \n Efficiency: ", y, "%"
        ),
        sub = paste("\n Number of turbines: ", length(e))
      )
      plot(grid_filtered, add = TRUE)
      graphics::points(bestPaEn[[i]][, "X"], bestPaEn[[i]][, "Y"],
        col = Col, pch = 20, cex = 1.5
      )
      plot(st_geometry(Polygon1),
        col = "lightblue",
        main = paste(
          i, "Round \n Best Efficiency Output: ",
          x1, "W/h \n Efficiency: ", y1, "%"
        ),
        sub = paste("\n Number of turbines: ", length(e1))
      )
      plot(grid_filtered, add = TRUE)
      graphics::points(bestPaEf[[i]][, "X"], bestPaEf[[i]][, "Y"],
        col = Col1, pch = 20, cex = 1.5
      )
    }

    ## Fuzzy Control ###############
    if (i > 20) {
      besPE <- do.call("rbind", lapply(bestPaEn[1:i], function(x) {
        max(x[, "EnergyOverall"])
      }))
      maxBisher <- max(besPE)
      WhichMaxBs <- which(besPE == max(besPE))

      if (length(WhichMaxBs) >= 2) {
        BestForNo <- bestPaEn[sample(WhichMaxBs, 2)]
        BestForNo[[1]][, "Run"] <- length(fit) + 1
        BestForNo[[2]][, "Run"] <- length(fit) + 2
      } else {
        BestForNo <- bestPaEn[WhichMaxBs]
        BestForNo <- append(BestForNo, BestForNo)
        BestForNo[[1]][, "Run"] <- length(fit) + 1
        BestForNo[[2]][, "Run"] <- length(fit) + 2
      }

      last7 <- besPE[i:(i - 5)]
      if (!any(last7 == maxBisher)) {
        if (verbose) {
          message(paste(
            "Park with highest Fitness level to date ",
            "is replaced in the list.", "\n"
          ))
        }
        fit <- append(fit, BestForNo)
      }
    }
    if (i == 1) {
      ## TODO I do have such a matrix already with that info or??
      t0 <- subset.matrix(allparks, !duplicated(allparks[, "Run"]))
      t0 <- t0[, "Parkfitness"]
      fitnessValues[[i]] <- t0
      rangeFitnessVt0 <- range(t0)
      maxt0 <- max(t0)
      meant0 <- mean(t0)
      allcoef0 <- c(rangeFitnessVt0, meant0)
      fuzzycontr[[i]] <- rbind(allcoef0)
      colnames(fuzzycontr[[i]]) <- c("Min", "Max", "Mean")
      teil <- 2
      if (selstate == "VAR") {
        teil <- 1.35
      }
      u <- 1.1
      beorwor[[i]] <- cbind(0, 0)
    }
    ## TODO - better fuzzy model and expose weights and values by options?
    if (i >= 2 && i <= iteration) {
      t0 <- subset.matrix(allparks, !duplicated(allparks[, "Run"]))
      t0 <- t0[, "Parkfitness"]
      fitnessValues[[i]] <- t0
      rangeFitnessVt0 <- range(t0)
      maxt0 <- max(t0)
      meant0 <- mean(t0)
      mint0 <- min(t0)
      t1 <- fitnessValues[[i - 1]]
      rangeFitnessVt1 <- range(t1)
      maxt1 <- max(t1)
      meant1 <- mean(t1)
      mint1 <- min(t1)
      maxDif <- maxt0 - maxt1
      meanDif <- meant0 - meant1
      minDif <- mint0 - mint1
      WeightDif <- c(0.80, 0.2, 0.0)
      maxunt <- (maxDif * WeightDif[1]) +
        (meanDif * WeightDif[2]) + (minDif * WeightDif[3])
      allcoef1 <- c(rangeFitnessVt0, meant0)
      allcoef2 <- c(rangeFitnessVt1, meant1)
      fuzzycontr[[i]] <- rbind(allcoef1, allcoef2)
      colnames(fuzzycontr[[i]]) <- c("Min", "Max", "Mean")

      if (maxunt <= 0) {
        pri <- "deteriorated"
        teil <- teil - 0.02
        u <- u - 0.06
      } else {
        pri <- "improved"
        teil <- teil + 0.017
        u <- u + 0.03
      }

      if (teil <= 4 / 3) {
        teil <- 4 / 3
        if (verbose) message(paste("Max 75% selected. SP: ", teil))
      }
      if (length(fit) <= 20) {
        teil <- 1
        u <- u + 0.1
        if (verbose) {
          message(paste(
            "Less than 20 individuals. Select all and increase ",
            "Crossover-point rate. CPR: ", u, "SP: ", teil
          ))
        }
      }

      u <- round(u, 2)
      teil <- round(teil, 3)

      if (verbose) {
        message(paste(
          "Fitness of this population (", i,
          "), compared to the prior,", pri,
          "by", round(maxunt, 2), "W"
        ))
      }
      meanunt <- meant0 - meant1
      beorwor[[i]] <- cbind(maxunt, meanunt)
    }

    ## SELECTION #################
    if (selstate == "FIX") {
      if (teil == 1) {
        teil <- 1
      } else {
        teil <- 2
      }
    }
    if (crossPart1 == "EQU") {
      u <- round(u, 2)
    }

    ## How many are selected and how much crossover points are used?
    selcross[[i]] <- cbind(cross = trunc(u + 1), teil)
    selec6best <- selection(
      fit = fit, Grid = Grid, teil = teil,
      elitism = elitism, nelit = nelit,
      selstate = selstate, verbose = verbose
    )

    selec6best_bin <- selec6best[[1]]
    if (verbose) {
      message(paste(
        "Selection  -  Amount of Individuals: ",
        length(selec6best_bin[1, -1])
      ))
    }
    nindivsel <- length(selec6best_bin[1, -1])

    ## CROSSOVER #################
    ## u determines the amount of crossover points,
    ## crossPart determines the method used (Equal/Random),
    ## uplimit is the maximum allowed permutations
    crossOut <- crossover(
      se6 = selec6best, u = u, uplimit = CrossUpLimit,
      crossPart = crossPart1,
      verbose = verbose, seed = NULL
    )
    if (verbose) {
      message(paste(
        "Crossover  -  Amount of Individuals: ",
        length(crossOut[1, ])
      ))
    }
    nindivcros <- length(crossOut[1, ])

    ## MUTATION #################
    ## Variable Mutation Rate is activated if more than 2 individuals
    ## represent the current best solution.
    loOp <- (length(afvs[, 1]) / n)
    if (loOp > 2) {
      mutrn <- round(runif(1, 0.03, 0.1), 2)
      t1 <- (loOp * 1.25) / 42
      mutrn <- mutrn * (1 + t1)
      mutrn <- round(mutrn + ((i) / (20 * iteration)), 5)
      mut <- mutation(a = crossOut, p = mutrn, seed = NULL)
      mut_rat <- mutrn
      if (verbose) {
        message(paste("Variable Mutation Rate is", mutrn))
      }
    } else {
      mut <- mutation(a = crossOut, p = mutr, seed = NULL)
      mut_rat <- mutr
    }
    mut_rate[[i]] <- mut_rat
    if (verbose) {
      message(paste("Mutation   -  Amount of Individuals: ", length(mut[1, ])))
    }
    nindivmut <- length(mut[1, ])

    ## TRIMTON #################
    ## After Crossover and Mutation, the amount of turbines in a windpark
    ## change and have to be corrected to the required amount of turbines.
    mut1 <- trimton(
      mut = mut, nturb = n, allparks = allparks,
      nGrids = n_gridcells, trimForce = trimForce,
      seed = NULL
    )

    if (verbose) {
      message(paste(
        "TrimToN    -  Amount of Individuals: ",
        length(mut1[1, ])
      ))
    }

    nindiv[[i]] <- cbind(nindivfit, nindivsel, nindivcros, nindivmut)
    if (maxParkwirkungsg == 100) {
      i <- iteration + 1
    } else {
      i <- i + 1
    }
  }

  ## Remove Parallel Cluster ###############
  if (Parallel) {
    parallel::stopCluster(cl)
  }

  ## Reduce list, if algorithm didnt run all iterations #################
  mut_rate <- mut_rate[lapply(mut_rate, length) != 0]
  beorwor <- beorwor[lapply(beorwor, length) != 0]
  selcross <- selcross[lapply(selcross, length) != 0]
  clouddata <- clouddata[lapply(clouddata, length) != 0]
  allparkcoeff <- allparkcoeff[lapply(allparkcoeff, length) != 0]
  bestPaEn <- bestPaEn[lapply(bestPaEn, length) != 0]
  bestPaEf <- bestPaEf[lapply(bestPaEf, length) != 0]
  fuzzycontr <- fuzzycontr[lapply(fuzzycontr, length) != 0]
  fitnessValues <- fitnessValues[lapply(fitnessValues, length) != 0]
  nindiv <- nindiv[lapply(nindiv, length) != 0]
  allCoords <- allCoords[lapply(allCoords, length) != 0]

  ## Bind the results together and Output them. #################
  alldata <- cbind(
    allparkcoeff, bestPaEn, bestPaEf,
    fuzzycontr, fitnessValues, nindiv,
    clouddata, selcross, beorwor,
    inputData, inputWind, mut_rate, allCoords
  )

  return(alldata)
}

#' @title Transform to Simple Feature Polygons
#' @name isSpatial
#' @description Helper Function, which transforms SpatialPolygons or coordinates
#'   in matrix/data.frame - form to a Simple Feature Polygon
#'
#' @export
#'
#' @param shape An area as SpatialPolygon, SimpleFeature Polygon or coordinates
#'   as matrix/data.frame
#' @param proj Which Projection should be assigned to matrix / data.frame
#'   coordinates
#'
#' @family Helper Functions
#' @return A Simple Feature Polygon
#'
#' @details If the columns are named, it will look for common abbreviation to
#'   match x/y or long/lat columns. If the columns are not named, the first 2
#'   numeric columns are taken.
#'
#' @examples \donttest{
#' library(sf)
#' df <- rbind(
#'   c(4498482, 2668272), c(4498482, 2669343),
#'   c(4499991, 2669343), c(4499991, 2668272)
#' )
#' isSpatial(df)
#'
#' Polygon1 <- sf::st_as_sf(sf::st_sfc(
#'   sf::st_polygon(list(cbind(
#'     c(4498482, 4498482, 4499991, 4499991, 4498482),
#'     c(2668272, 2669343, 2669343, 2668272, 2668272)
#'   ))),
#'   crs = 3035
#' ))
#' isSpatial(st_coordinates(Polygon1), 3035)
#' }
isSpatial <- function(shape, proj) {
  if (inherits(shape, "Spatial")) {
    shape <- st_as_sf(shape)
    ## This is needed for grid_area. Attribute names must have same length
    shape$names <- "layer"
  } else if (class(shape)[1] == "data.frame" ||
             class(shape)[1] == "matrix") {
    ## If coordinate names are found, take those columns,
    ## otherwise take the first 2
    if (length(colnames(shape))) {
      accep_cols_x <- c("L*N", "X")
      accep_cols_y <- c("L*T", "Y", "BREITE")
      sum_col_match <- sum(sapply(
        c(accep_cols_x, accep_cols_y), grepl,
        toupper(colnames(shape))
      ))
      if (sum_col_match >= 2) {
        x_col_match <- which(sapply(
          lapply(accep_cols_x, grepl, toupper(colnames(shape))),
          any
        ))
        y_col_match <- which(sapply(
          lapply(accep_cols_y, grepl, toupper(colnames(shape))),
          any
        ))

        x_col_index <- which(grepl(
          accep_cols_x[x_col_match],
          toupper(colnames(shape))
        ))
        y_col_index <- which(grepl(
          accep_cols_y[y_col_match],
          toupper(colnames(shape))
        ))

        pltm <- shape[, c(x_col_index[1], y_col_index[1])]
      } else {
        col_numeric <- which(sapply(shape[1, ], is.numeric))
        pltm <- shape[, col_numeric]
      }
    } else {
      col_numeric <- which(sapply(shape[1, ], is.numeric))
      pltm <- shape[, col_numeric]
    }
    colnames(pltm) <- c("x", "y")
    pltm <- data.frame(pltm)
    shape <- st_cast(st_combine(
      sf::st_as_sf(pltm, coords = c("x", "y"))$geometry
    ), "POLYGON")

    if (!missing(proj)) st_crs(shape) <- 3035
  }
  return(shape)
}

#' @title Transform Winddata
#' @name windata_format
#' @description Helper Function, which transforms winddata to an acceptable
#'   format
#'
#' @export
#'
#' @param df The wind data with speeds, direction and optionally a probability
#'   column. If not assigned, it will be calculated
#'
#' @family Helper Functions
#' @return A list of windspeed and probabilities
#'
#' @examples \donttest{
#' wind_df <- data.frame(
#'   ws = c(12, 30, 45),
#'   wd = c(0, 90, 150),
#'   probab = 30:32
#' )
#' windata_format(wind_df)
#'
#' wind_df <- data.frame(
#'   speed = c(12, 30, 45),
#'   direction = c(90, 90, 150),
#'   probab = c(10, 20, 60)
#' )
#' windata_format(wind_df)
#'
#' wind_df <- data.frame(
#'   speed = c(12, 30, 45),
#'   direction = c(400, 90, 150)
#' )
#' windata_format(wind_df)
#' }
windata_format <- function(df) {
  wind_df <- data.frame(df)
  if (!all(colnames(wind_df) %in% c("ws", "wd"))) {
    # Assume that we've been given a wind_df frame.
    # Lets find the correct columns
    if (length(colnames(wind_df)) &&
      all(!colnames(wind_df) %in% c("X1", "X2", "X3"))) {
      accep_speed <- c("SPEED", "GESCH", "V", "WS")
      accep_direc <- c("DIR", "RICHT", "WD")
      accep_proba <- c("PRO", "WAHR")
      sum_col_match <- sum(sapply(
        c(accep_speed, accep_direc, accep_proba),
        grepl, toupper(colnames(wind_df))
      ))
      if (sum_col_match >= 2) {
        speed_match <- which(sapply(
          lapply(accep_speed, grepl, toupper(colnames(wind_df))),
          any
        ))
        direc_match <- which(sapply(
          lapply(accep_direc, grepl, toupper(colnames(wind_df))),
          any
        ))
        probab_match <- which(sapply(
          lapply(accep_proba, grepl, toupper(colnames(wind_df))),
          any
        ))
        speed_index <- which(grepl(
          accep_speed[speed_match],
          toupper(colnames(wind_df))
        ))
        direc_index <- which(grepl(
          accep_direc[direc_match],
          toupper(colnames(wind_df))
        ))
        if (length(probab_match) != 0) {
          probab_index <- which(grepl(
            accep_proba[probab_match],
            toupper(colnames(wind_df))
          ))
          wind_df[, c(speed_index[1], direc_index[1], probab_index[1])]
          colnames(wind_df) <- c("ws", "wd", "probab")
        } else {
          wind_df[, c(speed_index[1], direc_index[1])]
          colnames(wind_df) <- c("ws", "wd")
        }
      } else {
        col_numeric <- which(sapply(wind_df[1, ], is.numeric))
        wind_df <- wind_df[, col_numeric]
        colnames(wind_df) <- c("ws", "wd")
      }
    } else {
      col_numeric <- which(sapply(wind_df[1, ], is.numeric))
      wind_df <- wind_df[, col_numeric]
      if (length(colnames(wind_df)) == 2) {
        colnames(wind_df) <- c("ws", "wd")
      } else {
        colnames(wind_df) <- c("ws", "wd", "probab")
      }
    }
  }
  wind_df$wd <- round(wind_df$wd, 0)
  wind_df$wd <- round(wind_df$wd / 100, 1) * 100
  ## If no probabilites are given, assign uniform distributed ones.
  if (anyNA(colnames(wind_df))) {
    which(is.na(colnames(wind_df)))
    colnames(wind_df)[3] <- "probab"
  }
  if (any(names(wind_df) == "probab") == FALSE) {
    wind_df$probab <- 100 / nrow(wind_df)
  }
  ## Checks if all the sum of possibility is  100
  if (sum(wind_df$probab) != 100) {
    wind_df$probab <- wind_df$probab * (100 / sum(wind_df$probab))
  }
  ## Checks if duplicated wind directions are at hand
  if (any(duplicated(wind_df$wd))) {
    for (i in 1:length(wind_df[duplicated(wind_df$wd) == FALSE, 1])) {
      ## Get duplicated direction rows
      temp <- wind_df[wind_df$wd == wind_df[duplicated(
        wind_df$wd
      ) == FALSE, ][i, "wd"], ]
      ## Sum up speed and probability
      temp$ws <- sum(temp$ws * (temp$probab / sum(temp$probab)))
      temp$probab <- sum(temp$probab * (temp$probab / sum(temp$probab)))
      ## Assign new/uniwue windspeed and probablity per direction
      wind_df[wind_df$wd == wind_df[duplicated(
        wind_df$wd
      ) == FALSE, ][i, "wd"], ]$ws <- round(temp$ws, 2)[1]
      wind_df[wind_df$wd == wind_df[duplicated(
        wind_df$wd
      ) == FALSE, ][i, "wd"], ]$probab <- round(temp$probab, 2)[1]
    }
  }
  ## Delete duplicated direction rows
  wind_df <- wind_df[!duplicated(wind_df$wd) == TRUE, ]
  ## Order by direction
  wind_df <- wind_df[with(wind_df, order(wd)), ]
  ## Sum up probabilites to 100% again
  if (sum(wind_df$probab) != 100) {
    wind_df$probab <- wind_df$probab * (100 / sum(wind_df$probab))
  }
  probabDir <- wind_df$probab
  if (any(wind_df$wd > 360)) {
    wind_df[wind_df$wd > 360, "wd"] <- wind_df[wind_df$wd > 360, "wd"] - 360
  }
  wind_df <- as.matrix(wind_df)
  winddata <- list(wind_df, probabDir)
  return(winddata)
}
