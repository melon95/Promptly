#!/usr/bin/env bash

# install-strict-commit-hook.sh
# Install strict commit message validation

echo "🔧 Installing strict commit message validation hook..."

# Check if we're in a Git repository
if [ ! -d ".git" ]; then
    echo "❌ This is not a Git repository. Please run this script in your project root."
    exit 1
fi

# Create strict commit-msg hook
cat > .git/hooks/commit-msg << 'EOF'
#!/usr/bin/env bash

# Strict commit message validation
# Fully compliant with Conventional Commits specification

commit_message=$(cat "$1")
first_line=$(echo "$commit_message" | head -n1)

# Strict regular expression
commit_regex='^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\([a-z0-9\-]+\))?: [a-z].{0,49}[^.]$'

# Type definitions - compatible with bash 3.x
valid_types="feat fix docs style refactor test chore perf ci build revert"

get_type_desc() {
    case $1 in
        feat) echo "A new feature" ;;
        fix) echo "A bug fix" ;;
        docs) echo "Documentation only changes" ;;
        style) echo "Changes that do not affect the meaning of the code" ;;
        refactor) echo "A code change that neither fixes a bug nor adds a feature" ;;
        test) echo "Adding missing tests or correcting existing tests" ;;
        chore) echo "Changes to the build process or auxiliary tools" ;;
        perf) echo "A code change that improves performance" ;;
        ci) echo "Changes to our CI configuration files and scripts" ;;
        build) echo "Changes that affect the build system or external dependencies" ;;
        revert) echo "Reverts a previous commit" ;;
        *) echo "Unknown type" ;;
    esac
}

# Error message
error_msg="❌ Commit message format error!

📝 Required format: <type>(<scope>): <subject>

🔖 Allowed types:"
for type in $valid_types; do
    error_msg="$error_msg
  $type: $(get_type_desc $type)"
done

error_msg="$error_msg

📏 Rules:
  • Subject must start with lowercase letter
  • Subject length: 1-50 characters
  • No period at the end
  • Use imperative mood (e.g., 'add' not 'added' or 'adds')
  • Scope (optional) must be lowercase alphanumeric with hyphens

✅ Valid examples:
  feat(auth): add user authentication
  fix(ui): resolve button alignment issue
  docs: update installation guide
  style: format code according to style guide
  refactor(api): extract validation logic
  test: add unit tests for user service
  chore: update dependencies
  perf(db): optimize query performance
  ci: add automated testing workflow
  build: update Xcode project settings
  revert: revert commit abc123

❌ Invalid examples:
  Added new feature          (wrong format)
  feat: Add new feature      (subject should start with lowercase)
  fix(UI): resolve issue     (scope should be lowercase)
  docs: update guide.        (no period at the end)
  feature: add login         (invalid type)
  fix: this is a very long subject that exceeds the maximum allowed length  (too long)

📝 Your commit message:
$first_line"

# Check basic format
if ! echo "$first_line" | grep -qE "$commit_regex"; then
    echo "$error_msg" >&2
    echo ""
    echo "💡 Need help? Run: git commit --help"
    echo "🔧 To bypass this check (not recommended): git commit --no-verify"
    exit 1
fi

# Extract type
type=$(echo "$first_line" | sed -n 's/^\([a-z]*\).*$/\1/p')

# Validate if type is valid
type_valid=false
for valid_type in $valid_types; do
    if [ "$type" = "$valid_type" ]; then
        type_valid=true
        break
    fi
done

if [ "$type_valid" = false ]; then
    echo "❌ Invalid commit type: '$type'" >&2
    echo "" >&2
    echo "🔖 Allowed types:" >&2
    for valid_type in $valid_types; do
        echo "  $valid_type: $(get_type_desc $valid_type)" >&2
    done
    exit 1
fi

# Check subject length
subject=$(echo "$first_line" | sed -n 's/^[^:]*: \(.*\)$/\1/p')
subject_length=${#subject}

if [ $subject_length -eq 0 ]; then
    echo "❌ Subject cannot be empty" >&2
    exit 1
fi

if [ $subject_length -gt 50 ]; then
    echo "❌ Subject too long: $subject_length characters (max 50)" >&2
    echo "📝 Subject: $subject" >&2
    exit 1
fi

# Check if subject starts with lowercase letter
if ! echo "$subject" | grep -q '^[a-z]'; then
    echo "❌ Subject must start with lowercase letter" >&2
    echo "📝 Subject: $subject" >&2
    echo "💡 Example: 'add user authentication' not 'Add user authentication'" >&2
    exit 1
fi

# Check if subject ends with period
if echo "$subject" | grep -q '\.$'; then
    echo "❌ Subject should not end with a period" >&2
    echo "📝 Subject: $subject" >&2
    exit 1
fi

# Check total message length
if [ ${#first_line} -gt 72 ]; then
    echo "❌ First line too long: ${#first_line} characters (max 72)" >&2
    echo "📝 Consider using a scope or shortening the subject" >&2
    exit 1
fi

# Check scope format (if exists)
if echo "$first_line" | grep -q '('; then
    scope=$(echo "$first_line" | sed -n 's/^[^(]*(\([^)]*\)).*$/\1/p')
    if ! echo "$scope" | grep -qE '^[a-z0-9\-]+$'; then
        echo "❌ Scope must be lowercase alphanumeric with hyphens only" >&2
        echo "📝 Scope: $scope" >&2
        echo "💡 Example: 'auth', 'user-profile', 'api-v2'" >&2
        exit 1
    fi
fi

# Check if imperative mood is used (simple check)
imperative_violations=("added" "fixed" "updated" "changed" "removed" "improved" "created" "deleted")
for violation in "${imperative_violations[@]}"; do
    if echo "$subject" | grep -qw "$violation"; then
        echo "⚠️  Consider using imperative mood: '${violation%d}' instead of '$violation'" >&2
        echo "📝 Subject: $subject" >&2
        echo "💡 Use imperative mood like Git itself: 'fix bug' not 'fixed bug'" >&2
        # This is just a warning, does not prevent commit
        break
    fi
done

echo "✅ Commit message format is valid"
echo "📋 Type: $type ($(get_type_desc $type))"
echo "📝 Subject: $subject ($subject_length chars)"
exit 0
EOF

# Make hooks executable
chmod +x .git/hooks/commit-msg

echo "✅ Commit message validation hook installed successfully!"
echo ""
echo "🎯 Features enabled:"
echo "   • ✅ Strict commit message validation"
echo "   • ✅ Conventional Commits enforcement"
echo "   • ✅ Detailed error messages with examples"
echo ""
echo "📋 Valid commit examples:"
echo "   feat(auth): add user authentication"
echo "   fix(ui): resolve button alignment issue"
echo "   docs: update installation guide"
echo "   test: add unit tests for user service"
echo ""
echo "🔧 To bypass checks (emergency only): git commit --no-verify"
echo "💡 For help: The hook will show detailed error messages"