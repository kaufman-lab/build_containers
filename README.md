# build_containers

This repo builds and stores singularity images to be used in lab workflows.

## Available Images

The set of image types that are available are displayed on the right under "packages".

These are the current image types:

-   `geospatial_plus`: Builds on the [rocker](https://github.com/rocker-org/rocker-versioned2) geospatial docker image.

    -   includes a few additional packages (including data.table, intervalaverage and terra)

    -   also has configured the R user library location to avoid clashing with the user library on the host machine.

-   `geospatial_plus_pdf`: geospatial_plus with the addition of a full tex installation. This should be able to knit PDFs without relying on tinytex needing to download tex installation files.

-   `geospatial_plus_ml`

    -   additionally includes torch for R, and tensorflow for python, and the reticulate package. The version of tensorflow is specifically intel's version since this is primarily intended to be run on an intel high performance compute (HPC) cluster. This is for a test project Michael was trying out using deep learning for air pollution prediction. Not currently in production anywhere.

-   `geospatial_plus_ml_horovod`

    -   additionally includes horovod (tensorflow only, set up for CPU) and openmpi. This doesn't use the intel version of tensorflow since it seems to cause poor performance when combined with horovod. This is also for a test project Michael was trying out using deep learning for air pollution prediction. Not currently in production anywhere.

- `nationalspatiotemporal`
   - This is for the national spatiotemporal model. It doesn't contain rstudio server, and it's not designed to be used interactively. It reproduces the R enviroment used for making predicitons/model fitting (R version, MKL, R packages) and shouldn't be used for anything other than that codebase (or projects that need to reproduce the environment of that codebase)

- `neogeo_portable`
   - This container is for calculating geocovariates using PostGIS. It does not contain R or Rstudio and is meant to be used in conjunction with the [neogeo_portable](https://github.com/kaufman-lab/neogeo_portable) repo. It has Postgres with PostGIS, Gnu Parallel, and Python installed. 

- `mkl_centos7`
   - This is used for nothing. It's just a demonstration of how to build R from source using MKL on CentOS 7. (this work formed the basis of getting nationalspatiotemporal working with MKL, although nationalspatiotemporal does not depend on mkl_centos7 in the way that geospatial_plus_ml depends on geospatial_plus. nationalspatiotemporal is an entirely different container image from mkl_centos7 and changes to mkl_centos7 won't affect nationalspatiotemporal).

- `ess`
   - Lightweight container with R, emacs, and ess. R is built with X11 for plotting at the terminal. Does not currently include geospatial packages, but could be extended to do so
   
## Using Images

If you'd like to test out an image interactively, try

    singularity shell oras://ghcr.io/kaufman-lab/geospatial_plus:4.1.0

Note that singularity will cache remote images, so using the oras URI (as above) may be more convenient than finding a storage location for the .sif file. However, there may be a tradeoff since using the URI pulls a hash so there is probably a slight delay to starting the image. If you want to instead download the image, you can use `singularity pull`.

Please disregard the instructions under github packages on how to pull these images using docker commands. These are not docker images and those commands will not work. Those instructions are auto-generated by github and I don't know how to turn them off.

## Image Requests

Submit an issue if you'd like additional packages or software built into an image.

Depending on the complexity, we may start a new image type (package) or add to an existing image.

## Image Stability

Within a version-tag (e.g. geospatial_plus:4.1.0), R packages built into the image are stable, even when the image (including the underlying rocker image) is rebuilt [because of how versioned rocker images install packages](https://github.com/rocker-org/rocker-versioned2/issues/201). Installing new R packages into the user library, while not recommended (it's better to request a package be added to the image), is also stable (the same version will always be installed) because install.packages by default downloads from a specific date's snapshot of the rstudio package manager. Python packages built into the image are stable because they are all manually specified as pip install commands with a version specified. However, unlike for R packages, installing python packages into the user directory is not reproducible because pip install will just download the newest version. If anyone is aware of a tool that makes pip install point to a specific day's snapshot of pypi (similar to how rstudio package manager/MRAN works) please let me know.

## Using images interactively

For images designed to host an IDE: While these images can be used non-interactively to run R and Python scripts (e.g. via `singularity exec oras://ghcr.io/kaufman-lab/geospatial_plus:4.1.0 Rscript scriptname.R`) without any additional options, if you want to use the image interactively for development (e.g. via `singularity shell` or `singularity instance`)  you should `--bind` a directory on the host machine to `/pseudohome`. This will allow installation of R and Python packages to an instance/shell-specific directory thus fully isolating the instance even during development. Without first binding `pseudohome`, user installation of packages will fail because pseudohome does not exist inside the image. This is arguably a good thing because it prevents accidental installation of packages or accidental loading of packages installed in the user library when images are being used for production.

## Definition files

This repository uses a pre-commit hook to auto-generate definition files. If you want to edit a definition, do not edit the definition files directly. Instead, edit the contents of build_scripts which get automatically pasted together into definition files during the pre-commit hook. The pre-commit hooked is tracked as part of the repository. In order to use it, you'll need to tell git to use a non-default hook directory and then set the pre-commit hook as executable.

    git config --local core.hooksPath githooks/
    chmod -R u+x ./githooks/pre-commit

This auto-generated definition file strategy allows different images to rely on shared code without relying on sequential builds which would be slow and also harder to figure out all the code that was used to create an image.

Note that github action build jobs will fail if the definition file isn't detected to be the exact result of the pasted-together contents of build_scripts. This ensures everyone uses the pre-commit hooks and mitigates the consequences of accidental direct editing of the definition files.

Note that the pre-commit hook calls an R script, so this is a local dependency as well as in the action where that script is run again to ensure it had been run as a pre-commit hook.

## Automated definition file creation

During the pre-commit hook, create_def_files.R (stored in the githooks directory) pastes together the contents of the build_scripts directory in the following way to create definition files:

-   Each directory in the build_scripts directory corresponds to an image. The directory name will determine name of the definition file (.def will be appended) which will be placed at the git repo root.

-   For each image, a definition file is constructed from the following files, corresponding to sections of a singularity definition file. All of these files are optional. If any of these files is not in the image directory it is silently skipped. (note bootstrap is only optional if a dependency structure is specified. see below).

    -   bootstrap

    -   %setup

    -   %files

    -   %post

    -   %environment

-   an image directory also may contain a dependencies.R script. This script is used to define the dependency structure of an image. Ie, the geospatial_plus_ml__4.1.0 image depends on geospatial_plus__4.1.0. This means that all the code in the geospatial_plus__4.1.0 definition file is run prior to any geospatial_plus_ml__4.1.0-specific definition code. This is done a on a section-by-section basis. So the %post section of geospatial_plus_ml__4.1.0's definition file is constructed first from geospatial_plus__4.1.0's post section, then from geospatial_plus_ml__4.1.0's post section. Then this process is repeated again for the environment section. The one exception is the bootstrap section. Each singularity definition can only have one bootstrap, so an image directory must contain either a bootstrap file or a dependency.R file. If a dependency file is present, the bootstrap file from the first dependency is used as the image's bootstrap.

-   Specifying the dependency.R script: this should be an R script that creates an R object called dependencies, which is a length-1 vector containing a directory name in build_scripts. Do not include an image's own directory name in the dependency file. If an image has no dependencies, just omit the dependency.R file entirely.

## Building images

This repo uses github actions to build images. There are three triggers:

-   workflow_dispatch: This allows manually starting the action through the github.com gui. This will *always* build definitions from main, even if run from a different branch. The intent of this is to be able to manually rerun the definitions unchanged to incorporate upstream rocker image changes. This will build and deploy all images. No commit or changes to definition files are necessary.
-   pull_request: Any commit in a pull request will run the action, but images are only built if the definitions are changed relative to the main branch (this prevents building for things like readme-only changes). When the trigger is pull_request, images are built but not deployed. This allows testing that the definition files works without uploading the image. The exception is dev tags which are built *and* deployed (which allows testing an image without the bother of merging a PR to main). Note that the pull_request trigger is really only designed to be a pull request where the target is main. Unpredictable results may occur if the destination branch isn't main.
-   push: This occurs when a pull request is merged into main (or a push to main without a pull request). This will cause images to be built and deployed, but only if the definition files are changed relative to the last commit on main (this prevents building for things like readme-only changes).

A couple more notes:
- Images cannot be deployed from a forked image since they rely on secrets.GITHUB_TOKEN which doesn't work from forks.
- Tags are features of the github container regisry which allow multiple versions of a container to exist under a single package. To create different tags in this repo, just create a directory under build_scripts with the same basename (eg geospatial_plus) as an existing container with a suffix seperated by a double underscore. Note that an image with a "dev" tag has special properties (in that it's deployed on a PR). All other images only get deployed if pushed to main.
- Note that different image tags don't depend on each other at all--they're entirely separate codebases. To start a new tag, I'd recommend copying an existing directory and renaming it. The only thing that relates images with the same basename but different tags is that they end up under the same package page (see  https://github.com/kaufman-lab/build_containers/pkgs/container/geospatial_plus_ml_horovod for an example)
- the build process starts for every commit on a PR, but images only get built for definition files that have changed relative to the main branch. If you want to rebuild images on a PR without a change, an empty commit should start the build process (this would be useful if you're trying to debug issues around github actions such as a failure to deploy).
- Only images which have a "dev" tag get deployed to the container registry for commits on a PR. All images are build, but only dev images are deployed. When a PR gets merged to master the images are rebuilt then actually deployed. this makes it so stable (version-tagged images) don't get messed with in PRs (with the exception of images with dev tags which should be assumed to be unstable).
- If a push workflow fails on main, a dangerous situation is created: definition files are committed to main but no corresponding images to those definitions have been deployed. To resolve this situation you need first fix the issue that caused the workflow failure then manually rerun the builds so they successfuly deploy from main.

Inspiration for this repo, along with more complicated examples for building multiple images can be found here: <https://github.com/singularityhub/github-ci>
