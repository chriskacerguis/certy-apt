#!/bin/bash
set -e

# Script to build a .deb package for certy
# Usage: ./build-deb.sh <version> <architecture>

VERSION=${1:-"v1.1.0"}
ARCH=${2:-"amd64"}

# Remove 'v' prefix for Debian version
DEB_VERSION="${VERSION#v}"

# Get script directory for sourcing helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source helper functions for dynamic info (optional - fallback to static if not available)
if [ -f "$SCRIPT_DIR/get-certy-info.sh" ]; then
    source "$SCRIPT_DIR/get-certy-info.sh"
    echo "Loaded dynamic info helper"
fi

echo "Building certy ${VERSION} for ${ARCH}..."

# Create build directory structure
BUILD_DIR="build/certy_${DEB_VERSION}_${ARCH}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/share/doc/certy"
mkdir -p "$BUILD_DIR/usr/share/man/man1"

# Copy binary
if [ ! -f "build/certy-${ARCH}" ]; then
    echo "Error: Binary build/certy-${ARCH} not found"
    echo "Please download it first"
    exit 1
fi

cp "build/certy-${ARCH}" "$BUILD_DIR/usr/bin/certy"
chmod +x "$BUILD_DIR/usr/bin/certy"

# Try to fetch dynamic features from GitHub README (with fallback)
FEATURES=""
if command -v get_readme_content &> /dev/null; then
    echo "Fetching dynamic features from GitHub..."
    README_CONTENT=$(cache_github_data 2>/dev/null || echo "")
    
    if [ -n "$README_CONTENT" ]; then
        # Extract features section
        FEATURES=$(echo "$README_CONTENT" | sed -n '/^## Features/,/^##[^#]/p' | \
            grep -E '^\*|^•|^-' | \
            sed 's/^[*•-] */  * /' | \
            head -10)
    fi
fi

# Fallback to default features if dynamic fetch failed
if [ -z "$FEATURES" ]; then
    echo "Using default features list"
    FEATURES=" Features:
  * Simple CA Management: Create and manage a root CA with intermediate CA
  * Multiple Certificate Types: TLS server, client authentication, and S/MIME
  * Smart Input Detection: Automatically detects domains, IPs, and emails
  * ECDSA Support: Generate certificates with ECDSA keys
  * PKCS#12 Export: Create .p12/.pfx files for legacy compatibility
  * CSR Support: Generate certificates from existing CSRs
  * No Dependencies: Single binary with no external runtime dependencies"
fi

# Generate control file with dynamic features
cat debian/control.template | \
    sed "s/@VERSION@/${DEB_VERSION}/g" | \
    sed "s/@ARCH@/${ARCH}/g" > "$BUILD_DIR/DEBIAN/control.tmp"

# Replace @FEATURES@ with actual features (handling multiline)
# Use a temporary file to avoid awk multiline issues
echo "$FEATURES" > "$BUILD_DIR/DEBIAN/features.tmp"

# Use sed to replace @FEATURES@ with the content of features.tmp
sed '/@FEATURES@/ {
    r '"$BUILD_DIR"'/DEBIAN/features.tmp
    d
}' "$BUILD_DIR/DEBIAN/control.tmp" > "$BUILD_DIR/DEBIAN/control"

rm -f "$BUILD_DIR/DEBIAN/control.tmp" "$BUILD_DIR/DEBIAN/features.tmp"

# Copy maintainer scripts
cp debian/postinst "$BUILD_DIR/DEBIAN/"
cp debian/prerm "$BUILD_DIR/DEBIAN/"
chmod +x "$BUILD_DIR/DEBIAN/postinst"
chmod +x "$BUILD_DIR/DEBIAN/prerm"

# Create changelog
cat > "$BUILD_DIR/usr/share/doc/certy/changelog" <<EOF
certy (${DEB_VERSION}) stable; urgency=medium

  * Release ${VERSION}
  * See https://github.com/chriskacerguis/certy/releases/tag/${VERSION}

 -- Chris Kacerguis <chris@chriskacerguis.com>  $(date -R)
EOF

gzip -9 -n "$BUILD_DIR/usr/share/doc/certy/changelog"

# Create copyright file
cat > "$BUILD_DIR/usr/share/doc/certy/copyright" <<EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: certy
Upstream-Contact: Chris Kacerguis <chris@chriskacerguis.com>
Source: https://github.com/chriskacerguis/certy

