#!/bin/bash

# ========================================
# GIT CLEANUP SCRIPT
# Remove files from git that should be ignored
# ========================================

set -e

echo "🧹 Git Repository Cleanup Script"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository!"
    exit 1
fi

# Check if .gitignore exists
if [[ ! -f .gitignore ]]; then
    print_error ".gitignore file not found!"
    exit 1
fi

print_status "Checking for files that should be ignored..."

# Find files that are tracked but should be ignored
IGNORED_FILES=$(git ls-files -ci --exclude-standard 2>/dev/null || true)

if [[ -z "$IGNORED_FILES" ]]; then
    print_success "No tracked files found that should be ignored!"
    exit 0
fi

echo
print_warning "Found the following tracked files that should be ignored:"
echo "$IGNORED_FILES" | sed 's/^/  - /'
echo

# Ask for confirmation
read -p "Do you want to remove these files from git tracking? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Operation cancelled."
    exit 0
fi

# Remove files from git tracking
print_status "Removing files from git tracking..."

echo "$IGNORED_FILES" | while IFS= read -r file; do
    if [[ -n "$file" ]]; then
        print_status "Removing: $file"
        git rm --cached "$file" 2>/dev/null || print_warning "Could not remove: $file"
    fi
done

# Check if there are changes to commit
if git diff --cached --quiet; then
    print_success "No changes to commit."
else
    print_status "Files removed from tracking. You can now commit these changes:"
    echo
    echo "  git commit -m \"Remove ignored files from tracking\""
    echo
    print_status "Staged changes:"
    git diff --cached --name-only | sed 's/^/  - /'
fi

print_success "Cleanup completed!"

# Optional: Show current status
echo
print_status "Current git status:"
git status --short