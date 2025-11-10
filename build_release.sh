#!/bin/bash

# Build script for InplaceAI releases

set -e

VERSION=${1:-"v1.0.1"}
BUILD_DIR=".build/release"
ARCHIVE_NAME="InplaceAI-${VERSION}.tar.gz"
BINARY_NAME="InplaceAI"

echo "Building InplaceAI version $VERSION..."

# Clean previous builds
rm -rf "$BUILD_DIR"
rm -f "$ARCHIVE_NAME"

# Build for release
swift build --configuration release

# Create archive directory
mkdir -p release
cp "$BUILD_DIR/$BINARY_NAME" release/

# Create tar.gz archive
cd release
tar -czf "../$ARCHIVE_NAME" "$BINARY_NAME"
cd ..

echo "Release archive created: $ARCHIVE_NAME"
echo "SHA256: $(shasum -a 256 "$ARCHIVE_NAME" | cut -d' ' -f1)"

# Clean up
rm -rf release
