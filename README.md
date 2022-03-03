# R Install Dependencies

[![test download and install](https://github.com/dewittpe/R-install-dependencies/actions/workflows/test_download_and_install.yml/badge.svg)](https://github.com/dewittpe/R-install-dependencies/actions/workflows/test_download_and_install.yml)

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
[BioConductor](https://www.bioconductor.org/), and then generate a `Makefile`
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

Alternatively, you could list the wanted packages in a file, say getthese.txt,
and call this function thusly:

    Rscript --vanilla build-dep-list.R getthese.txt

The source files for each package and all dependencies will be placed in a
`pkg-source-files` directory.

The R script will generate a `Makefile`

After transfering the `Makefile` and the `pkg-source-files` directory to
the remote machine, the user need only to run [GNU make](https://www.gnu.org/software/make/)
the needed packages.

    make

## Example
Say you need to download three packages: 1. ggplot2, 2. qwraps2, 3. data.table.

    Rscript --vanilla build-dep-list.R ggplot2 qwraps2 data.table

or

    echo -e "ggplot2\nqwraps2\ndata.table" > needed-pkgs.txt
    Rscript --vanilla build-dep-list.R needed-pkgs.txt


_Pausing between file downloads_

If you want/need to have a notable pause between downloads of each package
then you can add an optional command line argument `--pause=N` and a minimum
of N seconds will lapse between downloads.

    Rscript --vanilla build-dep-list.R --pause=3 qwraps2 cpr data.table

