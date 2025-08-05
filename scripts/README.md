# Git Maintenance Scripts

This directory contains scripts to help maintain your git repository and .gitignore file.

## Scripts

### 🧹 `git-cleanup.sh`
**Purpose**: Remove files from git tracking that should be ignored according to .gitignore

**Usage**:
```bash
./scripts/git-cleanup.sh
```

**What it does**:
- Scans for files currently tracked in git that match .gitignore patterns
- Shows you a list of files that will be removed from tracking
- Asks for confirmation before making changes
- Removes files from git tracking (files remain on disk)
- Shows you the staged changes ready to commit

**Example output**:
```
🧹 Git Repository Cleanup Script
=================================
[INFO] Checking for files that should be ignored...

[WARNING] Found the following tracked files that should be ignored:
  - gtk-3.0/colors.css
  - gtk-4.0/settings.ini

Do you want to remove these files from git tracking? (y/N): y
```

### 🔍 `validate-gitignore.sh`
**Purpose**: Validate and analyze your .gitignore file effectiveness

**Usage**:
```bash
./scripts/validate-gitignore.sh
```

**What it checks**:
- Files currently tracked that should be ignored
- Common ignore patterns that might be missing
- Large files that might need to be ignored
- Potentially sensitive files
- .gitignore statistics

**Example output**:
```
🔍 GitIgnore Validation Script
==============================
[INFO] Validating .gitignore patterns...
[SUCCESS] No tracked files found that should be ignored.
[WARNING] Consider adding these common patterns to .gitignore:
  - *.pyc
```

## Common Workflow

1. **After adding new patterns to .gitignore**:
   ```bash
   # Add patterns to .gitignore
   echo "new-directory/" >> .gitignore
   
   # Clean up tracked files that should now be ignored
   ./scripts/git-cleanup.sh
   
   # Commit the changes
   git add .gitignore
   git commit -m "Add new-directory/ to .gitignore and remove from tracking"
   ```

2. **Regular maintenance**:
   ```bash
   # Check if your .gitignore is working well
   ./scripts/validate-gitignore.sh
   
   # Clean up any issues found
   ./scripts/git-cleanup.sh
   ```

## Technical Details

### Why the fix was needed
The original script used `git ls-files -i --exclude-standard` which requires either `-o` (show untracked files) or `-c` (show cached/tracked files). Since we want to find tracked files that should be ignored, we use `-ci` (cached + ignored).

### Commands used
- `git ls-files -ci --exclude-standard` - List tracked files that match .gitignore patterns
- `git rm --cached <file>` - Remove file from git tracking but keep on disk
- `git check-ignore <file>` - Check if a file would be ignored

## Safety Features

- **Confirmation prompts**: Scripts ask before making changes
- **Dry-run capability**: Shows what will be changed before doing it
- **Non-destructive**: Files are only removed from git tracking, not deleted from disk
- **Error handling**: Scripts handle edge cases and provide helpful error messages