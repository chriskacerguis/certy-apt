# Dynamic Package Generation

This document explains how the APT repository uses dynamic information to keep packages up-to-date with the latest Certy features.

## Overview

The packaging system now uses a **dynamic information extraction** approach that:

1. **Extracts information from the Certy binary** itself (help text, version)
2. **Fetches latest documentation** from GitHub README
3. **Automatically updates** package metadata and man pages
4. **Falls back gracefully** to static defaults if dynamic fetching fails

This means the APT packages will automatically reflect changes in Certy without manual updates to the packaging scripts.

## How It Works

### 1. Dynamic Man Page Generation

The man page is now generated dynamically in `scripts/build-deb.sh`:

```bash
# Get help output from binary
HELP_OUTPUT=$("$BUILD_DIR/usr/bin/certy" -h 2>&1 || echo "")

# Generate OPTIONS section from help
generate_man_options_from_help "$HELP_OUTPUT"
```

**Benefits:**
- New flags in Certy automatically appear in the man page
- Flag descriptions match exactly what Certy outputs
- No need to manually update documentation

### 2. Dynamic Feature Extraction

Package descriptions are populated from the GitHub README:

```bash
# Fetch README from GitHub
README_CONTENT=$(cache_github_data)

# Extract features
FEATURES=$(extract_features_from_readme "$README_CONTENT")
```

**Benefits:**
- Package description stays in sync with main project
- New features automatically documented
- Consistent messaging across platforms

### 3. Binary Version Detection

Version information is extracted directly from the binary:

```bash
CERTY_VERSION=$("$BUILD_DIR/usr/bin/certy" --version 2>&1 | head -1)
```

**Benefits:**
- Man page shows actual binary version
- No version mismatch between package and binary
- Automatic version string updates

## Helper Script: get-certy-info.sh

The `scripts/get-certy-info.sh` script provides reusable functions:

### Available Functions

```bash
# Source the helper
source scripts/get-certy-info.sh

# Get latest release from GitHub
VERSION=$(get_latest_release_info)

# Fetch README content
README=$(get_readme_content)

# Extract features from README
FEATURES=$(extract_features_from_readme "$README")

# Get version from binary
VERSION=$(get_binary_version "/path/to/certy")

# Get help text from binary
HELP=$(get_binary_help "/path/to/certy")

# Parse help into structured data
parse_help_output "$HELP"

# Generate man page sections
generate_man_options_from_help "$HELP"
generate_man_examples_from_readme "$README"
```

### Caching

To avoid GitHub API rate limits, the helper caches GitHub data:

```bash
# Uses cached data if less than 1 hour old
README=$(cache_github_data)
```

Cache location: `${TMPDIR}/certy-apt-cache/github_data.cache`

## Fallback Strategy

The system is designed to work even when dynamic fetching fails:

1. **Primary**: Try to fetch from binary/GitHub
2. **Fallback**: Use static defaults from templates
3. **Graceful degradation**: Build succeeds even if dynamic fetching fails

Example:
```bash
if [ -n "$HELP_OUTPUT" ]; then
    # Use dynamic help
    parse_help_output "$HELP_OUTPUT"
else
    # Fall back to static options
    echo "Using default options list"
    # ... static content ...
fi
```

## Man Page Structure

The generated man page now includes comprehensive sections:

- **NAME**: Brief description
- **SYNOPSIS**: Command syntax
- **DESCRIPTION**: Detailed overview with CA structure explanation
- **OPTIONS**: Dynamically extracted from `certy -h`
- **EXAMPLES**: Organized by use case (Basic, Email, Client, Advanced)
- **FILES**: CA and config file locations
- **ENVIRONMENT**: Environment variables (CAROOT)
- **EXIT STATUS**: Return codes
- **NOTES**: Security warnings and best practices
- **TRUSTING THE CA**: Platform-specific trust installation
- **SEE ALSO**: Related commands and documentation
- **BUGS**: Where to report issues
- **AUTHOR**: Maintainer info
- **COPYRIGHT**: License information

## Updating the Dynamic System

### Adding New Information Sources

To add a new dynamic information source:

1. Add a function to `scripts/get-certy-info.sh`:
```bash
get_new_info() {
    local source="$1"
    # Fetch and parse
    curl -s "$source" | parse_data
}
```

2. Use it in `scripts/build-deb.sh`:
```bash
if command -v get_new_info &> /dev/null; then
    NEW_INFO=$(get_new_info "$SOURCE")
    # Use $NEW_INFO
else
    # Fallback
    NEW_INFO="default value"
fi
```

3. Add fallback content in template

### Improving Parsing

Current parsing methods:

- **Simple regex**: `grep -E '^\s*-'` for flags
- **Section extraction**: `sed -n '/^## Section/,/^##[^#]/p'`
- **Markdown parsing**: Detect headers, code blocks, lists

To improve:

