#!/bin/bash

set -e

echo "🔍 Debugging YAML files..."

for file in .github/workflows/*.yml; do
    if [[ -f "$file" ]]; then
        echo "=== Checking $file ==="
        
        # Check for tabs
        if grep -q $'\t' "$file"; then
            echo "❌ Contains tabs (use spaces instead)"
            grep -n $'\t' "$file"
        fi
        
        # Check indentation
        if grep -E '^[ ]{1,3}[^ ]' "$file" | grep -vE '^[ ]{2}|^[ ]{4}|^[ ]{6}|^[ ]{8}' | grep -v '^---' | grep -v '^\.\.\.'; then
            echo "⚠️  Possible indentation issues"
        fi
        
        # Validate YAML syntax
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" >/dev/null 2>&1; then
            echo "✅ Valid YAML"
        else
            echo "❌ Invalid YAML"
            python3 -c "import yaml; yaml.safe_load(open('$file'))"
            exit 1
        fi
        echo ""
    fi
done

echo "✅ All YAML files checked"