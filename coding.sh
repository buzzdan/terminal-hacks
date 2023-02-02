#!/bin/bash

## CODING HACKS! ##

# linter taken from: https://gitlab.appsflyer.com/clojure/tooling/af-clj-kondo?nav_source=navbar#usage

# Optional args:
#1 - file(s) to scan location
#2 - side branch
function af-kondo-linter(){
    local full_path=$PWD
    if [ -n "$1" ]; then
        full_path=$(realpath $1)
    fi

    if [ -f af-community-kondo-version ]; then
        local version=$(cat af-community-kondo-version)
    else
        echo "ERROR, please setup a local config file"
        return
    fi

    local branch=master
    if  [ -n "$2" ]; then
        branch=$2
    fi

    docker run \
    -v $PWD:$PWD \
    -w $PWD \
    --rm \
    artifactory.appsflyer.com:5000/af-kondo-linter-$branch:$version $full_path
}

alias lint=af-kondo-linter