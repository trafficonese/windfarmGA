## Create some Polygons ###################
Projection <- '+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000
+ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'
Proj84 <- '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'

cordslist <- list(structure(c(15.8862501316651, 15.8802827241768, 15.8814016130809, 
                 15.9090008727144, 15.9168330950428, 15.9265301322114, 15.9608427252693, 
                 15.9668101327576, 15.9970201331673, 16.0167871704724, 15.9884419849028, 
                 15.9709127254058, 15.9168330950428, 15.9145953172347, 15.8582779090636, 
                 15.8500727237671, 15.8608886498397, 15.8862501316651, 47.5568250061956, 
                 47.5522942591554, 47.5399585741679, 47.5392032338379, 47.5522942591554, 
                 47.5641237191238, 47.5583351681567, 47.5225829933608, 47.5160341797293, 
                 47.4918468635213, 47.4908388168251, 47.4739511582908, 47.4794969582227, 
                 47.4986506726316, 47.5006664467725, 47.5273681479331, 47.5505321961794, 
                 47.5568250061956), .Dim = c(18L, 2L)))
big_shape = SpatialPolygons(list(Polygons(list(Polygon(cordslist)), 1)), 
                            proj4string = CRS(Proj84))
big_shape <- spTransform(big_shape, CRS(Projection))
usethis::use_data(big_shape, overwrite = TRUE)

cordslist <- list(structure(c(15.0817690096444, 15.0830743800325, 15.0950091950091, 
                              15.0976199357853, 15.0862445652606, 15.0771069725441, 15.0817690096444, 
                              47.1150101971301, 47.1148832909329, 47.1051106048956, 47.0983829082324, 
                              47.0938126671506, 47.1059991050483, 47.1150101971301), .Dim = c(7L, 2L)), 
                  structure(c(15.092957898685, 15.0942632690731, 15.1032143803056, 
                              15.1073169729538, 15.0985523432053, 15.092771417201, 15.0875499356487, 
                              15.092957898685, 47.1233853370016, 47.1269380283696, 47.1231315642533, 
                              47.1153909139058, 47.1122181908802, 47.1142487554071, 47.1175482575189, 
                              47.1233853370016), .Dim = c(8L, 2L)), 
                  structure(c(15.1308136399391, 
                              15.1321190103272, 15.127829936195, 15.1183193805104, 15.1151491952822, 
                              15.1095547507619, 15.1088088248259, 15.111419565602, 15.1201841953505, 
                              15.1308136399391, 47.1309979565454, 47.1202130906391, 47.1161523392859, 
                              47.1148832909329, 47.1176751573605, 47.1250348303582, 47.1318860245243, 
                              47.1345501394874, 47.1344232798964, 47.1309979565454), .Dim = c(10L, 2L)))
cordslist <- lapply(cordslist, Polygon) 
hole_shape = SpatialPolygons(list(Polygons(cordslist, 1)),
                             proj4string = CRS(Proj84))
hole_shape <- spTransform(hole_shape, CRS(Projection))
usethis::use_data(hole_shape, overwrite = TRUE)



## Download Corine-Land-Cover Raster ######################
ccl_raster_url <-
  "https://www.eea.europa.eu/data-and-maps/data/clc-2006-raster-3/clc-2006-100m/g100_06.zip/at_download/file"
temp <- tempfile()
download.file(ccl_raster_url, temp, method = "libcurl", mode = "wb")
unzip(temp, "g100_06.tif")
unlink(temp)
ccl <- raster::raster("g100_06.tif")
usethis::use_data(ccl, overwrite = TRUE)

## Download Corine-Land-Cover Legend, save as .csv and add column for Rauhigkeit ###############
## TODO - add function to create a legend with other classification
legend_url <- "https://www.eea.europa.eu/data-and-maps/data/corine-land-cover-3/corine-land-cover-classes-and/clc_legend.csv/at_download/file"
data <- read.csv(legend_url)


## Weibull Raster ######################
## TODO - add data a github repo or somewhere accessible
a_weibull <- raster("a120_100m_Lambert.tif")
usethis::use_data(a_weibull, overwrite = TRUE)

k_weibull <- raster("k120_100m_Lambert.tif")
usethis::use_data(k_weibull, overwrite = TRUE)



## Result with Rect and 200 Iteration ##################
sp_polygon <- Polygon(rbind(c(4498482, 2668272), c(4498482, 2669343),
                            c(4499991, 2669343), c(4499991, 2668272)))
sp_polygon <- Polygons(list(sp_polygon), 1)
sp_polygon <- SpatialPolygons(list(sp_polygon))
projection <- paste("+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000",
                    "+ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs")
proj4string(sp_polygon) <- CRS(projection)
usethis::use_data(sp_polygon, overwrite = TRUE)

winddat <- data.frame(ws = 12, wd = 0)
# plotWindrose(winddat, "ws", "wd")
resultrect <- genAlgo(Polygon1 = sp_polygon,
                      n = 12, iteration = 200,
                      vdirspe = winddat,
                      Rotor = 30,
                      RotorHeight = 100)
usethis::use_data(resultrect, overwrite = TRUE)