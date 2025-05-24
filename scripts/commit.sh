#!/bin/bash

# Read the commit type
echo "Select commit type:"
echo "1) feat: A new feature"
echo "2) fix: A bug fix"
echo "3) docs: Documentation only changes"
echo "4) style: Changes that do not affect the meaning of the code"
echo "5) refactor: A code change that neither fixes a bug nor adds a feature"
echo "6) perf: A code change that improves performance"
echo "7) test: Adding missing tests or correcting existing tests"
echo "8) chore: Changes to the build process or auxiliary tools"
read -p "Enter number (1-8): " type_num

# Map number to commit type
case $type_num in
    1) type="feat";;
    2) type="fix";;
    3) type="docs";;
    4) type="style";;
    5) type="refactor";;
    6) type="perf";;
    7) type="test";;
    8) type="chore";;
    *) echo "Invalid selection" && exit 1;;
esac

# Read the commit message
read -p "Enter commit message: " message

# Read the issue number (optional)
read -p "Enter issue number (optional, press enter to skip): " issue

# Construct the commit message
if [ -n "$issue" ]; then
    commit_message="$type: $message (#$issue)"
else
    commit_message="$type: $message"
fi

# Create the commit
git add -A
git commit -m "$commit_message"

echo "Commit created: $commit_message"
