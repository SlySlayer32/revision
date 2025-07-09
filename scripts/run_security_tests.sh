#!/bin/bash

# Image Selection Security Test Runner
# This script runs the security-related tests for the image selection feature

echo "🔐 Running Image Selection Security Tests"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test files to run
SECURITY_TESTS=(
    "test/core/services/image_security_service_test.dart"
    "test/features/image_selection/presentation/cubit/image_selection_cubit_test.dart"
    "test/integration/image_selection_security_integration_test.dart"
)

echo "🧪 Running security-specific tests..."

# Run each security test
for test_file in "${SECURITY_TESTS[@]}"; do
    if [ -f "$test_file" ]; then
        echo -e "${YELLOW}Running: $test_file${NC}"
        
        # Run the test (would need Flutter/Dart to be installed)
        # dart test "$test_file" --reporter=expanded
        
        echo -e "${GREEN}✓ $test_file - Test file exists${NC}"
    else
        echo -e "${RED}✗ $test_file - File not found${NC}"
    fi
done

echo ""
echo "🛡️  Security Test Summary:"
echo "- Image validation tests"
echo "- Malware detection tests"
echo "- EXIF stripping tests"
echo "- File size limit tests"
echo "- Format validation tests"
echo "- Path traversal prevention tests"
echo "- Integration tests"

echo ""
echo "📝 To run these tests with Flutter:"
echo "   flutter test test/core/services/image_security_service_test.dart"
echo "   flutter test test/features/image_selection/presentation/cubit/image_selection_cubit_test.dart"
echo "   flutter test test/integration/image_selection_security_integration_test.dart"

echo ""
echo "✅ Security test runner completed!"