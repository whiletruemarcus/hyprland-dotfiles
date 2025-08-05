#!/bin/bash

# ========================================
# GITIGNORE VALIDATION SCRIPT
# Check and validate .gitignore patterns
# ========================================

set -e

echo "🔍 GitIgnore Validation Script"
echo "=============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_status "Validating .gitignore patterns..."

# Check for tracked files that should be ignored
print_status "Checking for tracked files that should be ignored..."
IGNORED_TRACKED=$(git ls-files -ci --exclude-standard 2>/dev/null || true)

if [[ -n "$IGNORED_TRACKED" ]]; then
    print_warning "Found tracked files that should be ignored:"
    echo "$IGNORED_TRACKED" | sed 's/^/  - /'
    echo
else
    print_success "No tracked files found that should be ignored."
fi

# Check for common patterns that might be missing
print_status "Checking for common ignore patterns..."

COMMON_PATTERNS=(
    "*.log"
    "*.tmp"
    "*.cache"
    "*.pid"
    "*.lock"
    ".DS_Store"
    "Thumbs.db"
    "*.swp"
    "*.swo"
    "*~"
    "*.bak"
    "*.backup"
    "node_modules/"
    ".env"
    "__pycache__/"
    "*.pyc"
)

MISSING_PATTERNS=()

for pattern in "${COMMON_PATTERNS[@]}"; do
    if ! grep -q "^${pattern//\*/\\*}$" .gitignore 2>/dev/null; then
        # Check if there are files matching this pattern
        if find . -name "$pattern" -type f 2>/dev/null | head -1 | grep -q .; then
            MISSING_PATTERNS+=("$pattern")
        fi
    fi
done

if [[ ${#MISSING_PATTERNS[@]} -gt 0 ]]; then
    print_warning "Consider adding these common patterns to .gitignore:"
    for pattern in "${MISSING_PATTERNS[@]}"; do
        echo "  - $pattern"
    done
    echo
fi

# Check for large files that should probably be ignored
print_status "Checking for large files (>1MB) that might need to be ignored..."
LARGE_FILES=$(find . -type f -size +1M 2>/dev/null | grep -v "^\./.git/" | head -10)

if [[ -n "$LARGE_FILES" ]]; then
    print_warning "Found large files that might need to be ignored:"
    echo "$LARGE_FILES" | while read -r file; do
        size=$(du -h "$file" 2>/dev/null | cut -f1)
        echo "  - $file ($size)"
    done
    echo
fi

# Check for sensitive file patterns
print_status "Checking for potentially sensitive files..."
SENSITIVE_PATTERNS=(
    "*.key"
    "*.pem"
    "*.p12"
    "*.pfx"
    "*password*"
    "*secret*"
    "*.env"
    "config.json"
    "credentials*"
)

SENSITIVE_FILES=()
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]] && ! git check-ignore "$file" >/dev/null 2>&1; then
            SENSITIVE_FILES+=("$file")
        fi
    done < <(find . -name "$pattern" -type f -print0 2>/dev/null)
done

if [[ ${#SENSITIVE_FILES[@]} -gt 0 ]]; then
    print_warning "Found potentially sensitive files that should be ignored:"
    for file in "${SENSITIVE_FILES[@]}"; do
        echo "  - $file"
    done
    echo
fi

# Summary
echo "================================"
print_status "Validation Summary:"

if [[ -z "$IGNORED_TRACKED" ]] && [[ ${#MISSING_PATTERNS[@]} -eq 0 ]] && [[ ${#SENSITIVE_FILES[@]} -eq 0 ]]; then
    print_success "Your .gitignore appears to be well configured!"
else
    print_warning "Consider reviewing the warnings above to improve your .gitignore."
fi

# Show .gitignore statistics
TOTAL_PATTERNS=$(grep -c "^[^#]" .gitignore 2>/dev/null || echo "0")
COMMENT_LINES=$(grep -c "^#" .gitignore 2>/dev/null || echo "0")

echo
print_status ".gitignore Statistics:"
echo "  - Total ignore patterns: $TOTAL_PATTERNS"
echo "  - Comment lines: $COMMENT_LINES"
echo "  - Total lines: $(wc -l < .gitignore)"