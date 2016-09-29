csv_filename <- function(file) {
    s <- strsplit(my_file_name, "[.]")
    return(paste0(s[[1]][1], ".csv"))
}
