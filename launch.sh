#!/bin/bash
set -e

SCHEME="ClaudeShot"
PROJECT="ClaudeShot.xcodeproj"

# Kill existing instance
pkill -x "$SCHEME" 2>/dev/null || true

# Build
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug build

# Get build path and launch
BUILD_DIR=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings | grep -m1 'BUILT_PRODUCTS_DIR' | awk '{print $3}')
open "$BUILD_DIR/$SCHEME.app"
