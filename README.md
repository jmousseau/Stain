# Stain

![](https://img.shields.io/badge/release-v0.8.1-red.svg?style=flat)
![](https://img.shields.io/travis/jmousseau/Stain/master.svg)

Stain (**S**lurm Con**tain**er) is an R package that generates "containers"
for slurm jobs. **NOTE**: still in beta!


### Installation

```R
devtools::install_github("jmousseau/Stain")
```

### SSH Setup

If slurm jobs are run on a remote host, setup a public/private ssh key to
allow remote slurm job submissions. To automatically generate the bash code
required to do so, see `?stain_ssh_setup`. The documentation contains directions
to set up ssh keys for the remote host.

---

### Getting Started

As an example, pretend the following files are used in a slurm job to convert a
tab delimited file to a CSV file.

```R
# main.R

main <- function() {
    # The reason why the "./data" directory was used will be clear later.
    input_file <- paste("./data", input_file_name, sep = "/")
    data <- data.table::fread(input_file)
    default_write(data, output_file_name)
}
```

```R
# default_write.R

default_write <- function(data, file) {
    write.csv(data, file, row.names = FALSE)
}
```

```R
# data.txt - A space delimited data file.
```

A `Stain` object is used to manage a slurm container. Its initializer takes a
directory and a list of options. If the directory is an existing slurm
container, the container will be loaded. Otherwise, a new slurm container
will be created. For more on what is inside a slurm container, see
[Slurm Container Details](#slurm-container-details).

`sbatch_opts` is a list of functions that take a string parameter representing
the value and returns that value as a formatted key-value pair.
`sbatch_mail_type_opts` is a list of all sbatch mail types. One may choose to
pass a custom option using the form `"--<key>=<value>"`.

```R
# Create a new slurm container in the current working directory.
stain <- Stain$new(name = "stain-example", options = c(
    sbatch_opts$memory("16g"),
    sbatch_opts$mail_user("example@domain.com"),
    sbatch_mail_type_opts$all
))

# Configure the remote host where the slurm job will be submitted.
stain$set_remote_host("<user>", "<host>")

# Add any R source files used by the slurm job.
stain$add_sources(c("main.R", "default_write.R"))

# Add any data files.
stain$add_data("data.txt")
```

The `add_data` function will place all data files in a `./data` directory which
only exists when a slurm job is running. **NOTE: Files added will not retain
their parent directory structure.**

One of the source files in a slurm container must contain a `main()` function.
Once an R source file containing a `main()` function has been added, one should
see a message similar to:

```
2 globals to specify:

    - input_file_name
    - output_file_name

Set these globals in the `globals` property of your Stain instance.
```

The globals are variables that not defined anywhere in the source files but
used in `main()`. But why would any variable not have a value? In the example,
`input_file_name` and `output_file_name` are undefined. This means they may be
edited using a `Stain` object, rather than explicitly hard coded in a source
file.

```R
# Assigning globals.
stain$globals$input_file_name <- "data.txt"
stain$globals$output_file_name <- "converted_data.csv"
```

```R
# Submit to <user>@<host>:<submit directory> where the <submit directory> is
# ~/stain by default.
stain$submit()

# Jobs can be canceled.
stain$cancel(job_ids = c("<job_id>"))
```

```R
# When a slurm job has finished, the output files may be fetched.
stain$fetch_output()

# View a history of job submissions.
stain$submission_history()
```


Now image a case where one would like to run these same scripts on a different
file. Remember how `input_file_name` and `output_file_name` where left
accessible by our slurm container? The code below will configure the container
for a new input file.

```R
# "stain-example" is the directory specified previously by the "name" parameter
# which now represents a directory of an existing slurm container.
stain <- Stain$new("stain-example")

# Add the new data file.
stain$add_data("data_2.txt")

# Change the globals.
stain$globals$input_file_name <- "data_2.txt"
stain$globals$output_file_name <- "converted_data_2.csv"

stain$submit()
```

In most cases submitting all variants of a job then copying back all the output
is the most logical because the `fetch_output` will always copy all the output
even if some of the files have already been copied.

---

### Dependency Submissions

It is often desirable for one job to submit after a previous job has finished.
Stain makes this easy by allowing you to specify a dependency list using the
`PREVIOUS(<n>|ALL)` placeholder.

```R
# When submitting, use the placeholder to refer to n previous jobs. In this case
# the job will only start when the previous 2 jobs have finished with an exit
# code of 0.
stain$submit(dependency_list = "afterok:PREVIOUS(2)")

# To refer to all previous jobs for the Stain, user PREVIOUS(ALL).
stain$submit(dependency_list = "afterok:PREVIOUS(ALL)")

```

`"afterok"` is one of many possible labels in the dependency list. The
[sbatch docs](http://slurm.schedmd.com/sbatch.html) go into more detail about
the different `"--dependency"` flag options.

---

### Logs

Stain will automatically store the log output of each submission in a separate
log file. The log file is specified by a unique identifier assigned during
submission.

```R
# Fetch all log files from the remote host.
stain$fetch_logs()

# The submission history will contain a column named "log_id".
stain$submission_history()

# Read the contents of a specific log file.
contents <- stain$get_log("<log id>")

```


---

### Slurm Container Details <a name="slurm-container-details"></a>

A slurm container is simply a directory structure to organize components
required for a slurm job. The components are stored in the `.stain/` directory.
Here is a breakdown of the `.stain/` subdirectories.

- `data/` Any data files specified in a `Stain` object will be copied here.
Copied data files will not retain there parent directory structure. Data is
available in the `./data` directory when the slurm job is running.

- `objects/` Any `globals` set in a `Stain` object will be written here as
`<name>.RData` where `<name>` is the name of the global. These object files will
be loaded prior to executing any R code.

- `sources/` Any R source files specified in a `Stain` object will be copied
here. One of the source files must contain a `main()` function. Also contains
`.default_stain_main.R` which executes the R code.

- `logs/` A log file with a unique identifier and path will be stored here for
each submission. Log ids are list in the `Stain` object `submission_history()`
method.

- `meta.json` A JSON file that stores metadata about the `Stain`. Information
includes things like previously used sbatch options, for when someone loads an
existing `Stain` and expects the options when submitting to be the same as those
specified during initialization, and submission history.

The files in `sources/` and `data/` may be listed using the `list_files()`
`Stain` method.

Another core component of a slurm container is the `submit.slurm` bash script
which is configured for the specified sbatch options and exists at the top level
of a slurm container.
