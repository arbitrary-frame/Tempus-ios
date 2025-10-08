#!/bin/bash

# Emergency Database Migration Script
# Migrates database from old Application Support location to new App Group container

set -e  # Exit on error

echo "🚨 Emergency Database Migration Script"
echo "======================================"
echo ""

# Find the app's Application Support directory
APP_SUPPORT_BASE="$HOME/Library/Developer/CoreSimulator/Devices"
APP_GROUP_BASE="$HOME/Library/Developer/CoreSimulator/Devices"

# You'll need to find these paths manually - listing them:
echo "Looking for database files in old location..."
echo ""

# Find all database files
echo "Searching for production-database.store files:"
find "$APP_SUPPORT_BASE" -name "production-database.store" 2>/dev/null | while read file; do
    echo "  Found: $file"
done

echo ""
echo "Searching for dev-database.store files:"
find "$APP_SUPPORT_BASE" -name "dev-database.store" 2>/dev/null | while read file; do
    echo "  Found: $file"
done

echo ""
echo "Searching for App Group containers:"
find "$APP_GROUP_BASE" -path "*/Group Containers/group.tempus-ios.Tempus" -type d 2>/dev/null | while read dir; do
    echo "  Found App Group: $dir"
done

echo ""
echo "======================================"
echo "MANUAL MIGRATION STEPS:"
echo "1. Locate your old database file from the list above"
echo "2. Locate the new App Group container directory"
echo "3. Copy the database file:"
echo "   cp [OLD_PATH]/production-database.store [NEW_PATH]/production-database.store"
echo ""
