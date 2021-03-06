% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/recombine_combine.R
\name{combMean}
\alias{combMean}
\title{Mean Recombination}
\usage{
recombine(distributed_data_object, combine = combMean, ...)
}
\description{
Mean recombination -- Calculate the elementwise mean of a vector in each value
}
\details{
\code{combMean} is passed to the argument \code{combine} in \code{\link{recombine}}

This method assumes that the values of the key-value pairs each consist of a numeric vector (with the same length).
The mean is calculated elementwise across all the keys.
}
\examples{
# Create a distributed data frame using the iris data set
bySpecies <- divide(iris, by = "Species")

# Add a transformation that returns a vector of sums for each subset, one
# mean for each variable
bySpeciesTrans <- addTransform(bySpecies, function(x) apply(x, 2, sum))
bySpeciesTrans[[1]]

# Calculate the elementwise mean of the vector of sums produced by
# the transform, across the keys
out1 <- recombine(bySpeciesTrans, combine = combMean)
out1

# This manual, non-datadr approach illustrates the above computation

# This step mimics the transformation above
sums <- aggregate(. ~ Species, data = iris, sum)
sums

# And this step mimics the mean recombination
out2 <- apply(sums[,-1], 2, mean)
out2

# These are the same
identical(out1, out2)

}
\author{
Ryan Hafen
}
\seealso{
\code{\link{divide}}, \code{\link{recombine}}, \code{\link{combCollect}}, \code{\link{combDdo}}, \code{\link{combRbind}}, \code{\link{combMeanCoef}}
}

