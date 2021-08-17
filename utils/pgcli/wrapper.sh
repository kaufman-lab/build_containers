#!/bin/bash

export SINGULARITY_BINDPATH="/var/run/postgresql"

app=pgcli
ver=2.2
sif_file=${app}-${ver}.sif

selfdir="/usr/local/apps/${app}/${ver}"

cmd="$(basename $0)"

singularity exec --cleanenv "${selfdir}/libexec/${sif_file}" "$cmd" "$@"
