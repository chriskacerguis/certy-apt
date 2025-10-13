# Dynamic Man Page Update Summary

## Changes Made

The APT repository now uses **dynamic information extraction** to automatically keep package documentation synchronized with Certy as it evolves.

## What Changed

### 1. Enhanced build-deb.sh Script

**File**: `scripts/build-deb.sh`

**Changes**:
- Sources helper script for dynamic functions
- Extracts version info from Certy binary: `certy --version`
- Extracts help text from binary: `certy -h`
- Fetches features from GitHub README
- Generates comprehensive man page dynamically
- Falls back gracefully to static defaults if dynamic fetching fails

**Benefits**:
- Man page OPTIONS section auto-generated from `certy -h`
- Package descriptions stay in sync with main project
- No manual updates needed when Certy adds/changes flags

### 2. New Helper Script

**File**: `scripts/get-certy-info.sh`

**Purpose**: Reusable functions for extracting dynamic information

**Key Functions**:
- `get_binary_version()` - Extract version from binary
- `get_binary_help()` - Get help text from binary
- `get_readme_content()` - Fetch README from GitHub
- `extract_features_from_readme()` - Parse features section
- `cache_github_data()` - Cache GitHub data (1-hour TTL)
- `generate_man_options_from_help()` - Create man page OPTIONS from help
- `parse_help_output()` - Structure help text data

**Benefits**:
- Reusable across scripts
- Caching prevents rate limiting
- Extensible for future needs

### 3. Updated control.template

**File**: `debian/control.template`

**Changes**:
- Added `@FEATURES@` placeholder
- Features now populated dynamically from GitHub README
- Falls back to sensible defaults if GitHub unavailable

**Benefits**:
- Package descriptions auto-update
- Consistent with main project documentation

### 4. Comprehensive New Man Page

The generated man page now includes:

- **Dynamic OPTIONS**: From `certy -h` output
- **Organized EXAMPLES**: Basic, Email, Client, Advanced sections
- **FILES**: Complete CA directory structure
- **ENVIRONMENT**: CAROOT variable documentation
- **EXIT STATUS**: Return code meanings
- **NOTES**: Security warnings and best practices
- **TRUSTING THE CA**: Platform-specific instructions
- **SEE ALSO**: Related commands
- **BUGS**: Issue reporting location
- **COPYRIGHT**: Full license information

### 5. New Documentation

**File**: `docs/DYNAMIC_GENERATION.md`

**Content**:
- How dynamic generation works
- Available helper functions
- Fallback strategies
- Troubleshooting guide
- Customization options
- Best practices

### 6. Updated README and QUICKREF

**Files**: `README.md`, `QUICKREF.md`

**Changes**:
- Added dynamic generation section
- Documented new helper script
- Added testing instructions
- Explained benefits to maintainers and users

## How It Works

### Build Process

```
1. Download Certy binary
   ↓
2. Extract version: certy --version
   ↓
3. Extract help: certy -h
   ↓
4. Fetch README from GitHub (cached)
   ↓
5. Parse features from README
   ↓
6. Generate man page with extracted info
   ↓
7. Populate package description
   ↓
8. Build .deb package
```

### Example: Adding New Flag to Certy

**Before** (manual update required):
1. Certy adds `-new-flag` option
2. Must manually edit `build-deb.sh` to add flag to man page
3. Must update package description
4. Must coordinate updates

**After** (automatic):
1. Certy adds `-new-flag` option with help text
2. Next package build automatically includes new flag
3. Man page shows correct description from help
4. No manual intervention needed

## Testing

### Test Dynamic Extraction

```bash
# Build with dynamic extraction
./scripts/build-deb.sh v1.1.0 amd64

# View generated man page
man -l build/certy_1.1.0_amd64/usr/share/man/man1/certy.1.gz

# Check package description
dpkg-deb --info build/certy_1.1.0_amd64.deb
```

### Test Helper Functions

```bash
# Source helper script
source scripts/get-certy-info.sh

# Test version extraction
get_binary_version build/certy-amd64

# Test help extraction
get_binary_help build/certy-amd64

# Test GitHub fetch
get_readme_content
```

### Test Fallback

```bash
# Build without network (tests fallback)
unset -f get_readme_content
./scripts/build-deb.sh v1.1.0 amd64

# Should still build successfully with static defaults
```

## Benefits

### For Maintainers
- ✅ **Reduced maintenance**: No manual doc updates
- ✅ **Always accurate**: Docs match actual binary
- ✅ **Automated**: CI/CD handles everything
- ✅ **Extensible**: Easy to add new dynamic sources

### For Users
- ✅ **Current documentation**: Man pages always up-to-date
- ✅ **Accurate info**: Package descriptions match reality
- ✅ **Better help**: Comprehensive examples and options
- ✅ **Consistent**: Same info across all platforms

## Backwards Compatibility

- ✅ Fallback ensures builds work even without dynamic sources
- ✅ Static defaults maintained for offline builds
- ✅ No changes to package format or installation
- ✅ Existing workflows continue to work

## Future Enhancements

Possible additions:
- Parse examples from README for man page
- Extract configuration options dynamically
- Generate multi-language man pages
- Pull changelog from GitHub releases
- Add benchmark/performance data
- Generate compatibility matrix

## Files Modified/Created

### Modified
- `scripts/build-deb.sh` - Enhanced with dynamic generation
- `debian/control.template` - Added @FEATURES@ placeholder
- `README.md` - Added dynamic generation section
- `QUICKREF.md` - Added testing and usage info

### Created
- `scripts/get-certy-info.sh` - Helper functions library
- `docs/DYNAMIC_GENERATION.md` - Technical documentation
- `docs/DYNAMIC_UPDATE_SUMMARY.md` - This file

## Migration Path

No migration needed! The changes are:
1. **Backward compatible**: Fallbacks ensure existing builds work
2. **Transparent**: Users see no breaking changes
3. **Gradual**: Benefits appear automatically on next build

## Support

For issues or questions:
- See `docs/DYNAMIC_GENERATION.md` for technical details
- Check `QUICKREF.md` for quick testing commands
- Open an issue with debug output if problems occur

## Validation Checklist

- [x] Dynamic man page generation from binary help
- [x] Feature extraction from GitHub README
- [x] Version detection from binary
- [x] Graceful fallback to static defaults
- [x] Caching to avoid rate limits
- [x] Comprehensive documentation
- [x] Testing procedures documented
- [x] Backward compatibility maintained
- [x] Helper script created and tested
- [x] README and QUICKREF updated

## Summary

The APT repository now intelligently extracts information from Certy itself and GitHub, ensuring packages always reflect the latest capabilities without manual intervention. This reduces maintenance burden while improving accuracy and consistency for users.
