% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/misc.R
\name{\%>\%}
\alias{\%>\%}
\title{Pipe data}
\usage{
lhs \%>\% rhs
}
\arguments{
\item{lhs}{a data object}

\item{rhs}{a function to apply to the data}
}
\description{
Pipe data from one datadr operation to another
}
\examples{
# Suppose we wish to do the following:
bySpecies <- divide(iris, by = "Species")
bySpeciesTransformed <- addTransform(bySpecies, function(x) mean(x$Sepal.Length))
recombine(bySpeciesTransformed, combine = combRbind)

# We can do it more consely using the pipe: '\%>\%'
divide(iris, by = "Species") \%>\%
  addTransform(function(x) mean(x$Sepal.Length)) \%>\%
    recombine(combRbind)
}

