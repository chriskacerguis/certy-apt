# Testing the APT Repository

This guide covers testing the APT repository locally and in CI/CD.

## Local Testing

### Prerequisites

```bash
# Install required tools
sudo apt-get update
sudo apt-get install -y dpkg-dev debhelper devscripts fakeroot gnupg
```

### Building a Package Locally

```bash
# Clone the repository
git clone https://github.com/chriskacerguis/certy-apt.git
cd certy-apt

# Create build directory
mkdir -p build

# Download a Certy binary (example for v1.1.0)
VERSION="v1.1.0"
curl -L -o build/certy-amd64 \
    "https://github.com/chriskacerguis/certy/releases/download/$VERSION/certy-linux-amd64"
chmod +x build/certy-amd64

# Build the package
./scripts/build-deb.sh "$VERSION" amd64

# Verify the package
dpkg-deb --info build/certy_1.1.0_amd64.deb
dpkg-deb --contents build/certy_1.1.0_amd64.deb
```

### Testing Package Installation

```bash
# Install the package
sudo dpkg -i build/certy_1.1.0_amd64.deb

# Test the installation
certy --version
which certy

# Check post-installation scripts ran
ls -l /usr/bin/certy

# Uninstall
sudo apt-get remove certy
```

### Testing Repository Structure

```bash
# Create repository structure
mkdir -p dists/stable/main/binary-amd64
mkdir -p pool/main/c/certy

# Copy package
cp build/certy_1.1.0_amd64.deb pool/main/c/certy/

# Generate repository metadata
cd dists/stable/main/binary-amd64
dpkg-scanpackages -m ../../../../pool/main/c/certy /dev/null > Packages
gzip -k -f Packages

# Verify Packages file
cat Packages
```

## Docker Testing

Create a test environment with Docker:

```bash
# Create a Dockerfile for testing
cat > Dockerfile.test <<'EOF'
FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y curl gnupg ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /test

CMD ["/bin/bash"]
EOF

# Build test image
docker build -f Dockerfile.test -t certy-apt-test .

# Run container
docker run -it --rm -v $(pwd):/test certy-apt-test

# Inside container, test installation
# (Assuming you have the repository hosted locally or on GitHub Pages)
curl -fsSL https://YOUR_USERNAME.github.io/certy-apt/KEY.gpg | \
    gpg --dearmor -o /usr/share/keyrings/certy-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/certy-archive-keyring.gpg arch=amd64] https://YOUR_USERNAME.github.io/certy-apt stable main" > /etc/apt/sources.list.d/certy.list

apt-get update
apt-get install -y certy
certy --version
```

## Testing Multiple Distributions

Test on different Ubuntu/Debian versions:

```bash
# Test on Ubuntu 20.04
docker run -it --rm ubuntu:20.04 bash

# Test on Ubuntu 22.04
docker run -it --rm ubuntu:22.04 bash

# Test on Debian 11
docker run -it --rm debian:11 bash

# Test on Debian 12
docker run -it --rm debian:12 bash
```

## Automated Testing Script

Create a test script:

```bash
cat > test-installation.sh <<'EOF'
#!/bin/bash
set -e

REPO_URL="${1:-https://chriskacerguis.github.io/certy-apt}"

echo "Testing APT repository: $REPO_URL"

# Add repository
echo "Adding repository..."
curl -fsSL "$REPO_URL/KEY.gpg" | \
    gpg --dearmor -o /usr/share/keyrings/certy-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/certy-archive-keyring.gpg arch=amd64] $REPO_URL stable main" > \
    /etc/apt/sources.list.d/certy.list

# Update package list
echo "Updating package list..."
apt-get update

# Install certy
echo "Installing certy..."
apt-get install -y certy

# Test installation
echo "Testing installation..."
certy --version

if [ $? -eq 0 ]; then
    echo "✓ Installation test passed"
else
    echo "✗ Installation test failed"
    exit 1
fi

# Test basic functionality
echo "Testing basic functionality..."
certy -CAROOT

if [ $? -eq 0 ]; then
    echo "✓ Functionality test passed"
else
    echo "✗ Functionality test failed"
    exit 1
fi

# Clean up
echo "Cleaning up..."
apt-get remove -y certy
rm /etc/apt/sources.list.d/certy.list
rm /usr/share/keyrings/certy-archive-keyring.gpg

echo "✓ All tests passed!"
EOF

chmod +x test-installation.sh

# Run tests
docker run -it --rm ubuntu:22.04 bash -c "
    apt-get update && apt-get install -y curl gnupg ca-certificates && \
    $(cat test-installation.sh)
"
```

## Package Quality Checks

### Linting Package Structure

```bash
# Install lintian
sudo apt-get install lintian

# Check package for issues
lintian build/certy_1.1.0_amd64.deb

# Check with verbose output
lintian -v build/certy_1.1.0_amd64.deb

# Check with all tags
lintian -I build/certy_1.1.0_amd64.deb
```