1. Add more sophisticated parsing for complex formats
2. Handle edge cases (unusual formatting)
3. Add validation of extracted data

### Testing Dynamic Generation

Test the dynamic system:

```bash
# Test with actual binary
./scripts/build-deb.sh v1.1.0 amd64

# Check generated man page
man -l build/certy_1.1.0_amd64/usr/share/man/man1/certy.1.gz

# Verify package description
dpkg-deb --info build/certy_1.1.0_amd64.deb

# Test with mock data
HELP_OUTPUT="Test help text" ./scripts/build-deb.sh v1.1.0 amd64
```

## Benefits of Dynamic Generation

### For Maintainers

- **Reduced maintenance**: Don't need to update packaging when Certy changes
- **Always accurate**: Documentation matches actual binary behavior
- **Consistent**: Same source of truth for all platforms
- **Automated**: CI/CD handles updates automatically

### For Users

- **Up-to-date docs**: Man pages reflect actual binary capabilities
- **Accurate descriptions**: Package info matches what they'll get
- **Better help**: Comprehensive examples and use cases
- **Current information**: Latest features and options documented

## Troubleshooting

### Man Page Not Updating

Check if dynamic extraction is working:

```bash
# Enable debug output
set -x
./scripts/build-deb.sh v1.1.0 amd64

# Check if helper is loaded
grep "Loaded dynamic info helper" build.log

# Verify binary is accessible
./build/certy-amd64 -h
```

### Features Not Showing

Check GitHub fetch:

```bash
# Test fetch manually
source scripts/get-certy-info.sh
README=$(get_readme_content)
echo "$README" | grep "## Features"

# Check cache
ls -la ${TMPDIR}/certy-apt-cache/

# Test with cache disabled
rm -rf ${TMPDIR}/certy-apt-cache/
./scripts/build-deb.sh v1.1.0 amd64
```

### Rate Limiting

If you hit GitHub API rate limits:

```bash
# Check rate limit status
curl -s https://api.github.com/rate_limit

# Use authenticated requests (higher limit)
export GITHUB_TOKEN="your_token"
# Modify get-certy-info.sh to use token

# Increase cache TTL
# Edit get-certy-info.sh: cache_ttl=7200  # 2 hours
```

## Future Enhancements

Possible improvements:

1. **Multi-language man pages**: Generate translations
2. **Release notes integration**: Pull changelog from GitHub releases
3. **Screenshot/examples**: Embed visual examples in documentation
4. **Compatibility matrix**: Auto-generate platform support info
5. **Benchmark data**: Include performance metrics
6. **API documentation**: Generate from code comments

## Configuration

### Customizing Dynamic Behavior

Environment variables for control:

```bash
# Disable dynamic fetching (use only static defaults)
export CERTY_APT_STATIC_ONLY=1

# Increase cache TTL (in seconds)
export CERTY_APT_CACHE_TTL=7200

# Use custom GitHub repo
export CERTY_GITHUB_REPO="yourusername/certy-fork"

# Use custom README URL
export CERTY_README_URL="https://example.com/custom-readme.md"
```

### Template Variables

Available template variables:

- `@VERSION@`: Package version (replaced in control file)
- `@ARCH@`: Target architecture
- `@FEATURES@`: Dynamic features list
- `${CERTY_VERSION}`: Binary version (man page)
- `$(date ...)`: Build date

## Best Practices

1. **Always test locally** before pushing
2. **Check fallback paths** work
3. **Validate extracted data** format
4. **Keep cache reasonable** (avoid disk bloat)
5. **Document new variables** in templates
6. **Test offline behavior** (no network)
7. **Monitor GitHub API usage** (stay under limits)

## Examples

### Custom Feature Extraction

```bash
# In build-deb.sh
CUSTOM_FEATURES=$(echo "$README_CONTENT" | 
    sed -n '/^## Key Features/,/^##[^#]/p' |
    grep -E '^\*' |
    sed 's/^* /  ✓ /')
```

### Enhanced Version Info

```bash
# Get commit hash from binary
COMMIT=$("$BINARY" --version 2>&1 | grep -o '[0-9a-f]\{7\}')
BUILD_DATE=$("$BINARY" --version 2>&1 | grep -o '20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]')
```

### Conditional Sections

```bash
# Only include advanced examples if binary supports them
if "$BINARY" -h 2>&1 | grep -q "\-pkcs12"; then
    generate_pkcs12_examples
fi
```

## Related Files

- `scripts/build-deb.sh`: Main build script with dynamic generation
- `scripts/get-certy-info.sh`: Helper functions library
- `debian/control.template`: Package metadata template
- `.github/workflows/build-and-publish.yml`: CI/CD automation

## References

- [Debian Man Page Format](https://www.debian.org/doc/manuals/debian-reference/ch12.en.html)
- [GitHub API Rate Limiting](https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting)
- [Debian Control File Format](https://www.debian.org/doc/debian-policy/ch-controlfields.html)
