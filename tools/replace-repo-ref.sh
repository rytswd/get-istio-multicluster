#!/usr/bin/env bash

__b__=$(tput bold)
__bg__=$(tput bold)$(tput setaf 2)
__by__=$(tput bold)$(tput setaf 3)
__cl__=$(tput sgr0)

confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
    [yY][eE][sS] | [yY])
        true
        ;;
    *)
        false
        ;;
    esac
}

echo "${__bg__}Replace all repository reference of 'rytswd/get-istio-multicluster'${__cl__}"
echo

remote=$(git remote -v | awk '{print $2}' | head -1)
if [[ -z $remote ]]; then
    repo=$remote
    echo "  Remote repository information found: '${remote}'"
    confirm "  Proceed with this repo name for the replace? [y/N] " || repo=""
    echo
fi

if [[ -z $repo ]]; then
    read -r -p "  Enter your GitHub username for your forked repository: " username
    read -r -p "  Enter the name of forked repository (defaults to 'get-istio-multicluster'): " reponame
    [[ -z $reponame ]] && reponame='get-istio-multicluster' # Fall back to 'get-istio-multicluster'
    repo="${username}/${reponame}"
fi

echo
confirm "About to replace '${__b__}rytswd/get-istio-multicluster${__cl__}' with '${__by__}${username}/${reponame}${__cl__}', are you sure to proceed? [y/N] " || {
    echo "Canceled."
    exit
}

find . -type f -name '*.yaml' -print0 |
    xargs -0 -n 1 perl -pi -e "s/rytswd\/get-istio-multicluster/${username}\/${reponame}/g"

echo
echo "Replace complete."
