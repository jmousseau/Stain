# Stain

![](https://img.shields.io/badge/release-v0.3.0-red.svg?style=flat)

`Stain` (**S**lurm Con**tain**er) is an R package that generates "containers" 
for slurm jobs. **NOTE**: still in beta!


### Installation

```R
devtools::install_github("jmousseau/Stain")
```

---

### Getting Started

For the following example, we will pretend that we have the following files
for our slurm job:

**main.R**
```R
main <- function() {
    input_file <- paste("./input", input_file_name, sep = "/")
    data <- data.table::fread(input_file)
    default_write(data, output_file_name)
}
```
**default_write.R**
```R
default_write <- function(data, file) {
    write.csv(data, file, row.names = FALSE)
}
```
**data.txt** - A space delimited data file.

Instantiate a `SlurmSettings` R6 object which manages certain `sbatch`
options. `sbatch_opts` is a list of supported option functions that take
a single parameter, representing the option's value. Any required `sbatch`
options that are not specified will take on default values.

Then use the `settings` object to create a `SlurmJob` object which is `Stain`'s
core component. Most importantly, the  `main_file` parameter must
contain a `main` function that takes no parameters.

```R
# Create a SlurmSettings object
settings <- SlurmSettings$new(c(
    sbatch_opts$nodes(2),
    sbatch_opts$email_user("example@domain.com"),
    sbatch_mail_type_opts$all
))

# Pass it into a SlurmJob object
sj <- SlurmJob$new(main_file = "./main.R",
                   settings = settings,
                   source_files = c("./default_write.R"))

# Add any data files
sj$input_files <- c("data.txt")
```

After instantiating `sj`, the following message will appear:
```
Found 2 global var(s) to assign:
    - input_file_name
    - output_file_name

Set the variables in the `params` list of your `SlurmJob` object.
```

The global var(s) represent variables that are never explicitly set in
your scripts. You may not run `create()` on your `SlurmJob` until all these
variables are set. For the example, one would run:
```R
sj$params$input_file_name <- "data.txt"
sj$params$output_file_name <- "converted_data.csv"

# Now that all `params` are set we can run:
sj$create()
```
This will create a `job_<alpha-numeric-id>/` directory which has multiple
subdirectories and scripts. Here is a brief explanation of each:

- `submit.sh` The shell script that submits your slurm job. See below for how to
run.

- `input` Any `input_files` specified in you `SlurmJob` will be copied here.
Directories will retain subdirectory structure, but files will not retain
parent directories.

- `output` Any files produced by your slurm job will be copied back into this
directory.

- `.static.slurm` The generated slurm file that will be summited using `sbatch`.

- `.objects` This hidden folder holds `.Rdata` files that each represent a
variable in `params`.


To run the slurm job, navigate to the job directory and run:
```shell
sh submit.sh
```
**NOTE:** Make sure your container is currently in the environment where you
submit slurm jobs. This may require you to `scp` the job directory to the
correct location.
