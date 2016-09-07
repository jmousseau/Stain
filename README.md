# Stain

![](https://img.shields.io/badge/release-v0.5.0-red.svg?style=flat)
![](https://img.shields.io/travis/jmousseau/Stain/dev.svg)

`Stain` (**S**lurm Con**tain**er) is an R package that generates "containers"
for slurm jobs. **NOTE**: still in beta!


### Installation

```R
devtools::install_github("jmousseau/Stain")
```

---

### Getting Started

For the following example, we will pretend that we use the following files
in our slurm job:

```R
# main.R

main <- function() {
    # The reason why the "./.data" directory was used will be clear
    # later on.
    input_file <- paste("./.data", input_file_name, sep = "/")
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
will be created. For more on what is inside a slurm container, see the
"Slurm Container Details" section.

`sbatch_opts` and `sbatch_mail_type_opts` are lists of commonly used options.
`sbatch_opts` is a list of functions that take a string parameter representing
the value and returns that value as a formatted key-value pair.
`sbatch_mail_type_opts` is a list of all sbatch mail types. One may choose to pass a custom option using the form `"--<key>=<value>"`.

Below is a `Stain` object for our example files.

```R
# Create a new Stain in the current directory.
stain <- Stain$new(options = c(
    sbatch_opts$memory("16g"),
    sbatch_opts$email_user("example@domain.com"),
    sbatch_mail_type_opts$all
))

# Add any R source files used by your slurm job.
stain$add_sources(c("main.R", "default_write.R"))

# Add any data files.
stain$add_data("data.txt")
```

The `add_data` function will place all data files in a `./.data` directory which
only exists when your slurm job is running. **NOTE: Files added will not retain
their parent directory structure.**

One of the source files in your slurm container must contain a `main()` function.
Once an R source file containing a `main()` function has been added, one should
see a message similar to the one below:

```
Found 2 vars to specify:
    - input_file_name
    - output_file_name

Set these vars in the `globals` list of your `Stain` object.
```

The globals are variables that not defined anywhere in the source files but
used in `main()`. But why would any variable not have a value? In the example,
`input_file_name` and `output_file_name` are undefined. This means they may be
edited using a `Stain` object, rather than explicitly changing a hard coded
value in a source file. We will see this later in the example.

Globals are assigned like so:
```R
stain$globals$input_file_name <- "data.txt"
stain$globals$output_file_name <- "converted_data.csv"

# Remember to save the globals or else they will not properly update!
stain$save_globals()
```

To submit the slurm job, navigate to the slurm container and run:
```shell
sbatch submit.slurm
```

Now image a case where one would like to run these same scripts on a different
file. Remember how `input_file_name` and `output_file_name` where left
accessible by our slurm container? The code below will configure the container
for a new input file.

```R
# "job_abc/" would be the directory of your slurm container.
stain <- Stain$new("job_abc/")

# Add the new data file.
stain$add_data("data_2.txt")

# Change the globals
stain$globals$input_file_name <- "data_2.txt"
stain$globals$output_file_name <- "converted_data_2.csv"
stain$save_globals()
```
```shell
sbatch submit.slurm
```

**NOTE:** Make sure your container is currently in the environment where you
submit slurm jobs. This may require you to `scp` the job directory to the
correct location.

---

### Slurm Container Details

A slurm container is simply a directory structure to organize components required
for a slurm job. The components are stored in the `.stain/` directory. Here
is a breakdown of the `.stain/` subdirectories.

- `data/` Any data files specified in a `Stain` object will be copied here.
Copied data files will not retain there parent directory structure. Data is
available in the `./data` directory when your slurm job is running.

- `objects/` Any `globals` set in your `Stain` object will be written here as
`<name>.RData` where `<name>` is the name of the global. These object files will
be loaded prior to executing any R code.

- `sources/` Any R source files specified in your `Stain` object will be copied
here. One of the source files must contain a `main()` function. Also contains
`.default_stain_main.R` which contains code to run your R code.

Another core component of a slurm container is the `submit.slurm` bash script
which is configured for your options and executes your R code and exists at the
top level of a slurm container.