Files: *
Copyright: 2024-2025 Chris Kacerguis
License: MIT

License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a
 copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included
 in all copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
EOF

# Generate dynamic man page by extracting help from the binary
echo "Generating dynamic man page from binary..."

# Get help output from the binary
HELP_OUTPUT=$("$BUILD_DIR/usr/bin/certy" -h 2>&1 || echo "")

# Extract version if available
CERTY_VERSION=$("$BUILD_DIR/usr/bin/certy" --version 2>&1 | head -1 || echo "certy ${DEB_VERSION}")

# Generate man page with dynamic content
cat > "$BUILD_DIR/usr/share/man/man1/certy.1" <<'MANEOF'
.TH CERTY 1 "$(date '+%B %Y')" "${CERTY_VERSION}" "User Commands"
.SH NAME
certy \- Simple Certificate Authority CLI
.SH SYNOPSIS
.B certy
[\fIOPTIONS\fR] [\fIDOMAINS/IPs/EMAILs\fR...]
.SH DESCRIPTION
Certy is a lightweight, user-friendly command-line tool for managing your own
Certificate Authority and generating certificates for development and testing.
.PP
It is designed as a modern replacement for mkcert, with additional features
including intermediate CA support, S/MIME certificates, client authentication
certificates, PKCS#12 export, and CSR support.
MANEOF

# Parse help output to extract options dynamically
if [ -n "$HELP_OUTPUT" ]; then
    cat >> "$BUILD_DIR/usr/share/man/man1/certy.1" <<'MANEOF'
.SH OPTIONS
MANEOF
    
    # Extract flags from help output
    echo "$HELP_OUTPUT" | grep -E '^\s*-' | while IFS= read -r line; do
        # Parse flag and description
        FLAG=$(echo "$line" | sed -E 's/^\s*(-[a-zA-Z0-9-]+).*/\1/')
        DESC=$(echo "$line" | sed -E 's/^\s*-[a-zA-Z0-9-]+\s+//')
        
        if [ -n "$FLAG" ]; then
            cat >> "$BUILD_DIR/usr/share/man/man1/certy.1" <<FLAGEOF
.TP
.B ${FLAG}
${DESC}
FLAGEOF
        fi
    done
else
    # Fallback to common flags if help output not available
    cat >> "$BUILD_DIR/usr/share/man/man1/certy.1" <<'MANEOF'
.SH OPTIONS
.TP
.B \-install
Initialize the CA infrastructure (one-time setup)
.TP
.B \-uninstall
Remove the CA from the system trust store
.TP
.B \-client
Generate a client authentication certificate
.TP
.B \-ecdsa
Use ECDSA instead of RSA for key generation
.TP
.B \-pkcs12
Generate a PKCS#12 (.p12) file
.TP
.B \-p12-password \fIpassword\fR
Set password for PKCS#12 file (default: no password)
.TP
.B \-p12-file \fIfile\fR
Custom path for the PKCS#12 file
.TP
.B \-csr \fIfile\fR
Generate certificate from a Certificate Signing Request file
.TP
.B \-cert-file \fIfile\fR
Custom path for the certificate file
.TP
.B \-key-file \fIfile\fR
Custom path for the private key file
.TP
.B \-ca-dir \fIdir\fR
Custom directory for CA files
.TP
.B \-CAROOT
Print the CA root directory path
.TP
.B \-version, \-\-version
Print version information
.TP
.B \-h, \-help, \-\-help
Print usage information
MANEOF
fi

