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
    branches: [main, master]

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
    branches: [main,master]

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
          TYPE: npm
          PATH: package.json
```

## Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| TYPE | true | Type of repo. See below for supported repo types |
| PATH | true | Path to the repo type's metadata file |
| TOKEN | true | Personal Access Token with Repo scope |

## Supported Repo Types

| Repo Type | File | Description |
| --- | --- | --- |
| npm | package.json | package.json for repo |
| nuget | ProjectName.csproj | csproj file for project |
| python | ProjectName.toml | toml file for project |

Note if using standard `PATH` inputs the `TYPE` input is not required.

## Metadata without a package manager

If you have a project that does not have a supported package manager, or if you just don't want to store metadata in your `package.json` and friends, you can create a file called `metadata.json` and store your metadata there.

This file will be prioritized over the package manager metadata files. Here's an example.

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

## Updating Metadata via GH CLI

With a `pyproject.toml` ([Justfile](https://just.systems) recipe):

```
github_repo_set_metadata:
  gh repo edit \
    --description "$(yq  '.project.description' pyproject.toml)" \
    --homepage "$(yq '.project.urls.Repository' pyproject.toml)" \
    --add-topic "$(yq '.project.keywords | join(",")' pyproject.toml)"
```

`metadata.json`:

```
github_repo_set_metadata:
  gh repo edit \
    --description "$(jq -r '.description' metadata.json)" \
    --homepage "$(jq -r '.homepage' metadata.json)" \
    --add-topic "$(jq -r '.keywords | join(",")' metadata.json)"
```
