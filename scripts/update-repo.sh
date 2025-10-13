#!/bin/bash
set -e

# Script to update APT repository metadata and sign it
# This script is typically run by GitHub Actions but can be used manually

REPO_DIR=${1:-"."}
DIST="stable"
COMPONENT="main"
ARCH="amd64"

echo "Updating APT repository metadata..."

cd "$REPO_DIR"

# Ensure directory structure exists
mkdir -p "dists/$DIST/$COMPONENT/binary-$ARCH"
mkdir -p "pool/$COMPONENT/c/certy"

# Generate Packages file
echo "Generating Packages file..."
cd "dists/$DIST/$COMPONENT/binary-$ARCH"
dpkg-scanpackages -m "../../../../pool/$COMPONENT/c/certy" /dev/null > Packages
gzip -k -f Packages

cd ../..

# Generate Release file
echo "Generating Release file..."
cat > Release <<EOF
Origin: Certy APT Repository
Label: Certy
Suite: $DIST
Codename: $DIST
Version: 1.0
Architectures: $ARCH
Components: $COMPONENT
Description: APT repository for Certy Certificate Authority CLI
Date: $(date -Ru)
EOF

# Add MD5 checksums
echo "MD5Sum:" >> Release
find "$COMPONENT" -type f -exec md5sum {} \; | sed "s|$COMPONENT/| |" | awk '{print " " $1 " " $3 " " $2}' >> Release

# Add SHA1 checksums
echo "SHA1:" >> Release
find "$COMPONENT" -type f -exec sha1sum {} \; | sed "s|$COMPONENT/| |" | awk '{print " " $1 " " $3 " " $2}' >> Release

# Add SHA256 checksums
echo "SHA256:" >> Release
find "$COMPONENT" -type f -exec sha256sum {} \; | sed "s|$COMPONENT/| |" | awk '{print " " $1 " " $3 " " $2}' >> Release

echo "Release file generated successfully"

# Sign the repository if GPG key is available
if [ -n "$GPG_KEY_ID" ]; then
    echo "Signing repository..."
    
    # Sign Release file
    gpg --default-key "$GPG_KEY_ID" \
        --batch --yes \
        ${GPG_PASSPHRASE:+--passphrase "$GPG_PASSPHRASE"} \
        ${GPG_PASSPHRASE:+--pinentry-mode loopback} \
        -abs -o Release.gpg Release
    
    # Create InRelease file
    gpg --default-key "$GPG_KEY_ID" \
        --batch --yes \
        ${GPG_PASSPHRASE:+--passphrase "$GPG_PASSPHRASE"} \
        ${GPG_PASSPHRASE:+--pinentry-mode loopback} \
        --clearsign -o InRelease Release
    
    echo "Repository signed successfully"
else
    echo "Warning: GPG_KEY_ID not set, skipping signing"
fi

cd "$REPO_DIR"

# Export public key if available
if [ -n "$GPG_KEY_ID" ]; then
    echo "Exporting public GPG key..."
    gpg --armor --export "$GPG_KEY_ID" > KEY.gpg
    echo "Public key exported to KEY.gpg"
fi

echo ""
echo "Repository metadata updated successfully!"
echo "Location: $REPO_DIR/dists/$DIST"
