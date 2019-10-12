#!/bin/sh

set -e

printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"

# Build the project.
hugo

# Add changes to git
cd public
git add .

msg="Rebuild site $(date)"
if [ -n "$*" ]; then
	msg="$*"
fi
git commit -m "$msg"
