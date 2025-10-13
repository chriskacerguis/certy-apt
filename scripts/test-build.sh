#!/bin/bash
# Test script to verify build-deb.sh works correctly
# This creates a mock binary for testing without downloading from GitHub

set -e

echo "================================"
echo "Testing build-deb.sh script"
echo "================================"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Clean any previous test artifacts
echo "Cleaning previous test artifacts..."
rm -rf build/
mkdir -p build/

# Create a mock binary that responds to --version and -h
echo "Creating mock Certy binary..."
cat > build/certy-amd64 <<'MOCKEOF'
#!/bin/bash
case "$1" in
    --version|-version)
        echo "certy version 1.1.0-test (commit abc1234)"
        ;;
    -h|-help|--help)
        cat <<'HELPEOF'
Usage: certy [options] [domain/email/IP...]

Options:
  -install          Initialize the CA infrastructure
  -uninstall        Remove the CA from system trust store
  -client           Generate a client authentication certificate
  -ecdsa            Use ECDSA instead of RSA for key generation
  -pkcs12           Generate a PKCS#12 (.p12) file
  -p12-password     Set password for PKCS#12 file
  -p12-file         Custom path for PKCS#12 file
  -csr              Generate certificate from CSR file
  -cert-file        Custom path for certificate file
  -key-file         Custom path for private key file
  -ca-dir           Custom directory for CA files
  -CAROOT           Print the CA root directory

Examples:
  certy -install
  certy example.com
  certy example.com "*.example.com" 127.0.0.1
  certy user@example.com
  certy -client client.example.com
HELPEOF
        ;;
    *)
        echo "Mock certy binary for testing"
        ;;
esac
MOCKEOF

chmod +x build/certy-amd64

echo "✓ Mock binary created"
echo ""

# Test the mock binary
echo "Testing mock binary responses..."
echo "  Version output:"
build/certy-amd64 --version | head -1
echo "  Help output (first 3 lines):"
build/certy-amd64 -h | head -3
echo "✓ Mock binary works"
echo ""

# Run the build script
echo "Running build-deb.sh..."
./scripts/build-deb.sh v1.1.0 amd64

# Verify the package was created
if [ -f "build/certy_1.1.0_amd64.deb" ]; then
    echo ""
    echo "✓ Package created successfully!"
    echo ""
    
    # Show package information
    echo "Package details:"
    dpkg-deb --info build/certy_1.1.0_amd64.deb | head -20
    echo ""
    
    # Check man page exists
    if dpkg-deb --contents build/certy_1.1.0_amd64.deb | grep -q "man/man1/certy.1.gz"; then
        echo "✓ Man page included in package"
    else
        echo "✗ Man page missing from package"
        exit 1
    fi
    
    # Extract and verify man page content
    echo ""
    echo "Extracting man page to verify content..."
    dpkg-deb --fsys-tarfile build/certy_1.1.0_amd64.deb | \
        tar xOf - ./usr/share/man/man1/certy.1.gz | \
        gunzip | head -20
    
    # Check for dynamic content
    echo ""
    echo "Checking for dynamically generated content..."
    MAN_CONTENT=$(dpkg-deb --fsys-tarfile build/certy_1.1.0_amd64.deb | \
        tar xOf - ./usr/share/man/man1/certy.1.gz | gunzip)
    
    if echo "$MAN_CONTENT" | grep -q "\\-install"; then
        echo "✓ Man page contains -install option"
    fi
    
    if echo "$MAN_CONTENT" | grep -q "\\-ecdsa"; then
        echo "✓ Man page contains -ecdsa option"
    fi
    
    if echo "$MAN_CONTENT" | grep -q "\\-pkcs12"; then
        echo "✓ Man page contains -pkcs12 option"
    fi
    
    echo ""
    echo "================================"
    echo "✓ ALL TESTS PASSED!"
    echo "================================"
    echo ""
    echo "Package: build/certy_1.1.0_amd64.deb"
    echo "Size: $(du -h build/certy_1.1.0_amd64.deb | cut -f1)"
    
else
    echo ""
    echo "✗ ERROR: Package not created!"
    echo ""
    ls -la build/
    exit 1
fi

# Cleanup instructions
echo ""
echo "To clean up test artifacts:"
echo "  rm -rf build/"
