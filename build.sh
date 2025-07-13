#!/bin/bash
# DevDB CLI Build Script

set -e

echo "🏗️  Building DevDB CLI package..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/ dist/ *.egg-info/

# Build the package
echo "📦 Building package..."
python3 setup.py sdist bdist_wheel

echo "✅ Build completed!"
echo ""
echo "📋 Installation instructions:"
echo "  Local install:     pip install -e ."
echo "  From wheel:        pip install dist/devdb_cli-1.0.0-py3-none-any.whl"
echo "  From source dist:  pip install dist/devdb-cli-1.0.0.tar.gz"
echo ""
echo "🚀 Usage after installation:"
echo "  devdb init my-project"
echo "  devdb init my-project --template basic"
echo "  devdb version"