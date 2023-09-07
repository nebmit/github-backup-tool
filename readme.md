# GitHub Repository Backup Script

This script automates the backup process for GitHub repositories. It fetches a list of repositories for a user and their organizations and then mirrors (or updates if they are already mirrored) each of them to a specified backup directory.

## Prerequisites

- **jq**: A lightweight and flexible command-line JSON processor.
- **Git**: Required for the clone and update operations.
- **Curl**: Used for making API calls to GitHub.

Ensure these tools are installed and accessible in your `$PATH`.

## Configuration

### Personal Access Token (PAT)

To use the GitHub API, you need to generate a Personal Access Token. Here's how:

1. Visit the GitHub documentation on [Managing Your Personal Access Tokens](https://docs.github.com/en/enterprise-server@3.10/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens).
2. Follow the guide to create a new token.
3. Ensure you grant the following permission for the token:
   - **repo**: Full control of private repositories
4. Save your generated token securely. You'll use this as the `GITHUB_TOKEN` environment variable.

You can also directly visit [this link](https://github.com/settings/tokens) to manage or create new tokens.

### Environment Variables

Set up the script using the following environment variables:

- `GITHUB_TOKEN`: Your GitHub personal access token. Essential for API access.
- `BACKUP_DEST_DIR`: The directory to backup repositories. Defaults to `backup/`.
- `BACKUP_LOG_PATH`: Path for the log file. Defaults to `BACKUP_DEST_DIR/backup.log`.

These variables can also be stored in a `.env` file in the same directory as the script:

```env
GITHUB_TOKEN=your_token_here
BACKUP_DEST_DIR=/path/to/backup
BACKUP_LOG_PATH=/path/to/log
```

## Usage

1. Make sure the script has execute permissions:

```bash
chmod +x backup.sh
```
2. Run the script:

```bash
./backup.sh
```

If executed successfully, the script will backup all repositories of the user and their associated organizations to the chosen directory. The script logs any issues encountered during the process.

## Interacting with Mirrored Repositories

While mirrored repositories are primarily used for backup purposes, you might find the need to interact with them directly.

Below examples are for this repository, which is mirrored to the default `backup` folder. Replace the paths with your own.

### 1. **Checking Out a Specific Branch or Tag:**
   
Mirrored repositories are "bare" and do not have a working directory. So, if you want to check out files from a specific branch or tag, you would first need to create a non-bare clone from the mirror:

```bash
git clone backup/github-backup-tool.git
cd github-backup-tool/
git checkout main
```

### 2. **Browsing Commits and Logs:**

You can inspect the logs of a mirrored repo without creating a working directory:

```bash
git --git-dir=backup/github-backup-tool.git log
```

### 3. **Restoring a Repository to a remote:**

If you ever need to restore or push a mirrored backup to GitHub (or another remote):

1. Create an empty repository on GitHub (or the remote of your choice).
2. Push the mirrored repository to the new remote repository:

```bash
cd backup/github-backup-tool.git
git push --mirror https://github.com/your-username/github-backup-tool.git
```

## Notes

**While you can technically make commits directly in the working directory created from the mirrored repo (as in point 1), it's not the primary use case for such backups. If you wish to continue development, consider pushing it to a remote (like GitHub) and then cloning that repository for a more standard Git workflow.**

The script interfaces with GitHub's API, which might have rate limits. Ensure your token has the right permissions, and be mindful of the number of API requests, particularly if you have many repositories.

