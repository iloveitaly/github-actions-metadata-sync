# GitHub Metadata Sync [![version](https://img.shields.io/github/v/release/iloveitaly/github-actions-metadata-sync)](https://img.shields.io/github/v/release/iloveitaly/github-actions-metadata-sync)

Github Action to sync repo metadata (description, homepage, topics) from code to repo.

## Use Cases

Keep the GitHub repo metadata (description, tags) in sync with your code! Metadata is now configuration as code, and can be validated with a Pull Request.

This is nearly identical to [github-actions-repo-sync](https://github.com/kbrashears5/github-action-repo-sync) with the primary differences being:

* Docker container is pulled and not built dynamically (less runtime)
* The file name and type are inferred from the repo, so there's less configuration

## Setup

Create a new file called `.github/workflows/repo-sync.yml` that looks like so:

```yaml
name: Repository Metadata Sync

on:
  push:
    branches: [main]

jobs:
  repo_sync:
    runs-on: ubuntu-latest
    steps:
      - name: Fetching Local Repository
        uses: actions/checkout@v4
      - name: Repository Metadata Sync
        uses: iloveitaly/github-actions-metadata-sync@v1
        with:
          TOKEN: ${{ secrets.GH_PERSONAL_TOKEN }}
```

Note that the built in `secrets.github_token` does not have the necessary permissions to update the repo description. You must use a personal access token instead:

```shell
gh secret set GH_PERSONAL_TOKEN --app actions --body ghp_the_key
```

Alternatively, you can manually specify the type and path (these are inferred from the repo type by default):

```yaml
name: Repository Metadata Sync

on:
  push:
    branches: [main]

jobs:
  repo_sync:
    runs-on: ubuntu-latest
    steps:
      - name: Fetching Local Repository
        uses: actions/checkout@v4
      - name: Repository Metadata Sync
        uses: iloveitaly/github-actions-metadata-sync@v1
        with:
          TOKEN: ${{ secrets.GH_PERSONAL_TOKEN }}
          # optional params, these are inferred from the repo type!
          INPUT_TYPE: npm
          INPUT_PATH: package.json
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

## Metadata without a package manager

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

For example, see [.github/workflows/repo-sync.yml](.github/workflows/repo-metadata-sync.yml) and `metadata.json` in this repo
