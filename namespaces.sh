#!/bin/bash

## NAMESPACES HACKS! ##

function namespace() {
    af ns top "$1"
}

NS_FOLDER="$HOME/dev/namespaces"
CODE_EDITOR="code" # code / vim / sublime / ... whaever...

function __fetch_config() {
    namespace="$1"
    [ -d "$NS_FOLDER" ] || mkdir -p "$NS_FOLDER"
    target="$NS_FOLDER/$namespace.json"
    echo "fetching config for $namespace --> $target"
    if res=$(domain-cli config "$namespace"); then
        echo "$res" >"$NS_FOLDER/$namespace.json"
    else
        echo "error fetching NS $namespace:"
        echo "$res"
        return 1
    fi
}

function ns-config() {
    namespace="$1"
    target="$NS_FOLDER/$namespace.json"
    __fetch_config "$namespace" && eval "$CODE_EDITOR $target"
}

function ns-update() {
    namespace="$1"
    config="$NS_FOLDER/$namespace.json"
    if [ -f "$config" ]; then
        echo "found $config. updating!."
        if curl -v --fail -H "Content-Type: application/json" -d@"$config" -X POST http://nsapi.msp.eu1.appsflyer.com/namespace/update; then
            echo ""
            echo "\e[1m$namespace was updated! press any key to show status page (or ctrl-C to exit)\e[0m"
            read -r
            echo "loading ..."
            sleep 1
            af ns top "$namespace"
        fi
    else
        echo "$config not found for NS $namespace."
        echo "use ns-config command to fetch it:"
        echo "$ ns-config $namespace"
    fi
}

function ns-change() {
    namespace="$1"
    ns-config "$namespace"
    echo "\e[1m$namespace update your config and press any key go on and update (or ctrl-C to exit)\e[0m"
    read -r
    echo "sending update ..."
    ns-update "$namespace"
}

function ns-restart-id() {
    namespace="$1"
    id="$2"

    __fetch_config "$namespace" || return 1
    source_config="$NS_FOLDER/$namespace.json"
    target_tmp="/tmp/$namespace.json"

    jq --arg id "$id" --arg rand "$RANDOM" '(.services[] | select(.id == $id) | .envVariables.restarter) = $rand' "$source_config" >"$target_tmp" &&
        mv -f "$target_tmp" "$source_config" &&
        jq --arg id "$id" --arg rand "$RANDOM" '(.resources[] | select(.id == $id) | .envVariables.restarter) = $rand' "$source_config" >"$target_tmp" &&
        mv -f "$target_tmp" "$source_config" &&
        ns-update "$namespace"
}

function ns-with-branch() {
    namespace="$1"
    folder="$(pwd)"
    service=$(basename "${folder}")
    branch=$(git branch --show-current)

    __fetch_config "$namespace" || return 1
    source_config="$NS_FOLDER/$namespace.json"
    target_tmp="/tmp/$namespace.json"

    jq --arg service "$service" --arg branch "$branch" '(.services[] | select(.image.service == $service) | .image.branch) = $branch' "$source_config" >"$target_tmp" &&
        mv -f "$target_tmp" "$source_config" &&
        ns-update "$namespace"
}

alias ns='domain-cli'
alias ns-show='domain-cli ns'

PLUGINS_FOLDER="$HOME/.oh-my-zsh/custom/plugins/namespace"
[ -d "$PLUGINS_FOLDER" ] || mkdir -p "$PLUGINS_FOLDER"
DIR=${0%/*}
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
plugin=$(cat "$DIR/zsh-plugins/_namespace")

printf "#compdef ns-update\n\n%s\n" "$plugin" >"$PLUGINS_FOLDER/_ns-update"
printf "#compdef ns-config\n\n%s\n" "$plugin" >"$PLUGINS_FOLDER/_ns-config"
printf "#compdef namespace\n\n%s\n" "$plugin" >"$PLUGINS_FOLDER/_namespace"
printf "#compdef af ns top\n\n%s\n" "$plugin" >"$PLUGINS_FOLDER/_nstop"
printf "#compdef ns-restart-id\n\n%s\n" "$plugin" >"$PLUGINS_FOLDER/_ns-restart-id"
printf "#compdef ns-with-branch\n\n%s\n" "$plugin" >"$PLUGINS_FOLDER/_ns-with-branch"

\cp -fR "$DIR/zsh-plugins/_domain-cli" "$PLUGINS_FOLDER"
