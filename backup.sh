#!/bin/bash

#  Check for .env file and source it
if [ -f .env ]; then
    source .env
else
    echo ".env file not found. Using default or existing environment variables."
fi

# Use environment variables or set default values
TOKEN="${GITHUB_TOKEN}"
DEST_DIR="${BACKUP_DEST_DIR:-./backup}"
LOG_PATH="${BACKUP_LOG_PATH:-$DEST_DIR/backup.log}"

mkdir -p "$DEST_DIR"

# Function to log messages
log_message() {
    echo "$(date): $1" >> "$LOG_PATH"
}

# Check for errors
error_exit() {
    log_message "$1"
    exit 1
}

# Fetch list of user repositories
curl -sH "Authorization: token $TOKEN" "https://api.github.com/user/repos?type=owner&per_page=100" | jq -r .[].ssh_url > repos.txt || error_exit "Failed to fetch user repos."

# Automatically fetch organizations and their repositories
ORGANIZATIONS=$(curl -sH "Authorization: token $TOKEN" "https://api.github.com/user/orgs" | jq -r .[].login) || error_exit "Failed to fetch organizations."

for ORG in $ORGANIZATIONS; do
    curl -sH "Authorization: token $TOKEN" "https://api.github.com/orgs/$ORG/repos?per_page=100" | jq -r .[].ssh_url >> repos.txt || error_exit "Failed to fetch repos for organization $ORG."
done

# Mirror or update all repositories
while read REPO; do
    REPO_NAME=$(basename $REPO .git)
    if [ -d "$DEST_DIR/$REPO_NAME.git" ]; then
        log_message "Updating $REPO_NAME"
        git --git-dir="$DEST_DIR/$REPO_NAME.git" remote update || log_message "Failed to update $REPO_NAME."
    else
        log_message "Cloning $REPO_NAME"
        git clone --mirror $REPO "$DEST_DIR/$REPO_NAME.git" || log_message "Failed to clone $REPO_NAME."
    fi
done < repos.txt

rm repos.txt
