################################################################################
# file: build-dep-list.R
#
# This script is used to get the source (.tar.gz) files for R packages and
# recursive dependencies so that the source files can be transfered to, and
# installed on, machines without internet access.
#
# The result of this script will place source files (.tar.gz) for the packages,
# and the package dependencies, and dependencies of dependencies, and so on, in
# the pkg-source-files directory.
#
# Update 3 March 2022: the original script would delete the existing
# pkg-source-files directory and download all the wanted packages and
# dependencies.  The current version will look at the versions of the packages
# in the pkg-source-files director and download the source .tag.gz if the
# package does not exist at all, or if there is a newer version of the package
# available.  Older version will not be deleted automatically.  The end user is
# responsible for removal of the old packages.  Simply deleting the
# pkg-source-files directory prior to running this script will result in a fresh
# download of all the needed packages.
#
# A Makefile will be generated to install the packages.
#
# Moving the pkg-source-files directory, and the Makefile via FTP
# to the target machine should be sufficient for installing on that machine,
# assuming that R and GNU make have been successfully installed on that machine.
#
# This script is expected to be evaluated from the command line via:
#
#   Rscript --vanilla build-dep-list.R [pkg1] [pkg2] [...] [pkgn]
#
# Where pkg1 is the name of the first known package to download, pkg2 the second
# known package to download, ..., and pkgn the nth package to download.  The
# script will download all the dependencies for pkg1, ..., pkgn, and the
# dependencies of the dependencies, and so on.
#
# Alternatively,
#
#  Rscript --vanilla build-dep-list.R needed-pkgs.txt
#
# where needed-pkgs.txt is a file listing the pkg1, pkg2, ..., pkgn.
#
# **EXAMPLE** you need the following three packages:
#
# 1. ggplot2
# 2. qwraps2
# 3. data.table
#
# One way to do this:
#
#     Rscript --vanilla build-dep-list.R ggplot2 qwraps2 data.table
#
# or
#
#    echo -e "ggplot2\nqwraps2\ndata.table" > needed-pkgs.txt
#    Rscript --vanilla build-dep-list.R needed-pkgs.txt
#
# _Pausing between file downloads_
#
# If you want/need to have a notable pause between downloads of each package
# then you can add an optional command line argument `--pause=N` and a minimum
# of N seconds will lapse between downloads.
#
#     Rscript --vanilla build-dep-list.R --pause=3 qwraps2 cpr data.table
#
################################################################################

# For testing and development, use a subset of packages.  If this script is
# called as noted above then the command line args will be used.
if (interactive()) {
  OUR_PACKAGES <- c("cpr", "qwraps2", "REDCapExporter", "ensr")
  DOWNLOAD_PAUSE <- 1 # in seconds
} else {
  cargs <- commandArgs(trailingOnly = TRUE)

  DOWNLOAD_PAUSE <- cargs[which(grepl("--pause=", cargs))]
  if (length(DOWNLOAD_PAUSE)) {
    DOWNLOAD_PAUSE <- as.numeric(strsplit(DOWNLOAD_PAUSE, "=")[[1]][2])
    OUR_PACKAGES <- cargs[-which(grepl("--pause=", cargs))]
  } else {
    DOWNLOAD_PAUSE <- 0
    OUR_PACKAGES <- cargs
  }

  if (file.exists(OUR_PACKAGES[1])) {
    OUR_PACKAGES <- scan(OUR_PACKAGES[1], what = character(), sep = '\n')
    print(OUR_PACKAGES)
  }
}

# Repositories to look for packages
# You can change the mirrors. get a list of mirrors via
#
#    utils::getCRANmirrors()
CRAN <- "https://cran.rstudio.com/"
BIOC <- "https://bioconductor.org/packages/release/bioc/"

# Define the base packages.  These are packages which come with R upon install
# of R.  These packages include: "base", "compiler", "datasets", "graphics",
# "grDevices", "grid", "methods", "parallel", "splines", "stats", "stats4",
# "tcltk", "tools", and "utils".
#
# NOTE: there are Priority = "recommended" packages as well.  If these packages
# are missing from the system install, this script might fail.  Downloading and
# installing the 'recommended' packages can be difficult between R versions.
base_pkgs <-
  unname(utils::installed.packages()[utils::installed.packages()[, "Priority"] %in% c("base", "recommended"), "Package"])

