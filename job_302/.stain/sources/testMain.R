
main <- function() {
    data <- data.table::fread(paste("./data", my_file_name, sep = "/"))
    write.csv(data, csv_filename(my_file_name) , row.names = FALSE)
}
