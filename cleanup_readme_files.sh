#!/bin/bash

# Script to clean up duplicate README.md files that cause build conflicts
# This script will rename all README.md files in subdirectories to MODULE_README.md

echo "🧹 Cleaning up duplicate README.md files..."

# Find all README.md files in subdirectories
find ./Sources -name "README.md" -not -path "./README.md" | while read -r file; do
    dir=$(dirname "$file")
    module=$(basename "$dir")
    new_name="${dir}/${module}_README.md"
    
    echo "📝 Renaming: $file → $new_name"
    mv "$file" "$new_name"
done

echo "✅ Cleanup complete! Run ./setup_xcode_project.sh to regenerate your Xcode project."
echo "🔍 Note: You may need to update any references to these README files in your code." 