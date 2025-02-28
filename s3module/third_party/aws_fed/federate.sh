#!/bin/bash
set -e -o pipefail
ENV=$1

cd "$(dirname "${0}")/third_party/aws_fed" || exit

aws-fed login "${ENV}-deploy" -f aws-fed.toml