# Add examples section
cat >> "$BUILD_DIR/usr/share/man/man1/certy.1" <<'MANEOF'
.SH EXAMPLES
.SS Basic Usage
.TP
Initialize the CA infrastructure:
.nf
.B certy -install
.fi
.TP
Generate a TLS certificate for a single domain:
.nf
.B certy example.com
.fi
.TP
Generate a TLS certificate for multiple domains and IPs:
.nf
.B certy example.com "*.example.com" localhost 127.0.0.1 ::1
.fi
.SS Email Certificates
.TP
Generate an S/MIME certificate (automatically detected from email):
.nf
.B certy user@example.com
.fi
.TP
Generate S/MIME with PKCS#12 export:
.nf
.B certy -pkcs12 user@example.com
.fi
.SS Client Certificates
.TP
Generate a client authentication certificate:
.nf
.B certy -client client.example.com
.fi
.SS Advanced Options
.TP
Use ECDSA instead of RSA:
.nf
.B certy -ecdsa example.com
.fi
.TP
Generate PKCS#12 with password protection:
.nf
.B certy -pkcs12 -p12-password "MySecurePass" example.com
.fi
.TP
Custom output paths:
.nf
.B certy -cert-file ./certs/server.pem -key-file ./certs/server-key.pem example.com
.fi
.TP
Use custom CA directory:
.nf
.B certy -ca-dir /path/to/ca example.com
.fi
.TP
Generate certificate from CSR:
.nf
.B certy -csr request.csr -cert-file signed.pem
.fi
.SH FILES
.TP
.B ~/.certy/
Default directory for CA files and certificates
.TP
.B ~/.certy/rootCA.pem
Root CA certificate
.TP
.B ~/.certy/rootCA-key.pem
Root CA private key
.TP
.B ~/.certy/intermediateCA.pem
Intermediate CA certificate
.TP
.B ~/.certy/intermediateCA-key.pem
Intermediate CA private key
.TP
.B ~/.certy/config.yml
Configuration file with default settings
.TP
.B ~/.certy/serial.txt
Serial number tracker for certificates
.SH ENVIRONMENT
.TP
.B CAROOT
Alternative location for CA files. Can be set to override the default ~/.certy/ directory.
Useful for managing multiple CAs or team shared CA directories.
.SH EXIT STATUS
.TP
.B 0
Success
.TP
.B 1
General error (invalid arguments, CA not found, etc.)
.SH NOTES
.PP
\fBSecurity Warning:\fR This tool is designed for development and testing purposes.
It intentionally prioritizes simplicity over security. CA private keys are not
password protected, and all private keys are stored in plain text.
.PP
\fBDo not use this for production certificates or security-critical applications.\fR
.PP
The certificate chain follows best practices:
.nf
  Root CA (self-signed, 10 years)
    └── Intermediate CA (signed by root, 5 years)
        └── End-entity certificates (signed by intermediate, 1 year)
.fi
.SH TRUSTING THE CA
To trust certificates generated by certy, add the root CA to your system's trust store:
.SS macOS
.nf
sudo security add-trusted-cert -d -r trustRoot -k \\
    /Library/Keychains/System.keychain ~/.certy/rootCA.pem
.fi
.SS Linux (Debian/Ubuntu)
.nf
sudo cp ~/.certy/rootCA.pem /usr/local/share/ca-certificates/certy-root-ca.crt
sudo update-ca-certificates
.fi
.SS Windows
.nf
certutil -addstore -f "ROOT" %USERPROFILE%\\.certy\\rootCA.pem
.fi
.SH SEE ALSO
.BR openssl (1),
.BR update-ca-certificates (8)
.PP
Full documentation: <https://github.com/chriskacerguis/certy>
.SH BUGS
Report bugs at: <https://github.com/chriskacerguis/certy/issues>
.SH AUTHOR
Chris Kacerguis <chris@chriskacerguis.com>
.SH COPYRIGHT
Copyright \(co 2024-2025 Chris Kacerguis. MIT License.
.PP
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
MANEOF

# Substitute variables in the man page
sed -i.bak "s/\${CERTY_VERSION}/${CERTY_VERSION}/g" "$BUILD_DIR/usr/share/man/man1/certy.1"
sed -i.bak "s/\$(date '+%B %Y')/$(date '+%B %Y')/g" "$BUILD_DIR/usr/share/man/man1/certy.1"
rm -f "$BUILD_DIR/usr/share/man/man1/certy.1.bak"

echo "Man page generated successfully"

gzip -9 -n "$BUILD_DIR/usr/share/man/man1/certy.1"

# Calculate installed size (in KB)
INSTALLED_SIZE=$(du -sk "$BUILD_DIR" | cut -f1)
echo "Installed-Size: $INSTALLED_SIZE" >> "$BUILD_DIR/DEBIAN/control"

# Build the package
dpkg-deb --build "$BUILD_DIR"

# The output is already at $BUILD_DIR.deb which is build/certy_VERSION_ARCH.deb
# No need to move, just verify it exists
if [ ! -f "$BUILD_DIR.deb" ]; then
    echo "Error: Package file not created"
    exit 1
fi

echo "Package built successfully: $BUILD_DIR.deb"

# Clean up
rm -rf "$BUILD_DIR"

# Show package info
echo ""
echo "Package information:"
dpkg-deb --info "$BUILD_DIR.deb"
