#!/usr/bin/env bash
# Inserts arbitrary derives after every matching serde cfg_attr line.
# Idempotent — skips files that already have the rkyv attribute.
# Usage: ./arbitrary.sh              (runs in current directory)
#        ./arbitrary.sh path/to/src  (runs in given directory)

set -euo pipefail

ROOT="${1:-.}"

find "$ROOT" -name "*.rs" -type f | while read -r file; do
    if grep -qF 'feature = "arbitrary-derive"' "$file"; then
        echo "skip (already patched): $file"
        continue
    fi

    if ! grep -qF '#[cfg_attr(feature = "serde", derive(Serialize, Deserialize))]' "$file"; then
        continue
    fi

    perl -i -pe '
        if (/^(\s*)#\[cfg_attr\(feature = "serde", derive\(Serialize, Deserialize\)\)\]/) {
            my $indent = $1;
            $_ .= "${indent}#[cfg_attr(feature = \"arbitrary-derive\", derive(arbitrary::Arbitrary))]\n";
        }
    ' "$file"

    echo "patched: $file"
done