### Verifying Package Contents

```bash
# List all files in the package
dpkg-deb --contents build/certy_1.1.0_amd64.deb

# Extract package for inspection
dpkg-deb --extract build/certy_1.1.0_amd64.deb extracted/
dpkg-deb --control build/certy_1.1.0_amd64.deb extracted/DEBIAN/

# Check file permissions
ls -lR extracted/

# Verify scripts
cat extracted/DEBIAN/postinst
cat extracted/DEBIAN/prerm
```

### Checking Dependencies

```bash
# Show package dependencies
dpkg-deb --field build/certy_1.1.0_amd64.deb Depends

# Test if dependencies are available
apt-cache show <dependency-name>
```

## GPG Signing Tests

```bash
# Verify repository signature
cd dists/stable

# Check InRelease
gpg --verify InRelease

# Check Release.gpg
gpg --verify Release.gpg Release

# Check key is in Release
gpg --verify --status-fd 1 InRelease | grep GOODSIG
```

## Repository Metadata Tests

```bash
# Validate Packages file structure
cat dists/stable/main/binary-amd64/Packages

# Check for required fields
grep -q "Package: certy" dists/stable/main/binary-amd64/Packages
grep -q "Version:" dists/stable/main/binary-amd64/Packages
grep -q "Architecture:" dists/stable/main/binary-amd64/Packages

# Validate Release file
cat dists/stable/Release

# Check checksums
cd dists/stable
md5sum -c <(grep -A 100 "MD5Sum:" Release | grep "main/" | awk '{print $1 "  " $3}')
```

## GitHub Actions Testing

Test the workflow locally with [act](https://github.com/nektos/act):

```bash
# Install act
# macOS: brew install act
# Linux: See https://github.com/nektos/act#installation

# Run the workflow locally
act workflow_dispatch -s GPG_PRIVATE_KEY="..." -s GPG_KEY_ID="..." -s GPG_PASSPHRASE="..."

# Test specific job
act -j build-packages
```

## Continuous Testing

Set up automated tests in GitHub Actions:

```yaml
# .github/workflows/test.yml
name: Test Repository

on:
  pull_request:
  push:
    branches: [main]

jobs:
  test-package-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install dependencies
        run: sudo apt-get install -y dpkg-dev lintian
      
      - name: Download binary
        run: |
          mkdir -p build
          curl -L -o build/certy-amd64 \
            https://github.com/chriskacerguis/certy/releases/latest/download/certy-linux-amd64
          chmod +x build/certy-amd64
      
      - name: Build package
        run: ./scripts/build-deb.sh v1.1.0 amd64
      
      - name: Lint package
        run: lintian build/*.deb
      
      - name: Verify package contents
        run: dpkg-deb --contents build/*.deb
```

## Troubleshooting Tests

### Package Won't Install

```bash
# Check dependencies
dpkg -I build/certy_1.1.0_amd64.deb | grep Depends

# Try installing with --force
sudo dpkg -i --force-depends build/certy_1.1.0_amd64.deb

# Check for conflicts
dpkg -l | grep certy
```

### Repository Not Found

```bash
# Verify URL is accessible
curl -I https://YOUR_USERNAME.github.io/certy-apt/

# Check Packages file
curl https://YOUR_USERNAME.github.io/certy-apt/dists/stable/main/binary-amd64/Packages

# Verify sources.list entry
cat /etc/apt/sources.list.d/certy.list

# Check apt update output
sudo apt-get update -o Debug::pkgAcquire::Worker=1
```

### Signature Verification Fails

```bash
# Check if key is imported
gpg --list-keys

# Manually verify
gpg --verify dists/stable/Release.gpg dists/stable/Release

# Check key fingerprint
gpg --fingerprint YOUR_KEY_ID
```

## Performance Testing

```bash
# Time package download
time curl -O https://YOUR_USERNAME.github.io/certy-apt/pool/main/c/certy/certy_1.1.0_amd64.deb

# Time full installation
time (sudo apt-get update && sudo apt-get install -y certy)

# Check package size
ls -lh pool/main/c/certy/certy_1.1.0_amd64.deb
```

## Cleanup

```bash
# Remove test packages
rm -rf build/certy_*

# Remove test repository structure
rm -rf dists/ pool/

# Uninstall test package
sudo apt-get remove --purge certy
```

## Checklist

Before releasing:

- [ ] Package builds successfully
- [ ] Package installs on Ubuntu 20.04, 22.04
- [ ] Package installs on Debian 11, 12
- [ ] Binary is executable and works
- [ ] Lintian shows no errors
- [ ] Repository metadata is correct
- [ ] GPG signatures are valid
- [ ] GitHub Pages serves files correctly
- [ ] Installation instructions work
- [ ] Upgrade from previous version works
- [ ] Removal works without errors