# get a list of the available packages from CRAN and BioConductor
available_pkgs <- available.packages(repos = c(CRAN, BIOC))

# use the tools::package_dependencies function to generate a list of the
# packages dependencies, and dependencies of dependencies, and so on, ...
pkgs_to_download <- OUR_PACKAGES
i <- 1L
while(i <= length(pkgs_to_download)) {
  deps <-
    unlist(tools::package_dependencies(packages = pkgs_to_download[i],
                                       which = c("Depends", "Imports", "LinkingTo"),
                                       db = available_pkgs,
                                       recursive = FALSE),
           use.names = FALSE)
  deps <- deps[!(deps %in% base_pkgs)]
  pkgs_to_download <- append(pkgs_to_download, deps, i)
  i <- i + 1L
}
pkgs_to_download <- unique(rev(pkgs_to_download))

# Download the needed packages into the pkg-source-files directory

# If you want to download into a clean directory use unlink to delete the files
# within the pkg-source-files directory.  Otherwise, the version numbers for the
# available_pkgs will be checked and only missing packages or packages with
# newer versions will be downloaded.
# unlink("pkg-source-files/*")
dir.create("pkg-source-files/", showWarnings = FALSE)

pkg_versions <-
  sapply(pkgs_to_download, function(p) {
           available_pkgs[, "Version"][which(p == rownames(available_pkgs))]
           })

tarballs <-
  paste0("./pkg-source-files/", pkgs_to_download, "_", pkg_versions, ".tar.gz")
tarballs <- setNames(tarballs, pkgs_to_download)

dwnld_pkgs <- NULL
print(tarballs)

for(tb in tarballs) {
  if (file.exists(tb)) {
    message(paste(tb, "exists and will not be downloaded again"))
    dwnld_pkgs <-
      rbind(dwnld_pkgs, c(names(tarballs)[tarballs == tb], tb))
  } else {
    message(paste(tb, "will be downloaded"))

    if (!("last_dwnld" %in% ls())) {
      last_dwnld <- Sys.time()
    }
    if (as.numeric(difftime(Sys.time(), last_dwnld, units = "secs")) < DOWNLOAD_PAUSE) {
      message("Pausing download for ", DOWNLOAD_PAUSE, " seconds")
      Sys.sleep(DOWNLOAD_PAUSE)
    }
    dwnld_pkgs <-
      rbind(dwnld_pkgs,
            download.packages(pkgs = names(tarballs)[tarballs == tb],
                              destdir = "./pkg-source-files",
                              repos = c(CRAN, BIOC),
                              type = "source")
      )
    last_dwnld <- Sys.time()
  }
}

# generate a Makefile to install the packages.  The Makefile will stop if there
# is an error in any of the installs.  Using a bash script will not stop if
# there is an error.

cat("all:", paste0("./pkg-source-files/.", OUR_PACKAGES, collapse = " "), "\n\n",
    file = "Makefile",
    append = FALSE)

for (i in 1:nrow(dwnld_pkgs)) {

  deps <-
    unlist(tools::package_dependencies(packages = dwnld_pkgs[i, 1],
                                       which = c("Depends", "Imports", "LinkingTo"),
                                       db = available_pkgs,
                                       recursive = FALSE),
           use.names = FALSE)
  deps <- deps[!(deps %in% base_pkgs)]

  if (length(deps)) {
    deps <- paste0("./pkg-source-files/.", deps, collapse = " ")
  }

  trgt <- paste0("./pkg-source-files/.", dwnld_pkgs[i, 1], ": ", dwnld_pkgs[i, 2], " ", deps)
  rcp  <- "\n\tR CMD INSTALL $<\n\t@touch $@\n\n"
  cat(trgt, rcp, file = "Makefile", append = TRUE)

}


################################################################################
#  end of file
################################################################################
