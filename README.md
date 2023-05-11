# Mirror to BitBucket GitHub Action

Mirrors a GitHub Git repository to BitBucket. If no corresponding BitBucket repository exists, it is created using the [BitBucket API 2.0](https://developer.atlassian.com/bitbucket/api/2/reference/).

**Please note**: make sure that you checkout the entire repository before using this. By default, `actions/checkout@v2` only creates a shallow clone. See section [example usage](#example-usage) on how to do a complete clone.

## Required Inputs

### `password`
Password to use on bitbucket for authentication and for pushing.


## Optional Inputs
### `username`
Username to use on bitbucket for authentication. Default: GitHub user name.

### `password`
Password to use on bitbucket for authentication. Password can be saved as a secret in GitHub.

### `company`
Company to use on bitbucket repo path.
### `repository`
Name of the repository on bitbucket. If it does not exist, it is created automatically. Default: GitHub repository name.

Sample for explain the usage of the all arguments:
git push https://"$username:$password"@bitbucket.org/$company/$reponame.git
## Outputs
None

## Example usage

      - name: Checkout
        uses: actions/checkout@v2
        with:
          fetch-depth: 0 # <-- clone with complete history
      - name: Push
        uses: 101digital/code-share-action@main
        with:
          username: username
          password: ${{ secrets.UD_BITBUCKET_PASSWORD }}
          company: company_name
          repository: wallet-service
