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

#echo "Validating Repo credentials..."
#curl --fail "${CURL_OPTS[@]}" "https://$dest_repo_url/api/v3/user" > /dev/null || (
#    echo "... failed. Most likely, the provided credentials are invalid. Terminating..."
#    exit 1
#)


reponame=$(echo $reponame | tr '[:upper:]' '[:lower:]')

echo "Checking if Github repository \"$company/$reponame\" exists..."
curl "${CURL_OPTS[@]}" "https://$dest_repo_url/api/v3/repos/$company/$reponame" | grep "error" > /dev/null && (
    echo "Github repository \"$company/$reponame\" does NOT exist, Please creat it..."
    #Enable following line if repo needs to be created at this stage
    #For bitbucket
    #curl -X POST --fail "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/repositories/$company/$reponame" -H "Content-Type: application/json" -d '{"scm": "git", "is_private": "true"}' > /dev/null
    #For Github
    #curl -X POST --fail "${CURL_OPTS[@]}" "https://$dest_repo_url/api/v3/user/repos" -H "Content-Type: application/json" -d '{"name":$reponame, "private": true}' > /dev/null

)

echo "Pushing to remote..."
if [ ${commithistory} == "true" ];
then
{
echo "Sync the latest changes to $branch branch with full commit history"
echo "Set the remote Repo.. https://"$username:$password"@$dest_repo_url/$company/$reponame"
git remote add dest_origin https://"$username:$password"@$dest_repo_url/$company/$reponame.git
git branch -M $branch
git push dest_origin $branch --porcelain --force-with-lease --force-if-includes

}
else
{
echo "Cleaning the commit history.."
rm -rf .git
git init -b $branch
git config --global --add safe.directory "*"
git config --global user.email "githubactions@101digital.io"
git config --global user.name "Github Actions"

echo "Adding ignore items if defined"
if [ -n "$ignorelist" ]; then
for item in "${ignorelist[@]}" ; do echo $item >> .gitignore ; done
fi

echo "Commit the latest changes to $branch branch.."
git add .
git commit -m "Sync latest changes"
git branch -M $branch
echo "Set the remote Repo.. https://"$username:$password"@$dest_repo_url/$company/$reponame"
git remote add dest_origin https://"$username:$password"@$dest_repo_url/$company/$reponame.git
echo "Pushing to remote..."
#git push dest_origin $branch --porcelain --force-with-lease --force-if-includes
git push dest_origin $branch  --force
echo "Cleanup..."
ls -ltr
rm -rf  .gitignore .git
}
fi