#!/bin/bash

DIR=${0%/*}
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/general-utils.sh"
. "$DIR/af-utils.sh"
. "$DIR/coding.sh"
. "$DIR/namespaces.sh"
