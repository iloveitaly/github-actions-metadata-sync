# GitHub Metadata Sync

Github Action to sync repo metadata from code to repo.

[![version](https://img.shields.io/github/v/release/iloveitaly/github-actions-metadata-sync)](https://img.shields.io/github/v/release/iloveitaly/github-actions-metadata-sync)

# Use Cases

Keep the GitHub repo metadata (description, tags) in sync with your code! Metadata is now configuration as code, and can be validated with a Pull Request.

# Setup

Create a new file called `/.github/workflows/repo-sync.yml` that looks like so:

```yaml
name: Repo Sync

on:
  push:
    branches:
      - main
  schedule:
    - cron: 0 0 * * *

jobs:
  repo_sync:
    runs-on: ubuntu-latest
    steps:
      - name: Fetching Local Repository
        uses: actions/checkout@v3
      - name: Repo Metadata Sync
        uses: iloveitaly/github-actions-metadata-sync@v1
        with:
          TOKEN: ${{ secrets.GH_PERSONAL_TOKEN }}
          # optional params, these are inferred from the repo type!
          INPUT_TYPE: npm
          INPUT_PATH: package.json
```

Note that the built in `secrets.github_token` does not have the necessary permissions to update the repo description. Use
a personal access token instead:

```shell
gh secret set GH_PERSONAL_TOKEN --app actions --body ghp_the_key
```

Alternatively, you can let the action infer `TYPE` and `PATH` for you:

```yaml
name: Repo Sync

on:
  push:
    branches:
      - master
  schedule:
    - cron: 0 0 * * *

jobs:
  repo_sync:
    runs-on: ubuntu-latest
    steps:
      - name: Fetching Local Repository
        uses: actions/checkout@master
      - name: Sync Repository Metadata
        uses: iloveitaly/github-actions-repo-sync@v1
        with:
          TOKEN: ${{ secrets.GH_PERSONAL_TOKEN }}
```

## Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| INPUT_TYPE | true | Type of repo. See below for supported repo types |
| INPUT_PATH | true | Path to the repo type's metadata file |
| TOKEN | true | Personal Access Token with Repo scope |

## Supported Repo Types

| Repo Type | File | Description |
| --- | --- | --- |
| npm | package.json | package.json for repo |
| nuget | ProjectName.csproj | csproj file for project |
| python | ProjectName.toml | toml file for project |

Note if using standard `PATH` inputs the `TYPE` input is not required.

## Tips

For repo types that aren't listed above (like this one), you can still use this action, just have to get creative.

For example (and I would recommend), you can create a file called `metadata.json`, choose the npm type, and make the file look like so:

```json
{
  "description": "Repo description",
  "homepage": "https://github.com/kbrashears5/github-action-repo-sync",
  "keywords": [
    "sync",
    "repo",
    "metadata"
  ]
}
```

For example, see [.github/workflows/repo-sync.yml](.github/workflows/repo-metadata-sync.yml)` & `metadata.json` in this repo
