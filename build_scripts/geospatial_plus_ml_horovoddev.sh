#!/bin/bash

gh_token=$(cat /tmp/hostvar.txt)
echo $gh_token | gh auth login --with-token
rm -rf /tmp/hostvar.txt

mkdir /tensorflow_wheels_v2.5.0
cd /tensorflow_wheels_v2.5.0
gh release download v2.5.0  --repo kaufman-lab/build_tensorflow

cd /