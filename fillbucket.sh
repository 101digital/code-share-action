#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

trap "echo 'Missing parameter'; exit 1" INT TERM EXIT

username="$1"
password="$2"
company="$3"
reponame="$4"
branch="$5"
dest_repo_url="$6"
ignorelist=($7)
commithistory="$8"

trap - INT TERM EXIT

CURL_OPTS=(-u "$username:$password" --silent)
reponame=$(echo $reponame | tr '[:upper:]' '[:lower:]')

if [[ ${dest_repo_url} == *"bitbucket"* ]]; then
    echo "Validating Repo credentials..."
    curl --fail "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/user" > /dev/null || (
        echo "... failed. Most likely, the provided credentials are invalid. Terminating..."
        exit 1
    )

    echo "Checking if BitBucket repository \"$company/$reponame\" exists..."
    curl "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/repositories/$company/$reponame" | grep "error" > /dev/null && (
        echo "BitBucket repository \"$company/$reponame\" does NOT exist, creating it..."
        curl -X POST --fail "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/repositories/$company/$reponame" -H "Content-Type: application/json" -d '{"scm": "git", "is_private": "true"}' > /dev/null
    )
elif [[ ${dest_repo_url} == *"github.com"* ]]; then
    echo "Validating Repo credentials..."
    curl --fail -u $username:$password --silent "https://$dest_repo_url/api/v3/user" > /dev/null || (
        echo "... failed. Most likely, the provided credentials are invalid. Terminating..."
        exit 1
    )

    echo "Checking if Github repository \"$company/$reponame\" exists..."
    curl -I -s -o /dev/null -w "%{http_code}" -u $username:$password -H "Accept: application/vnd.github.v3+json"  "https://$dest_repo_url/api/v3/repos/$company/$reponame" | grep "404" && (
        echo "Github repository \"$company/$reponame\" does NOT exist, Please create it..."
        echo "Creating new repo on Github..."
        curl -L -X POST -H "Accept: application/vnd.github+json"  -u $username:$password "https://api.github.com/user/repos" -d "{\"name\":\"$reponame\",\"description\":\"$reponame dependency for 101d app\",\"private\":true}"
    )
else
    echo "Validating Repo credentials..."
    curl --fail -u $username:$password --silent "https://$dest_repo_url/api/v3/user" > /dev/null || (
        echo "... failed. Most likely, the provided credentials are invalid. Terminating..."
        exit 1
    )

    echo "Checking if Github repository \"$company/$reponame\" exists..."
    curl -I -s -o /dev/null -w "%{http_code}" -u $username:$password -H "Accept: application/vnd.github.v3+json"  "https://$dest_repo_url/api/v3/repos/$company/$reponame" | grep "404" && (
        echo "Github repository \"$company/$reponame\" does NOT exist, Please create it..."
        echo "Creating new repo on Github..."
        curl -L -X POST -H "Accept: application/vnd.github+json"  -u $username:$password "https://$dest_repo_url/api/v3/orgs/$company/repos" -d "{\"name\":\"$reponame\",\"description\":\"$reponame dependency for 101d app\",\"private\":true}"
    )
fi

echo "Pushing to remote..."
if [ ${commithistory} == "true" ]; then
    echo "Sync the latest changes to $branch branch with full commit history"
    git config --global --add safe.directory "*"
    git config --global user.email "githubactions@101digital.io"
    git config --global user.name "Github Actions"
    git config --global http.version HTTP/1.1
    git config --global http.postBuffer 157286400
    echo "Set the remote Repo.. https://"$username:$password"@$dest_repo_url/$company/$reponame"
    git remote add dest_origin https://"$username:$password"@$dest_repo_url/$company/$reponame
    git branch -M $branch
    git fetch dest_origin
    git push dest_origin $branch --porcelain --force-with-lease --force-if-includes
else
    echo "Cleaning the commit history.."
    rm -rf .git
    git init -b $branch
    git config --global --add safe.directory "*"
    git config --global user.email "githubactions@101digital.io"
    git config --global user.name "Github Actions"

    echo "Adding ignore items if defined"
    if [ -n "$ignorelist" ]; then
        for item in "${ignorelist[@]}"; do
            echo $item >> .gitignore
        done
    fi

    echo "Commit the latest changes to $branch branch.."
    git add .
    git commit -m "Sync latest changes"
    git branch -M $branch
    echo "Set the remote Repo.. https://"$username:$password"@$dest_repo_url/$company/$reponame"
    git remote add dest_origin https://"$username:$password"@$dest_repo_url/$company/$reponame.git
    echo "Pushing to remote..."
    git push dest_origin $branch --force
    echo "Cleanup..."
    ls -ltr
    rm -rf  .gitignore .git
fi
