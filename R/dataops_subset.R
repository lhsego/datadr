#' Subsetting Distributed Data Frames
#' 
#' Return a subset of a "ddf" object to memory
#' 
#' @param data object to be subsetted -- an object of class "ddf" or "ddo" - in the latter case, need to specify \code{preTransFn} to coerce each subset into a data frame
#' @param subset logical expression indicating elements or rows to keep: missing values are taken as false
#' @param select expression, indicating columns to select from a data frame
#' @param drop passed on to [ indexing operator
#' @param preTransFn a transformation function (if desired) to applied to each subset prior to division
#' @param params a named list of parameters external to the input data that are needed in the distributed computing (most should be taken care of automatically such that this is rarely necessary to specify)
#' @param control parameters specifying how the backend should handle things (most-likely parameters to \code{rhwatch} in RHIPE) - see \code{\link{rhipeControl}} and \code{\link{localDiskControl}}
#' @param verbose logical - print messages about what is being done
#' 
#' @return data frame
#' 
#' @author Ryan Hafen
#' @export
drSubset <- function(data,
   subset = NULL,
   select = NULL,
   drop = FALSE,
   preTransFn = NULL,
   maxRows = 500000,
   params = NULL,
   control = NULL,
   verbose = TRUE
) {
   # data <- divide(iris, by = "Species")
   # subset <- expression(Sepal.Length > 5)
   # select <- NULL
   # drop <- FALSE
   # preTransFn <- flatten
   # maxRows <- 500000
   # params <- NULL; control <- NULL; verbose <- TRUE

   if(!inherits(data, "ddf")) {
      if(verbose)
         message("* Input data is not 'ddf' - attempting to cast it as such")
      data <- ddf(data)
   }
   
   if(is.null(preTransFn))
      preTransFn <- identity
   
   # get an example of what a subset will look like
   ex <- kvExample(data, transform = TRUE)
   ex <- kvApply(preTransFn, ex)
   
   if(verbose)
      message("* Testing 'subset' on a subset")
   
   if(is.null(select))
      select <- TRUE
   
   if(missing(subset)) {
      subset <- NULL      
   } else {
      subset <- substitute(subset)
   }
   
   r <- if(is.null(subset)) {
	   rep_len(TRUE, nrow(ex))      
   } else {
	   r <- eval(subset, ex, parent.frame())
         if(!is.logical(r)) stop("'subset' must be logical")
	   r & !is.na(r)
   }
   test <- ex[r, select, drop = drop]
   
   parList <- list(
      transFn = getAttribute(data, "transFn"),
      preTransFn = preTransFn,
      maxRows = maxRows,
      subset = subset,
      select = select,
      drop = drop
   )
   
   globalVars <- unique(drFindGlobals(preTransFn))
   globalVarList <- getGlobalVarList(globalVars, parent.frame())
   if(length(globalVarList) > 0)
      parList <- c(parList, globalVarList)
   
   if(! "package:datadr" %in% search()) {
      if(verbose)
         message("* ---- running dev version - sending datadr functions to mr job")
      parList <- c(parList, list(
      ))
      
      setup <- expression({
         suppressWarnings(suppressMessages(library(data.table)))
      })
   } else {
      setup <- expression({
         suppressWarnings(suppressMessages(library(datadr)))
      })
   }
   
   map <- expression({
      dfList <- lapply(seq_along(map.keys), function(i) {
         kvApply(preTransFn,
            kvApply(transFn, list(map.keys[[i]], map.values[[i]]),   
               returnKV = TRUE))
      })
      df <- data.frame(rbindlist(dfList))
      
      r <- if(is.null(subset)) {
   	   rep_len(TRUE, nrow(df))      
      } else {
   	   r <- eval(subset, df, parent.frame())
            if(!is.logical(r)) stop("'subset' must be logical")
   	   r & !is.na(r)
      }
      res <- df[r, select, drop = drop]
      
      counter("datadr", "totalFilteredRows", nrow(res))
      collect("1", res)
   })
   
   reduce <- expression(
      pre = {
         df <- list()
         nRows <- 0
      },
      reduce = {
         nRows <- nRows + sapply(reduce.values, nrow)
         if(nRows < maxRows)
            df[[length(df) + 1]] <- reduce.values
      },
      post = {
         df <- data.frame(rbindlist(unlist(df, recursive = FALSE)))
         df <- df[1:min(nrow(df), maxRows),]
         collect(reduce.key, df)
      }
   )
   
   res <- mrExec(data,
      setup     = setup,
      map       = map, 
      reduce    = reduce, 
      params    = c(params, parList),
      control   = control
   )
   
   # TODO: checking on whether counter is larger than
   # number of rows of result

   res[[1]][[2]]
}

