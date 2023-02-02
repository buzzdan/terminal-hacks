#!/bin/bash

## AF utility functions
okta_username="$(cat ~/.af/.okta_username)"
alias santa="ssm santa.eu1.appsflyer.com"
alias ob="python3 -m obhave"
alias aws="aws --profile=appsflyer"
alias okta="security find-generic-password -a ${okta_username} -s appsflyer.okta -w | tr -d '\n' | pbcopy"


function tok() {
    # source "$HOME/.ssh/source-creation-vault.sh"
    af vault login --login-with-keychain && { 
        export TOKEN=$(cat ~/.vault-token)
        printf "${BWhite}\nTOKEN is > ${BGreen}%s${Color_Off}\n\n" "$TOKEN"
        echo "$TOKEN" | pbcopy
    }
}

function creds() {
    tok
    # unset AWS_SECRET_KEY AWS_SECRET_ACCESS_KEY AWS_ACCESS_KEY AWS_ACCESS_KEY_ID
    aws sso login --profile Production_Developers-195229424603
    #  ~/.aws/aws-okta.sh --silent-mode -a
   
}


## i2cssh ssh to all machines on a cluster ##

# To make this work you need to install some funky stuff.
# Follow the instructions in Erez Mazor's snippet: https://gitlab.appsflyer.com/snippets/64

alias i2cssh="i2cssh -Xo=StrictHostKeyChecking=no"

i2csshrc_file="$HOME/.i2csshrc"
[ -f "${i2csshrc_file}" ] || /bin/cat <<EOM >"${i2csshrc_file}"
---
version: 2
broadcast: true
iterm2: true   
profile: i2cssh
environment:
    - LC_ALL: en_US.UTF-8
EOM

function ec2-hosts() {
    aws ec2 describe-instances --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`].Value}' --filters "Name=tag:Name,Values=$1*" | jq ".[].Name[0]"
}

function i2cssh-hosts() {
    creds
    HOSTS_LIST=$(ec2-hosts "$1")
    HOSTS_COMMA_DELIMITED=$(echo $HOSTS_LIST | paste -s -d, -)
    echo "Opening i2cssh SSH session to: [$HOSTS_COMMA_DELIMITED]"
    i2cssh -m "$HOSTS_COMMA_DELIMITED"
}
