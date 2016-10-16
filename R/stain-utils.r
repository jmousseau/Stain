#' Generate a Random Alphanumeric.
#'
#' @param len The length of the alphanumeric to produce.
#'
#' @return An alphanumeric string.
rand_alphanumeric = function(len = 3) {
    population <- c(rep(0:9, each = 5), LETTERS, letters)
    samp <- sample(population, len, replace = TRUE)
    return(paste(samp, collapse = ''))
}
