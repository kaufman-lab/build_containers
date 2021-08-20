# build_containers

This repo builds and stores singularity images to be used in lab workflows.

## Available Images

The set of image types that are available are displayed on the right under "packages".

There are two images types:

-   `geospatial_plus`: Builds on the [rocker](https://github.com/rocker-org/rocker-versioned2) geospatial docker image.

    -   includes a few additional packages (including data.table, intervalaverage and terra)

    -   also has configured the R user library location to avoid clashing with the user library on the host machine.

-   `geospatial_plus_ml`

    -   additionally includes torch for R, and tensorflow for python, and the reticulate package. The version of tensorflow is specifically intel's version for avx512 since this is primarily intended to be run on an intel high performance compute (HPC) cluster.

-   `geospatial_plus_ml_horovod`

    -   additionally includes horovod (tensorflow only, set up for CPU) and openmpi.

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

## Definition files

This repository uses both git a pre-commit hook to auto-generate definition files. If you want to edit a definition, do not edit the definition files directly. Instead, edit the contents of build_scripts which get automatically pasted together into definition files as a pre-commit hook.  The pre-commit hooked is tracked as part of the repository. In order to use it, you'll need to tell git to use a non-default hook directory and then set the pre-commit hook as executable.

    git config --local core.hooksPath githooks/
    chmod -R u+x ./githooks/pre-commit

This auto-generated definition file strategy allows different images to rely on shared code without relying on sequential builds which would be slow and also harder to figure out all the code that was used to create an image.

Note that github action build jobs will fail if the definition file isn't detected to be the exact result of the pasted-together contents of build_scripts. This ensures everyone uses the pre-commit hooks and mitigates the consequences of accidental direct editing of the definition files.

## Building images

This repo uses github actions to build images. There are three triggers:

-   workflow_dispatch: This allows manually starting the action through the github.com gui. This will *always* build definitions from main, even if run from a different branch. The intent of this is to be able to manually rerun the definitions unchanged to incorporate upstream rocker image changes. This will build and deploy all images. No commit or changes to definition files are necessary.
-   pull_request: Any commit in a pull request will run the action, but images are only built if the definitions are changed relative to the main branch. When the trigger is pull_request, images are built but not deployed. This allows testing that the definition files works without uploading the image. The exception is dev tags which are built *and* deployed (which allows testing an image without the bother of merging a PR to main). Note that the pull_request trigger is really only designed to be a pull request where the target is main. Unpredictable results may occur if the destination branch isn't main.
-   push: This occurs when a pull request is merged into main (or a push to main without a pull request). This will cause images to be built and deployed, but only if the definition files are changed relative to the last commit on main.  This makes it straightforward to edit readme, actions, commit hooks, etc without building/deploying.

Inspiration for this repo, along with more complicated examples for building multiple images can be found here: <https://github.com/singularityhub/github-ci>
