#!/bin/bash

# Script to update vendored libfswatch source code
# Usage: ./tools/update_libfswatch.sh [version/commit/tag]
#
# This script reproduces how to get the current vendored code from the 
# upstream libfswatch repository and applies necessary patches for R package use.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
FSWATCH_REPO="https://github.com/emcrisostomo/fswatch.git"
FSWATCH_VERSION="${1:-master}"  # Default to master branch if no version specified
WORK_DIR="$(pwd)/fswatch-update-tmp"
TARGET_DIR="$(pwd)/src/fswatch"

echo -e "${GREEN}=== LibFSWatch Update Script ===${NC}"
echo "Repository: ${FSWATCH_REPO}"
echo "Version/Commit: ${FSWATCH_VERSION}"
echo "Target directory: ${TARGET_DIR}"
echo ""

# Check if target directory exists
if [ ! -d "${TARGET_DIR}" ]; then
  echo -e "${RED}Error: Target directory ${TARGET_DIR} does not exist${NC}"
  exit 1
fi

# Step 1: Clone the fswatch repository
echo -e "${YELLOW}Step 1: Cloning fswatch repository...${NC}"
rm -rf "${WORK_DIR}"
git clone --depth 1 --branch "${FSWATCH_VERSION}" "${FSWATCH_REPO}" "${WORK_DIR}" 2>/dev/null || \
  git clone "${FSWATCH_REPO}" "${WORK_DIR}"

cd "${WORK_DIR}"

# If a specific commit was requested, check it out
if [ "${FSWATCH_VERSION}" != "master" ] && ! git rev-parse --verify "${FSWATCH_VERSION}" >/dev/null 2>&1; then
  echo -e "${YELLOW}Checking out ${FSWATCH_VERSION}...${NC}"
  git checkout "${FSWATCH_VERSION}" || {
    echo -e "${RED}Error: Could not checkout ${FSWATCH_VERSION}${NC}"
    exit 1
  }
fi

# Show what version we're at
CURRENT_COMMIT=$(git rev-parse HEAD)
CURRENT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "no tag")
echo -e "${GREEN}Current commit: ${CURRENT_COMMIT}${NC}"
echo -e "${GREEN}Current tag: ${CURRENT_TAG}${NC}"
echo ""

# Step 2: Extract only the needed files
echo -e "${YELLOW}Step 2: Extracting required files...${NC}"

# Create temporary staging directory
STAGING_DIR="${WORK_DIR}/staging"
mkdir -p "${STAGING_DIR}"

# Copy the files we need (excluding fswatch CLI tool, tests, and build infrastructure)
echo "Copying libfswatch source files..."
cp -r libfswatch "${STAGING_DIR}/"

# Copy top-level files needed for the build
cp CMakeLists.txt "${STAGING_DIR}/"
cp AUTHORS "${STAGING_DIR}/"
cp AUTHORS.libfswatch "${STAGING_DIR}/"
cp LICENSE-2.0.txt "${STAGING_DIR}/"
cp README.md "${STAGING_DIR}/"

# Remove unnecessary files from libfswatch
echo "Cleaning up unnecessary files..."
rm -rf "${STAGING_DIR}/libfswatch/doc"
find "${STAGING_DIR}" -name "Makefile.am" -delete

echo ""

# Step 3: Apply patches specific to watcher package
echo -e "${YELLOW}Step 3: Applying patches for watcher package...${NC}"

# Patch 1: Fix Windows latency issue (use std::this_thread::sleep_for instead of sleep)
# Note: Future versions may include this fix upstream (PR #340 was merged to master)
echo "Applying Windows latency fix..."
WINDOWS_MONITOR="${STAGING_DIR}/libfswatch/src/libfswatch/c++/windows_monitor.cpp"

if [ -f "${WINDOWS_MONITOR}" ]; then
  # Add required headers if not present
  if ! grep -q "include <thread>" "${WINDOWS_MONITOR}"; then
    sed -i.bak '/^#  include <cstdio>/a\
#  include <thread>\
#  include <chrono>
' "${WINDOWS_MONITOR}"
    rm -f "${WINDOWS_MONITOR}.bak"
  fi
  
  # Replace sleep() with std::this_thread::sleep_for (only if not already patched)
  if grep -q "sleep(latency)" "${WINDOWS_MONITOR}"; then
    sed -i.bak 's/sleep(latency)/std::this_thread::sleep_for(std::chrono::milliseconds((long long) (latency * 1000)))/' "${WINDOWS_MONITOR}"
    rm -f "${WINDOWS_MONITOR}.bak"
    echo -e "${GREEN}  ✓ Windows latency fix applied${NC}"
  else
    echo -e "${GREEN}  ✓ Windows latency fix already present${NC}"
  fi
else
  echo -e "${YELLOW}  ⚠ windows_monitor.cpp not found, skipping patch${NC}"
fi

echo ""

# Step 4: Replace vendored code
echo -e "${YELLOW}Step 4: Updating vendored code...${NC}"
rm -rf "${TARGET_DIR}"
mv "${STAGING_DIR}" "${TARGET_DIR}"
echo -e "${GREEN}Vendored code updated successfully!${NC}"
echo ""

# Step 5: Clean up
echo -e "${YELLOW}Step 5: Cleaning up...${NC}"
cd "$(dirname "${WORK_DIR}")"
rm -rf "${WORK_DIR}"
echo -e "${GREEN}Temporary files removed${NC}"
echo ""

# Step 6: Show summary
echo -e "${GREEN}=== Update Complete ===${NC}"
echo ""
echo "Summary:"
echo "  - Updated from commit: ${CURRENT_COMMIT}"
echo "  - Updated from tag: ${CURRENT_TAG}"
echo "  - Patches applied: Windows latency fix"
echo ""
