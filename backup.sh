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

CRON_COMMAND="$PWD/$0"

mkdir -p "$DEST_DIR"

# Function to log messages
log_message() {
    echo "$(date): $1" >> "$LOG_PATH"
}

# Helper function to exit script with error message
error_exit() {
    log_message "$1"
    exit 1
}

# Function to remove any existing cron jobs for this script
remove_existing_cron() {
    (crontab -l 2>/dev/null | grep -v "$CRON_COMMAND") | crontab -
}

# Check if a scheduling argument is provided
if [ "$1" == "--schedule" ]; then
    if [ -z "$2" ]; then
        echo "Please provide an interval for the schedule. Supported formats: Xmin, Xh, Xd, Xw, Xm (where X is a number)."
        exit 1
    fi

    # Remove any existing cron jobs for this script
    remove_existing_cron

    # Determine the cron interval based on the provided format
    case $2 in
        *min)
            NUMBER=${2%min}
            CRON_INTERVAL="*/$NUMBER * * * *"
            ;;
        *h)
            NUMBER=${2%h}
            CRON_INTERVAL="0 */$NUMBER * * *"
            ;;
        *d)
            NUMBER=${2%d}
            CRON_INTERVAL="0 0 */$NUMBER * *"
            ;;
        *w)
            NUMBER=${2%w}
            CRON_INTERVAL="0 0 * * $(($NUMBER + 1))"
            ;;
        *m)
            NUMBER=${2%m}
            CRON_INTERVAL="0 0 1 */$NUMBER *"
            ;;
        *)
            echo "Invalid interval format."
            exit 1
            ;;
    esac

    # Add the new cron job
    echo "$CRON_INTERVAL $CRON_COMMAND" | crontab -

    echo "Scheduled to run with an interval of $2."
    exit 0
fi

# Check if a stop argument is provided
if [ "$1" == "--stop" ]; then
    # Remove any existing cron jobs for this script
    remove_existing_cron
    echo "Stopped any scheduled runs of this script."
    exit 0
fi

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
