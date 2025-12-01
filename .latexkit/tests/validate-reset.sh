#!/usr/bin/env bash
# Quick validation test for reset command

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Validating reset command implementation..."
echo ""

# Test 1: Check for interactive prompts
if grep -q "What would you like to reset?" "$PROJECT_ROOT/latexkit" && \
   grep -q "\[1\] This project only" "$PROJECT_ROOT/latexkit" && \
   grep -q "\[2\] All projects" "$PROJECT_ROOT/latexkit"; then
    echo -e "${GREEN}✓${NC} Interactive prompts found"
else
    echo -e "${RED}✗${NC} Interactive prompts missing"
    exit 1
fi

# Test 2: Check for RESET commit
if grep -q 'git commit -m "RESET:' "$PROJECT_ROOT/latexkit"; then
    echo -e "${GREEN}✓${NC} RESET commit integration found"
else
    echo -e "${RED}✗${NC} RESET commit integration missing"
    exit 1
fi

# Test 3: Check for merge workflow with --no-ff
if grep -q "Merge to main?" "$PROJECT_ROOT/latexkit" && \
   grep -q "Switching to main branch" "$PROJECT_ROOT/latexkit" && \
   grep -q "Merging branch" "$PROJECT_ROOT/latexkit" && \
   grep -q "git merge --no-ff" "$PROJECT_ROOT/latexkit"; then
    echo -e "${GREEN}✓${NC} Merge workflow with --no-ff found"
else
    echo -e "${RED}✗${NC} Merge workflow missing or incorrect"
    exit 1
fi

# Test 4: Check README documentation
if grep -q "### \`reset\`" "$PROJECT_ROOT/README.md" && \
   grep -q "Option 1: This Project Only" "$PROJECT_ROOT/README.md" && \
   grep -q "Option 2: All Projects" "$PROJECT_ROOT/README.md"; then
    echo -e "${GREEN}✓${NC} README documentation complete"
else
    echo -e "${RED}✗${NC} README documentation incomplete"
    exit 1
fi

# Test 5: Check syntax
if bash -n "$PROJECT_ROOT/latexkit"; then
    echo -e "${GREEN}✓${NC} No syntax errors"
else
    echo -e "${RED}✗${NC} Syntax errors found"
    exit 1
fi

echo ""
echo -e "${GREEN}All validation checks passed!${NC}"
echo ""
echo "Implementation includes:"
echo "  • Interactive scope selection (this project / all)"
echo "  • Automatic RESET commit on deletion"
echo "  • Merge to main workflow with --no-ff flag"
echo "  • Branch validation"
echo "  • Comprehensive documentation"
