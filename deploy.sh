#!/bin/sh

set -e

printf "\033[0;32m>>> Rebuilding website...\033[0m\n"

# Build the project.
hugo

printf "\033[0;32m>>> Deploying updates to GitHub...\033[0m\n"

# Add changes to git
cd public
git add .

msg="Rebuild site $(date)"
if [ -n "$*" ]; then
	msg="$*"
fi
git commit -m "$msg"

git push origin gh-pages
