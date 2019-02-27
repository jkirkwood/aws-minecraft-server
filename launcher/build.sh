#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" || exit
rm build_*.zip

zipname="build__$(date +%s).zip"
zip "$zipname" main.js

echo "launcher_lambda_filename = \"../launcher/${zipname}\"" > ../terraform/launcher.auto.tfvars
