# Quick Reference Guide

## For Repository Maintainers

### Initial Setup

1. **Generate GPG Key** (see [docs/GPG_SETUP.md](docs/GPG_SETUP.md))
   ```bash
   gpg --full-generate-key
   gpg --armor --export-secret-keys KEY_ID > private-key.asc
   base64 -w 0 private-key.asc > private-key-base64.txt
   ```

2. **Add GitHub Secrets**
   - `GPG_PRIVATE_KEY` (base64-encoded)
   - `GPG_KEY_ID` (40-char key ID)
   - `GPG_PASSPHRASE` (your passphrase)

3. **Enable GitHub Pages**
   - Settings → Pages → Source: "GitHub Actions"

4. **Run First Build**
   - Actions → "Build and Publish APT Repository" → Run workflow
   - Enter version (e.g., `v1.1.0`)

### Common Tasks

#### Manually Trigger Package Build

```bash
# Via GitHub UI
Actions → Build and Publish APT Repository → Run workflow → Enter version

# Via GitHub CLI
gh workflow run build-and-publish.yml -f version=v1.1.0
```

#### Build Package Locally

```bash
# Download binary
VERSION="v1.1.0"
mkdir -p build
curl -L -o build/certy-amd64 \
  "https://github.com/chriskacerguis/certy/releases/download/$VERSION/certy-linux-amd64"
chmod +x build/certy-amd64

# Build package (automatically extracts info from binary and GitHub)
./scripts/build-deb.sh "$VERSION" amd64

# Test installation
sudo dpkg -i build/certy_*.deb
```

#### Test Dynamic Generation

```bash
# Test with actual binary to see dynamic extraction
./scripts/build-deb.sh v1.1.0 amd64

# Check generated man page
man -l build/certy_*/usr/share/man/man1/certy.1.gz

# View package description
dpkg-deb --info build/certy_*.deb | grep -A 20 "Description"

# Test helper functions
source scripts/get-certy-info.sh
get_binary_help build/certy-amd64
```

# Test installation
sudo dpkg -i build/certy_*.deb
```

#### Update Repository Metadata

```bash
# If you manually add packages
./scripts/update-repo.sh

# Then commit and push to gh-pages
git checkout gh-pages
git add -A
git commit -m "Update repository"
git push
```

#### Check Repository Status

```bash
# View latest packages
curl https://YOUR_USERNAME.github.io/certy-apt/dists/stable/main/binary-amd64/Packages

# Verify signatures
curl -s https://YOUR_USERNAME.github.io/certy-apt/dists/stable/InRelease | gpg --verify

# Check GitHub Actions status
gh run list --workflow=build-and-publish.yml
```

---

## For End Users

### Installation

```bash
# Add repository
curl -fsSL https://chriskacerguis.github.io/certy-apt/KEY.gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/certy-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/certy-archive-keyring.gpg arch=amd64] https://chriskacerguis.github.io/certy-apt stable main" | \
  sudo tee /etc/apt/sources.list.d/certy.list

# Install
sudo apt update
sudo apt install certy
```

### Usage

```bash
# Verify installation
certy --version

# Initialize CA
certy -install

# Generate certificate
certy example.com

# See all options
certy -h
```

### Updating

```bash
# Update package list
sudo apt update

# Upgrade certy
sudo apt upgrade certy
```

### Uninstallation

```bash
# Remove package
sudo apt remove certy

# Remove repository
sudo rm /etc/apt/sources.list.d/certy.list
sudo rm /usr/share/keyrings/certy-archive-keyring.gpg
sudo apt update
```

---

## Troubleshooting

### "NO_PUBKEY" Error

```bash
# Re-import the GPG key
curl -fsSL https://chriskacerguis.github.io/certy-apt/KEY.gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/certy-archive-keyring.gpg
```

### Package Not Found

```bash
# Verify repository URL
cat /etc/apt/sources.list.d/certy.list

# Check if repository is accessible
curl -I https://chriskacerguis.github.io/certy-apt/

# Update package list
sudo apt update
```

### Permission Denied Installing Package

```bash
# Use sudo
sudo apt install certy

# Or if you have the .deb file
sudo dpkg -i certy_*.deb
```

### Binary Not Working

```bash
# Check installation
which certy
ls -l /usr/bin/certy

# Check if executable
file /usr/bin/certy
chmod +x /usr/bin/certy  # If needed

# Check architecture
dpkg --print-architecture
```

---

## File Locations

### Repository Structure

```
Main branch:
  .github/workflows/build-and-publish.yml  - GitHub Actions workflow
  debian/                                   - Package templates
  scripts/                                  - Build scripts
  docs/                                     - Documentation

