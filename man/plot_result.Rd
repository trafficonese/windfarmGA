% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plots.R
\name{plot_result}
\alias{plot_result}
\title{Plot the best results}
\usage{
plot_result(
  result,
  Polygon1,
  best = 3,
  plotEn = 1,
  topographie = FALSE,
  Grid = TRUE,
  sourceCCLRoughness = NULL,
  sourceCCL = NULL,
  weibullsrc
)
}
\arguments{
\item{result}{The output of \code{\link{genetic_algorithm}}}

\item{Polygon1}{The considered area as SpatialPolygon, SimpleFeature Polygon
or coordinates as matrix/data.frame}

\item{best}{A numeric value indicating how many of the best individuals
should be plotted}

\item{plotEn}{A numeric value that indicates if the best energy or efficiency
output should be plotted. \code{1} plots the best energy solutions
and \code{2} plots the best efficiency solutions}

\item{topographie}{A logical value, indicating whether terrain effects should
be considered and plotted or not}

\item{Grid}{If \code{TRUE} (default) the used grid will be added to the plot.
You can also pass another Simple Feature object}

\item{sourceCCLRoughness}{The source to the adapted Corine Land Cover legend
as .csv file. Only required when terrain effect model is activated. As
default a .csv file within this package (\file{~/extdata}) is taken that
was already adapted manually.}

\item{sourceCCL}{The path to the Corine Land Cover raster (.tif). Only
required when the terrain effect model is activated.}

\item{weibullsrc}{A list of Weibull parameter rasters, where the first list
item must be the shape parameter raster `k` and the second item must be the
scale parameter raster `a` of the Weibull distribution. If no list is
given, then rasters included in the package are used instead, which
currently only cover Austria. This variable is only used
if \code{weibull = TRUE}.}
}
\value{
Returns a data.frame of the best (energy/efficiency) individual
  during all iterations
}
\description{
Plot the best solutions of the genetic algorithm.
  Depending on \code{plotEn}, either the best energy or efficiency solutions
  can be plotted. \code{best} indicates the amount of best solutions to plot.
}
\examples{
\dontrun{
## Add some data examples from the package
library(sf)
Polygon1 <- sf::st_as_sf(sf::st_sfc(
  sf::st_polygon(list(cbind(
    c(4498482, 4498482, 4499991, 4499991, 4498482),
    c(2668272, 2669343, 2669343, 2668272, 2668272)
  ))),
  crs = 3035
))

## Plot the results of a hexagonal grid optimization
plot_result(resulthex, Polygon1, best = 1, plotEn = 1, topographie = FALSE)

## Plot the results of a rectangular grid optimization
plot_result(resultrect, Polygon1, best = 1, plotEn = 1, topographie = FALSE)
}
}
\seealso{
Other Plotting Functions: 
\code{\link{plot_cloud}()},
\code{\link{plot_development}()},
\code{\link{plot_evolution}()},
\code{\link{plot_fitness_evolution}()},
\code{\link{plot_parkfitness}()},
\code{\link{plot_windfarmGA}()},
\code{\link{plot_windrose}()},
\code{\link{random_search_single}()}
}
\concept{Plotting Functions}
