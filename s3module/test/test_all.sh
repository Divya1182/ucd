#!/bin/bash
set -e -o pipefail

tfswitch $TERRAFORM_VERSION || exit
cd "$(dirname "${0}")/test"
go test -v -timeout 30m