gh-pages branch:
  dists/stable/                             - Repository metadata
  pool/main/c/certy/                        - .deb packages
  KEY.gpg                                   - Public GPG key
  index.html                                - Repository homepage
```

### User System

```
/etc/apt/sources.list.d/certy.list                    - Repository source
/usr/share/keyrings/certy-archive-keyring.gpg         - Repository GPG key
/usr/bin/certy                                        - Certy binary
/usr/share/doc/certy/                                 - Documentation
/usr/share/man/man1/certy.1.gz                        - Man page
```

---

## Dynamic Package Generation

The repository uses dynamic information extraction to keep packages up-to-date:

### What's Dynamic

- **Man Pages**: Generated from `certy -h` output
- **Package Descriptions**: Extracted from GitHub README
- **Version Info**: Pulled from binary itself
- **Features List**: Auto-updated from main project

### How It Works

```bash
# Helper script extracts info
source scripts/get-certy-info.sh

# From binary
get_binary_help /path/to/certy
get_binary_version /path/to/certy

# From GitHub (cached for 1 hour)
cache_github_data
get_readme_content
```

### Benefits

- **Always current**: Docs match actual binary
- **Low maintenance**: No manual updates needed
- **Consistent**: Same source across platforms
- **Graceful fallback**: Works offline with defaults

### Testing Dynamic Generation

```bash
# See what gets extracted
./scripts/build-deb.sh v1.1.0 amd64 2>&1 | grep "dynamic"

# Check man page content
zcat build/certy_*/usr/share/man/man1/certy.1.gz | less

# Verify features in package
dpkg-deb -I build/certy_*.deb | grep "Features"
```

See [docs/DYNAMIC_GENERATION.md](docs/DYNAMIC_GENERATION.md) for full details.

---

## Important Links

- **Main Certy Project**: https://github.com/chriskacerguis/certy
- **APT Repository**: https://chriskacerguis.github.io/certy-apt
- **Repository Source**: https://github.com/chriskacerguis/certy-apt
- **Issues**: https://github.com/chriskacerguis/certy-apt/issues

---

## GitHub Actions Workflow

### Triggers

- **Manual**: Actions → Run workflow
- **Scheduled**: Daily at 2 AM UTC
- **Automatic**: Push to main (workflow files only)

### Jobs

1. **check-release**: Check for new Certy releases
2. **build-packages**: Download binaries and build .deb packages
3. **publish-repository**: Update metadata, sign, and deploy

### Required Secrets

- `GPG_PRIVATE_KEY`: Base64-encoded private GPG key
- `GPG_KEY_ID`: 40-character GPG key ID
- `GPG_PASSPHRASE`: GPG key passphrase

---

## Script Reference

### build-deb.sh

```bash
./scripts/build-deb.sh <version> <architecture>
```

Builds a .deb package from a Certy binary.

**Arguments:**
- `version`: Certy version (e.g., v1.1.0)
- `architecture`: Target architecture (amd64, arm64, armhf)

**Output:** `build/certy_VERSION_ARCH.deb`

### update-repo.sh

```bash
./scripts/update-repo.sh [repository-directory]
```

Updates APT repository metadata and signs it.

**Environment Variables:**
- `GPG_KEY_ID`: GPG key to use for signing
- `GPG_PASSPHRASE`: Passphrase for GPG key

**Output:** Updates `dists/stable/` directory

---

## Configuration

### Changing Distribution Name

Edit in:
- `.github/workflows/build-and-publish.yml`
- `scripts/update-repo.sh`

Replace `stable` with your preferred name.

### Adding Architectures

Edit `.github/workflows/build-and-publish.yml`:

```yaml
strategy:
  matrix:
    arch: [amd64, arm64, armhf]
```

Ensure Certy releases include binaries for these architectures.

### Changing Component

Edit workflow and scripts to replace `main` with your component name.

---

## Best Practices

1. **Always sign packages** in production
2. **Test locally** before pushing
3. **Keep GPG keys secure** and backed up
4. **Monitor workflow runs** for failures
5. **Update documentation** when making changes
6. **Tag releases** for tracking
7. **Set key expiration** and renew periodically
8. **Use branch protection** on main and gh-pages

---

## Getting Help

1. Check documentation in `docs/`
2. Review workflow logs in Actions tab
3. Search existing issues
4. Open a new issue with details
5. Consult Debian packaging documentation

---

## Version History

- **1.0.0** (2025-10-13): Initial repository setup
  - GitHub Actions workflow
  - Package building scripts
  - Documentation
  - GPG signing support
