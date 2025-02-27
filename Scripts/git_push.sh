#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Change to project root
cd "$PROJECT_ROOT"

echo "🔍 Checking git status..."

# Check if there are any changes
if [[ -z $(git status --porcelain) ]]; then
    echo "✨ No changes to commit!"
    exit 0
fi

# Show changes to be committed
echo "📝 Changes detected:"
git status --short

# Ask for confirmation
read -p "❓ Do you want to commit and push these changes? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "🚫 Operation cancelled"
    exit 1
fi

# Ask for commit message
echo "📝 Enter commit message:"
read -r commit_message

if [[ -z "$commit_message" ]]; then
    echo "❌ Commit message cannot be empty"
    exit 1
fi

# Add all changes
echo "📦 Adding changes..."
git add .

# Commit changes
echo "💾 Committing changes..."
git commit -m "$commit_message"

# Get current branch
current_branch=$(git symbolic-ref --short HEAD)

# Push changes
echo "🚀 Pushing to $current_branch..."
git push origin "$current_branch"

echo "✅ Push complete!" 