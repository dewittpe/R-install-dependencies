# R Install Dependencies

Consider the following situation.  You need to install a set of R packages on a
machine that cannot make external http(s) requests.   As such, you must download
source files for the pacakge, along with all of the dependencies, and
dependencies of dependencies, etc, and transfer these source files to the
machine (likely via FTP) that cannot make the external http(s) requests.
Further, you need to install the packages in the correct order so that the
install of a dependency does not fail do to a missing dependencies of the the
dependency.

The scrpt `build-dep-list.R` will generate the needed list of dependencies,
download the source files, from both [CRAN](https://cran.r-project.org) and
[BioConductor](https://www.bioconductor.org/), and then generate a `makefile`
to install the packages in an order so that R package dependencies should not
cause errors.

## Use

On a computer, with internet access run the following script

    Rscript --vanilla build-dep-list.R pkg1 [pkg2] [pkg3] [...] [pkgn]

The R script will download the source (.tar.gz) file for pkg1 and the
dependencies (packages listed under Depends, Imports, and LinksTo in the
DESCRIPTION file) along with the dependencies of the dependencies, and so on.
You may list multiple packages here and the n packages and dependencies will be
downloaded.

The source files will be placed in a `pkg-source-files` directory.

The R script will generate a `makefile`

After transfering the `makefile` and the `pkg-source-files` directory to
the remote machine, the user need only to run [GNU make](https://www.gnu.org/software/make/)
the needed packages.

    make

## Example
Say you need to download three packages: 1. ggplot2, 2. qwraps2, 3. data.table.

    Rscript --vanilla build-dep-list.R ggplot2 qwraps2 data.table

or

    echo -e "ggplot2\nqwraps2\ndata.table" > needed-pkgs.txt
    Rscript --vanilla build-dep-list.R needed-pkgs.txt


