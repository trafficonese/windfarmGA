context("GA Functions")
library(testthat)
library(windfarmGA)
library(sp)
library(spatstat)
library(maptools)

test_that("Test Genetic Algorithm Function", {
  ## Data ##############
  Polygon1 <- Polygon(rbind(c(0, 0), c(0, 2000), c(2000, 2000), c(2000, 0)))
  Polygon1 <- Polygons(list(Polygon1),1);
  Polygon1 <- SpatialPolygons(list(Polygon1))
  Projection <- "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000
  +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
  proj4string(Polygon1) <- CRS(Projection)
  
  Polygon2 <- Polygon(rbind(c(0, 0), c(0, 3500), c(1500, 2000), c(2000, 0)))
  Polygon2 <- Polygons(list(Polygon2),1);
  Polygon2 <- SpatialPolygons(list(Polygon2))
  Projection <- "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000
  +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
  proj4string(Polygon2) <- CRS(Projection)
  
  ## BAROHOEHE ################################
  data <- matrix(seq(0,5000,500));
  # expect_s3_class(BaroHoehe(data), "data.frame")
  expect_false(any(is.na(BaroHoehe(data))))
  
  
  ## GRIDFILTER ################################
  Grid <- GridFilter(shape = Polygon1,resol = 200, prop = 1)
  expect_is(Grid[[1]], "matrix")
  expect_is(Grid[[2]], "SpatialPolygonsDataFrame")
  expect_false(anyNA(Grid[[1]]))
  
  Grid <- GridFilter(shape = Polygon1,resol = 200, prop = 0.1)
  expect_is(Grid[[1]], "matrix")
  expect_is(Grid[[2]], "SpatialPolygonsDataFrame")
  expect_false(anyNA(Grid[[1]]))
  
  Grid <- GridFilter(shape = Polygon1,resol = 500, prop = 0.1)
  expect_is(Grid[[1]], "matrix")
  expect_is(Grid[[2]], "SpatialPolygonsDataFrame")
  expect_false(anyNA(Grid[[1]]))
  
  Grid <- GridFilter(shape = Polygon1,resol = 500, prop = 0)
  expect_is(Grid[[1]], "matrix")
  expect_is(Grid[[2]], "SpatialPolygonsDataFrame")
  expect_false(anyNA(Grid[[1]]))
  
  Grid <- GridFilter(shape = Polygon2, resol = 300, prop = 100)
  expect_is(Grid[[1]], "matrix")
  expect_is(Grid[[2]], "SpatialPolygonsDataFrame")
  expect_false(anyNA(Grid[[1]]))
  # plot(Polygon2)
  # plot(Grid[[2]], add=T, col="red")
  # points(Grid[[1]][,2], Grid[[1]][,3], col="blue", pch=20)
  
  Grid1 <- GridFilter(shape = Polygon2, resol = 300, prop = 0.1)
  expect_is(Grid1[[1]], "matrix")
  expect_is(Grid1[[2]], "SpatialPolygonsDataFrame")
  expect_false(anyNA(Grid1[[1]]))
  expect_true(nrow(Grid1[[1]]) > nrow(Grid[[1]]))
  expect_false(identical(Grid[[2]]@bbox, Grid1[[2]]@bbox))
  # plot(Polygon2)
  # plot(Grid1[[2]], add=T, col="red")
  # points(Grid1[[1]][,2], Grid1[[1]][,3], col="blue", pch=20)
  
  Grid1 <- GridFilter(shape = Polygon2, resol = 300, prop = -100)
  expect_is(Grid1[[1]], "matrix")
  expect_is(Grid1[[2]], "SpatialPolygonsDataFrame")
  expect_false(anyNA(Grid1[[1]]))
  expect_true(nrow(Grid1[[1]]) > nrow(Grid[[1]]))
  expect_false(identical(Grid[[2]]@bbox, Grid1[[2]]@bbox))
  
  
  ## HEXATEX #################
  HexGrid <- HexaTex(Polygon1, 100, FALSE)
  expect_is(HexGrid[[1]], "matrix")
  expect_is(HexGrid[[2]], "SpatialPolygons")
  expect_false(anyNA(HexGrid[[1]]))
  
  HexGrid <- HexaTex(Polygon1, 200, FALSE)
  expect_is(HexGrid[[1]], "matrix")
  expect_is(HexGrid[[2]], "SpatialPolygons")
  expect_false(anyNA(HexGrid[[1]]))

  HexGrid <- HexaTex(Polygon1, 400.1, FALSE)
  expect_is(HexGrid[[1]], "matrix")
  expect_is(HexGrid[[2]], "SpatialPolygons")
  expect_false(anyNA(HexGrid[[1]]))
  
  HexGrid <- HexaTex(Polygon1, 1000000000, FALSE)
  expect_is(HexGrid[[1]], "matrix")
  expect_is(HexGrid[[2]], "SpatialPolygons")
  expect_false(anyNA(HexGrid[[1]]))
    
  ## TESS2SPDF #############
  HexaGrid <- spatstat::hextess(maptools::as.owin.SpatialPolygons(Polygon1),s = 100)
  expect_true(class(HexaGrid)[1] == "tess")
  
  ## Convert the Tesselation to SpatialPolygons
  Hex2spdf <- tess2SPdf(HexaGrid)
  expect_is(Hex2spdf, "SpatialPolygons")
  
  
  ## STARTGA ################################
  startsel <- StartGA(Grid[[1]], n = 10, nStart = 20);
  expect_is(startsel, "list")
  expect_true(all(sapply(startsel, class) == "matrix"))
  expect_true(all(sapply(startsel, nrow) == 10))
  expect_true(all(sapply(startsel, ncol) == 4))
  expect_output(str(startsel), "List of 20")
  expect_false(any(unlist(sapply(startsel, is.na))))
  
  startsel <- StartGA(Grid[[1]], n = 20, nStart = 25);
  expect_is(startsel, "list")
  expect_true(all(sapply(startsel, class) == "matrix"))
  expect_true(all(sapply(startsel, nrow) == 20))
  expect_true(all(sapply(startsel, ncol) == 4))
  expect_output(str(startsel), "List of 25")
  expect_false(any(unlist(sapply(startsel, is.na))))
  
  startsel <- StartGA(Grid[[1]], n = 20, nStart = 100);
  expect_is(startsel, "list")
  expect_true(all(sapply(startsel, class) == "matrix"))
  expect_true(all(sapply(startsel, nrow) == 20))
  expect_true(all(sapply(startsel, ncol) == 4))
  expect_output(str(startsel), "List of 100")
  expect_false(any(unlist(sapply(startsel, is.na))))
  
  startsel <- StartGA(Grid[[1]], n = 20, nStart = 300);
  expect_is(startsel, "list")
  expect_true(all(sapply(startsel, class) == "matrix"))
  expect_true(all(sapply(startsel, nrow) == 20))
  expect_true(all(sapply(startsel, ncol) == 4))
  expect_output(str(startsel), "List of 300")
  expect_false(any(unlist(sapply(startsel, is.na))))
  
  startsel <- StartGA(Grid[[1]], n = 10, nStart = 20)
  expect_is(startsel, "list")
  expect_true(all(sapply(startsel, class) == "matrix"))
  expect_true(all(sapply(startsel, nrow) == 10))
  expect_true(all(sapply(startsel, ncol) == 4))
  expect_output(str(startsel), "List of 20")
  expect_false(any(unlist(sapply(startsel, is.na))))
  
  ## FITNESS ################################
  wind <- data.frame(ws = 12, wd = 0)
  ## TODO - fitness now takes a list of windata. winddata and probability?
  wind <- list(wind, probab = 100)
  fit <- fitness(selection = startsel,referenceHeight = 100, RotorHeight=100,
                 SurfaceRoughness=0.3,Polygon = Polygon1, resol1 = 200,rot=20,
                 dirspeed = wind, srtm_crop="",topograp=FALSE,cclRaster="")
  expect_output(str(fit), "List of 20")
  expect_true(all(sapply(fit, nrow) == 10))
  expect_false(any(unlist(sapply(fit, is.na))))
  expect_false(any(unlist(do.call("rbind", fit)[,-c(1,2)] < 0)))
  
  fit1 <- fitness(selection = startsel, referenceHeight = 100, RotorHeight=100,
                  SurfaceRoughness=0.3,Polygon = Polygon1, resol1 = 200,rot=20,
                  dirspeed = wind, topograp=FALSE)
  expect_output(str(fit1), "List of 20")
  expect_true(all(sapply(fit1, nrow) == 10))
  expect_false(any(unlist(sapply(fit1, is.na))))
  expect_false(any(unlist(do.call("rbind", fit1)[,-c(1,2)] < 0)))
  
  
  ## SELECTION ################################
  allparks <- do.call("rbind",fit);
  selec6best <- selection1(fit, Grid[[1]], 2, TRUE, 6, "VAR");
  expect_output(str(selec6best), "List of 2")
  expect_false(any(unlist(sapply(selec6best, is.na))))
  expect_true(all(unlist(selec6best[[1]][,-1]) %in% c(0,1)))
  expect_true(all(selec6best[[2]][,-1] > 0))
  rm(selec6best)
  
  selec6best <- selection1(fit, Grid[[1]],2, TRUE, 6, "FIX");
  expect_output(str(selec6best), "List of 2")
  expect_false(any(unlist(sapply(selec6best, is.na))))
  expect_true(all(unlist(selec6best[[1]][,-1]) %in% c(0,1)))
  expect_true(all(selec6best[[2]][,-1] > 0))
  rm(selec6best)
  
  selec6best <- selection1(fit, Grid[[1]],4, FALSE, 6, "FIX");
  expect_output(str(selec6best), "List of 2")
  expect_false(any(unlist(sapply(selec6best, is.na))))
  expect_true(all(unlist(selec6best[[1]][,-1]) %in% c(0,1)))
  expect_true(all(selec6best[[2]][,-1] > 0))
  
  
  
  ## CROSSOVER #####################
  crossOut <- crossover1(selec6best, 2, uplimit = 300, crossPart = "RAN");
  expect_output(str(crossOut), "num")
  expect_false(any(is.na(crossOut)))
  expect_true(all(crossOut %in% c(0, 1)))
  rm(crossOut)
  
  crossOut <- crossover1(selec6best, 7, uplimit = 500, crossPart = "RAN");
  expect_output(str(crossOut), "num")
  expect_false(any(is.na(crossOut)))
  expect_true(all(crossOut %in% c(0, 1)))
  rm(crossOut)
  
  crossOut <- crossover1(selec6best, 3, uplimit = 300, crossPart = "EQU");
  expect_output(str(crossOut), "num")
  expect_false(any(is.na(crossOut)))
  expect_true(all(crossOut %in% c(0, 1)))
  
  
  ## MUTATION #####################
  ## Variable Mutation Rate is activated if more than 2 individuals represent the
  ## current best solution.
  mut <- mutation(a = crossOut, p = 0.3)
  expect_output(str(mut), "num")
  expect_false(any(is.na(mut)))
  expect_true(all(mut %in% c(0, 1)))

  mut <- mutation(a = crossOut, p = 0.1)
  expect_output(str(mut), "num")
  expect_false(any(is.na(mut)))
  expect_true(all(mut %in% c(0, 1)))

  mut <- mutation(a = crossOut, p = 1)
  expect_output(str(mut), "num")
  expect_false(any(is.na(mut)))
  expect_true(all(mut %in% c(0, 1)))

  mut <- mutation(a = crossOut, p = 100)
  expect_output(str(mut), "num")
  expect_false(any(is.na(mut)))
  expect_true(all(mut %in% c(0, 1)))

  mut <- mutation(a = crossOut, p = -1)
  expect_output(str(mut), "num")
  expect_false(any(is.na(mut)))
  expect_true(all(mut %in% c(0, 1)))
  
  mut <- mutation(a = crossOut, p = 0.0005)
  expect_output(str(mut), "num")
  expect_false(any(is.na(mut)))
  expect_true(all(mut %in% c(0, 1)))
  
  ## TRIMTON #####################
  ## After Crossover and Mutation, the amount of turbines in a windpark change
  ## and have to be corrected to the required amount of turbines.
  mut1 <- trimton(mut = mut, nturb = 1, allparks = allparks,
                  nGrids = nrow(Grid[[1]]), trimForce = FALSE)
  expect_output(str(mut1), "num")
  expect_false(any(is.na(mut1)))
  expect_true(all(mut1 %in% c(0, 1)))
  expect_true(all(colSums(mut1) == 1))
  expect_true(all(dim(mut) == dim(mut1)))
  rm(mut1)


  mut1 <- trimton(mut = mut, nturb = min(colSums(mut)), allparks = allparks,
                  nGrids = nrow(Grid[[1]]), trimForce = FALSE)
  expect_output(str(mut1), "num")
  expect_false(any(is.na(mut1)))
  expect_true(all(mut1 %in% c(0, 1)))
  expect_true(all(colSums(mut1) == min(colSums(mut))))
  expect_true(all(dim(mut) == dim(mut1)))
  rm(mut1)

  mut1 <- trimton(mut = mut, nturb = 10, allparks = allparks,
                  nGrids = nrow(Grid[[1]]), trimForce = FALSE)
  expect_output(str(mut1), "num")
  expect_false(any(is.na(mut1)))
  expect_true(all(mut1 %in% c(0, 1)))
  expect_true(all(colSums(mut1) == 10))  
  expect_true(all(dim(mut) == dim(mut1)))

  mut1 <- trimton(mut = mut, nturb = 5, allparks = allparks,
                  nGrids = nrow(Grid[[1]]), trimForce = TRUE)
  expect_output(str(mut1), "num")
  expect_false(any(is.na(mut1)))
  expect_true(all(mut1 %in% c(0, 1)))
  expect_true(all(colSums(mut1) == 5))
  expect_true(all(dim(mut) == dim(mut1)))
  rm(mut1)

  mut1 <- trimton(mut = mut, nturb = min(colSums(mut)), allparks = allparks,
                  nGrids = nrow(Grid[[1]]), trimForce = TRUE)
  expect_output(str(mut1), "num")
  expect_false(any(is.na(mut1)))
  expect_true(all(mut1 %in% c(0, 1)))
  expect_true(all(colSums(mut1) == min(colSums(mut))))
  expect_true(all(dim(mut) == dim(mut1)))
  rm(mut1)

  mut1 <- trimton(mut = mut, nturb = 20, allparks = allparks,
                  nGrids = nrow(Grid[[1]]), trimForce = TRUE)
  expect_output(str(mut1), "num")
  expect_false(any(is.na(mut1)))
  expect_true(all(mut1 %in% c(0, 1)))
  expect_true(all(colSums(mut1) == 20))  
  expect_true(all(dim(mut) == dim(mut1)))


  ## GETRECTV #####################
  getRectV <- getRects(mut1, Grid[[1]])
  expect_is(getRectV, "list")
  expect_true(all(sapply(getRectV, class) == "matrix"))
  expect_true(all(sapply(getRectV, ncol) == 3))
  expect_true(all(sapply(getRectV, nrow) == 20))
  expect_false(any(unlist(sapply(getRectV, is.na))))
  expect_true(all(sapply(getRectV, colnames) %in% c("ID","X","Y")))


  ## FITNESS AGAIN #####################
  fit <- fitness(selection = getRectV,referenceHeight = 100, RotorHeight=100,
                 SurfaceRoughness=0.3,Polygon = Polygon1, resol1 = 200,rot=20,
                 dirspeed = wind, srtm_crop="",topograp=FALSE,cclRaster="")
  expect_is(fit, "list")
  expect_true(all(sapply(fit, nrow) == 20))
  expect_true(length(fit) == length(getRectV))
  expect_false(any(unlist(sapply(fit, is.na))))
  expect_false(any(unlist(do.call("rbind", fit)[,-c(1,2)] < 0)))

})