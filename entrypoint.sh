#!/bin/bash
set -euo pipefail

# problem matcher must exist in workspace
cp /error-matcher.json $HOME/repo-sync-error-matcher.json
echo "::add-matcher::$HOME/repo-sync-error-matcher.json"

echo "Repository: [$GITHUB_REPOSITORY]"

# log inputs
echo "Inputs"
echo "---------------------------------------------"
REPO_TYPE="$INPUT_TYPE"
FILE_PATH="$INPUT_PATH"
GITHUB_TOKEN="$INPUT_TOKEN"
echo "Repo type    : $REPO_TYPE"
echo "Path         : $FILE_PATH"
GIT_EMAIL="$INPUT_GIT_EMAIL"
echo "Git email       : $GIT_EMAIL"
GIT_USERNAME="$INPUT_GIT_USERNAME"
echo "Git username    : $GIT_USERNAME"

# Infer file path if not provided
if [ -z "$FILE_PATH" ]; then
    if [ -f "metadata.json" ]; then
        FILE_PATH="metadata.json"
    elif [ -f "package.json" ]; then
        FILE_PATH="package.json"
    elif [ -f "pyproject.toml" ]; then
        FILE_PATH="pyproject.toml"
    elif [ -f *.csproj ]; then
        FILE_PATH=$(ls *.csproj | head -n 1)
    else
        echo "File path not provided and could not be inferred"
        exit 1
    fi
fi

# infer repo type if not provided
if [[ -z "$REPO_TYPE" && ("$FILE_PATH" == "package.json" || "$FILE_PATH" == "metadata.json") ]]; then
    REPO_TYPE="npm"
elif [[ -z "$REPO_TYPE" && "$FILE_PATH" == "pyproject.toml" ]]; then
    REPO_TYPE="python"
elif [[ -z "$REPO_TYPE" && "$FILE_PATH" == *".csproj" ]]; then
    REPO_TYPE="nuget"
else
    echo "Repo type not provided and could not be inferred"
    exit 1
fi

# set temp path
TEMP_PATH="/ghars/"
cd /
mkdir "$TEMP_PATH"
cd "$TEMP_PATH"
echo "Temp Path       : $TEMP_PATH"
echo "---------------------------------------------"

echo " "

# find username and repo name
REPO_INFO=($(echo $GITHUB_REPOSITORY | tr "/" "\n"))
USERNAME=${REPO_INFO[0]}
echo "Username: [$USERNAME]"
REPO_NAME=${REPO_INFO[1]}
echo "Repo name: [$REPO_NAME]"

# initialize git
# TODO pretty certain we can remove all of this and just use GITHUB_ACTOR
echo "Intiializing git"
git config --system core.longpaths true
git config --global core.longpaths true
git config --global user.email "$GIT_EMAIL" && git config --global user.name "$GIT_USERNAME"
echo "Git initialized"

echo " "

# clone the repo
REPO_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
GIT_PATH="${TEMP_PATH}${GITHUB_REPOSITORY}"
echo "Cloning [$REPO_URL] to [$GIT_PATH]"
# TODO since we are cloning here, why do we have a clone call in the repo yml?
git clone --quiet --no-hardlinks --no-tags --depth 1 $REPO_URL ${GITHUB_REPOSITORY}

cd $GIT_PATH

# verify path exists
echo "Checking that [${FILE_PATH}] exists"
if [ ! -f "$FILE_PATH" ]; then
    echo "Path does not exist: [${FILE_PATH}]"
    exit 1
fi

# default the parameters
DESCRIPTION=""
WEBSITE=""
TOPICS=""

echo " "

echo "Repo type: ${REPO_TYPE}"

# determine repo type
if [ "$REPO_TYPE" == "npm" ]; then
    echo "Repo type: NPM"
    # read in the variables from package.json
    echo "Parsing ${FILE_PATH}"
    DESCRIPTION=$(jq -r '.description' ${FILE_PATH})
    WEBSITE=$(jq -r '.homepage' ${FILE_PATH})
    TOPICS=$(jq '.keywords' ${FILE_PATH})

elif [ "$REPO_TYPE" == "nuget" ]; then
    echo "Repo type: NuGet"
    DESCRIPTION=$(grep -oP '(?<=<Description>)[^<]+' "${FILE_PATH}")
    WEBSITE=$(grep -oP '(?<=<RepositoryUrl>)[^<]+' "${FILE_PATH}")
    TOPICS_STRING=$(grep -oP '(?<=<PackageTags>)[^<]+' "${FILE_PATH}")
    TOPICS_ARRAY=$(echo $TOPICS_STRING | tr ";" "\n")
    TOPICS=$(printf '%s\n' "${TOPICS_ARRAY[@]}" | jq -R . | jq --no-progress-meter .)

elif [ "$REPO_TYPE" == "python" ]; then
    echo "Repo type: Python"
    # read in the variables from pyproject.toml
    echo "Parsing ${FILE_PATH}"
    DESCRIPTION=$(yq e '.tool.poetry.description // .project.description' ${FILE_PATH})
    WEBSITE=$(yq e '.tool.poetry.homepage // .project.urls.Repository' ${FILE_PATH})
    TOPICS=$(
        result=$(yq -ojson eval '.tool.poetry.keywords // .project.keywords' ${FILE_PATH})
        if [ "$result" = "null" ]; then
            echo "[]"
        else
            echo $result
        fi
    )
else
    echo "Unsupported repo type: [${REPO_TYPE}]"
    exit 1
fi

if [ "$DESCRIPTION" = "null" ] && [ "$DESCRIPTION" = "" ] && [ "$WEBSITE" = "null" ] && [ "$WEBSITE" = "" ] && [ "$TOPICS" = "null" ] && [ "$TOPICS" = "" ]; then
    echo "Error: No updates found - description, website and topics are all empty"
    exit 1
fi

# update the description
echo " "
echo "Description: ${DESCRIPTION}"
if [ "$DESCRIPTION" != null ] && [ "$DESCRIPTION" != "" ]; then
    echo "Updating description for [${GITHUB_REPOSITORY}]"
    jq -n --arg description "$DESCRIPTION" '{description:$description}'
    jq -n --arg description "$DESCRIPTION" '{description:$description}' | curl --no-progress-meter -d @- \
        -X PATCH \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/json" \
        -u ${USERNAME}:${GITHUB_TOKEN} \
        --fail \
        ${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}
fi

# update the homepage
echo " "
echo "Website: ${WEBSITE}"
if [ "$WEBSITE" != null ] && [ "$WEBSITE" != "" ]; then
    echo "Updating homepage for [${GITHUB_REPOSITORY}]"
    jq -n --arg homepage "$WEBSITE" '{homepage:$homepage}'
    jq -n --arg homepage "$WEBSITE" '{homepage:$homepage}' | curl --no-progress-meter -d @- \
        -X PATCH \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/json" \
        -u ${USERNAME}:${GITHUB_TOKEN} \
        --fail \
        ${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}
fi

# update the topics
echo " "
echo "Topics: ${TOPICS}"
if [ "$TOPICS" != null ] && [ "$TOPICS" != "" ]; then
    echo "Updating topics for [${GITHUB_REPOSITORY}]"
    jq -n --argjson topics "$TOPICS" '{names:$topics}'
    jq -n --argjson topics "$TOPICS" '{names:$topics}' | curl --no-progress-meter -d @- \
        -X PUT \
        -H "Accept: application/vnd.github.mercy-preview+json" \
        -u ${USERNAME}:${GITHUB_TOKEN} \
        --fail \
        ${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/topics
fi
