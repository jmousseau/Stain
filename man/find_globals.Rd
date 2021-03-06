% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/globals.r
\name{find_globals}
\alias{find_globals}
\title{Find unassigned global variables.}
\usage{
find_globals(source_files, object_files = c())
}
\arguments{
\item{source_files}{R files containing globals to exclude such as
function declarations.}

\item{object_files}{Rdata files that contain globals to exclude.}
}
\value{
A list of globals without assignments.
}
\description{
This funciton sources files and loads objects into an environment
and then runs \code{codetools::findGlobals} on the environment.
}
\details{
NOTE: Globals are determined for the \code{main()} function only!
}

