#!/bin/bash

echo "Repository: [$GITHUB_REPOSITORY]"

# log inputs
echo "Inputs"
echo "---------------------------------------------"
REPO_TYPE="$INPUT_TYPE"
FILE_PATH="$INPUT_PATH"
GITHUB_TOKEN="$INPUT_TOKEN"
echo "Repo type    : $REPO_TYPE"
FILES=($RAW_FILES)
echo "Path         : $FILE_PATH"

if [ "$GITHUB_TOKEN" == null -o "$GITHUB_TOKEN" == "" ]; then
    echo "Token was not provided"
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

# initalize git
echo "Intiializing git"
git config --system core.longpaths true
git config --global core.longpaths true
git config --global user.email "action-bot@github.com" && git config --global user.name "Github Action"
echo "Git initialized"

echo " "

# clone the repo
REPO_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
GIT_PATH="${TEMP_PATH}${GITHUB_REPOSITORY}"
echo "Cloning [$REPO_URL] to [$GIT_PATH]"
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

echo "###[group] $REPO_TYPE"

# determine repo type
if [ "$REPO_TYPE" == "npm" ]; then
    echo "Repo type: NPM"
    # read in the variables from package.json
    echo "Parsing ${FILE_PATH}"
    DESCRIPTION=`jq -r '.description' ${FILE_PATH}`
    WEBSITE=`jq -r '.homepage' ${FILE_PATH}`
    TOPICS=`jq '.keywords' ${FILE_PATH}`

elif [ "$REPO_TYPE" == "nuget" ]; then
    echo "Repo type: NuGet"
    DESCRIPTION=$(grep -oP '(?<=<Description>)[^<]+' "${FILE_PATH}")
    WEBSITE=$(grep -oP '(?<=<RepositoryUrl>)[^<]+' "${FILE_PATH}")
    TOPICS_STRING=$(grep -oP '(?<=<PackageTags>)[^<]+' "${FILE_PATH}")
    TOPICS_ARRAY=$(echo $TOPICS_STRING | tr ";" "\n")
    TOPICS=`printf '%s\n' "${TOPICS_ARRAY[@]}" | jq -R . | jq -s .`
else
    echo "Unsupported repo type: [${REPO_TYPE}]"
    exit 1
fi

# update the description
echo " "
echo "Description: ${DESCRIPTION}"
if [ "$DESCRIPTION" != null -a "$DESCRIPTION" != "" ]; then
    echo "Updating description for [${GITHUB_REPOSITORY}]"
    jq -n --arg description "$DESCRIPTION" '{description:$description}'
    jq -n --arg description "$DESCRIPTION" '{description:$description}' |  curl -d @- \
        -X PATCH \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/json" \
        -u ${USERNAME}:${GITHUB_TOKEN} \
        --silent \
        ${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}
fi

# update the homepage
echo " "
echo "Website: ${WEBSITE}"
if [ "$WEBSITE" != null -a "$WEBSITE" != "" ]; then
    echo "Updating homepage for [${GITHUB_REPOSITORY}]"
    jq -n --arg homepage "$WEBSITE" '{homepage:$homepage}'
    jq -n --arg homepage "$WEBSITE" '{homepage:$homepage}' | curl -d @- \
        -X PATCH \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/json" \
        -u ${USERNAME}:${GITHUB_TOKEN} \
        --silent \
        ${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}
fi

# update the topics
echo " "
echo "Topics: ${TOPICS}"
if [ "$TOPICS" != null -a "$TOPICS" != "" ]; then
    echo "Updating topics for [${GITHUB_REPOSITORY}]"
    jq -n --argjson topics "$TOPICS" '{names:$topics}'
    jq -n --argjson topics "$TOPICS" '{names:$topics}' | curl -d @- \
        -X PUT \
        -H "Accept: application/vnd.github.mercy-preview+json" \
        -u ${USERNAME}:${GITHUB_TOKEN} \
        --silent \
        ${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/topics
fi