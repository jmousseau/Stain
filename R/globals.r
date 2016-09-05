#' Find unassigned global variables.
#'
#' This funciton sources files and loads objects into an environment
#' and then runs \code{codetools::findGlobals} on the environment.
#'
#' @param source_files R files containing globals to exclude such as
#' function declarations.
#'
#' @param object_files Rdata files that contain globals to exclude.
#'
#' @return A list of globals without assignments.
find_globals = function(source_files, object_files = c()) {
    e <- new.env()

    for (file in source_files) {
        testthat::source_file(file, e)
    }

    for (object_file in object_files) {
        load(object_file, envir = e)
    }

    globals <- codetools::findGlobals(e$main)

    # Filter known `findGlobals` errors
    known_errors <- c("{", "}", "::")
    globals <- globals[!(globals %in% known_errors)]

    # Filter all functions in loaded packages
    for (package in (.packages())) {
        package <- paste0("package:", package)
        exports <- names(as.list(as.environment(package)))
        globals <- globals[!(globals %in% exports)]
    }

    # Filter functions and variables in source files
    globals <- globals[!(globals %in% names(as.list(e)))]

    nglobals <- length(globals)

    if (nglobals > 0) {
        if (nglobals == 1) {
            vars <- "var"
            t_vars <- "this var"
        } else {
            vars <- "vars"
            t_vars <- "these vars"
        }

        cat(paste("Found", nglobals, vars, "to specify:"))
        for (global in globals) {
            cat(paste("\n    -", global))
        }

        cat(paste("\n\nSet", t_vars, "in the `params` property of your `SlurmJob` instance."))
    }

    # Set the values of all gobals to NA
    global_list <- list()

    for (global in globals) {
        global_list[[global]] <- NA
    }

    return(global_list)
}
