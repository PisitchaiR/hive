#!/usr/bin/env bash
# Release Hive — supports Git Flow two-phase release.
#
# Usage:
#   bash scripts/release.sh --prepare <version>   # bump + test + build (no commit/push)
#   bash scripts/release.sh --publish <version>   # commit + tag + push + GH release
#   bash scripts/release.sh --dry-run <version>   # validate + preview, no side-effects
#   bash scripts/release.sh <version>             # all-in-one (legacy / hotfix)
#
# Git Flow release flow:
#   1. On release/X.Y.Z branch: bash scripts/release.sh --prepare X.Y.Z
#   2. Push + PR → main, get review/merge
#   3. On main after merge: bash scripts/release.sh --publish X.Y.Z
#   4. Cherry-pick version bump commit back to develop, delete release branch

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# ── Args ──────────────────────────────────────────────────────────────────────
DRY_RUN=false
PREPARE=false
PUBLISH=false
VERSION=""

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --prepare) PREPARE=true ;;
        --publish) PUBLISH=true ;;
        *)         VERSION="$arg" ;;
    esac
done

if [ -z "$VERSION" ]; then
    echo "usage: bash scripts/release.sh [--dry-run|--prepare|--publish] <version>" >&2
    echo "  e.g. bash scripts/release.sh --prepare 0.15.0" >&2
    echo "  e.g. bash scripts/release.sh --publish 0.15.0" >&2
    echo "  e.g. bash scripts/release.sh --dry-run 0.15.0" >&2
    exit 1
fi
TAG="v${VERSION}"

# run <cmd...>  — executes normally; in dry-run prints the command instead
run() {
    if $DRY_RUN; then
        echo "  [dry-run] $*"
    else
        "$@"
    fi
}

$DRY_RUN && echo "==> DRY RUN — no files will be changed, nothing will be pushed"

# ── PUBLISH-only: commit + tag + push + GH release ────────────────────────────
if $PUBLISH; then
    echo "==> Publishing ${TAG}"

    ZIP="dist/Hive-${TAG}.zip"
    if [ ! -f "$ZIP" ]; then
        echo "error: ${ZIP} not found — run --prepare first" >&2
        exit 1
    fi

    NOTES="$(awk "/^## ${TAG}/{found=1; next} found && /^## v/{exit} found{print}" CHANGELOG.md | sed '/^[[:space:]]*$/d')"
    echo "==> Release notes preview:"
    echo "${NOTES}" | sed 's/^/  /'

    run git add Sources/HiveKit/App/AppInfo.swift
    run git commit -m "chore: bump version to ${VERSION}"
    run git tag "${TAG}"
    run git push origin main "${TAG}"

    if $DRY_RUN; then
        echo "  [dry-run] gh release create ${TAG} ${ZIP} --title ${TAG} --notes ..."
        echo "✓ Dry run complete — everything looks good for ${TAG}"
    else
        echo "==> Creating GitHub release ${TAG}"
        gh release create "${TAG}" "${ZIP}" \
            --title "${TAG}" \
            --notes "${NOTES}"
        echo ""
        echo "✓ Published ${TAG}"
        echo "  https://github.com/PisitchaiR/hive/releases/tag/${TAG}"
    fi
    exit 0
fi

# ── Steps shared by --prepare and legacy (all-in-one) ─────────────────────────

# 1. Validate CHANGELOG has an entry for this version
echo "==> Checking CHANGELOG.md for ${TAG}"
if ! grep -q "^## ${TAG}" CHANGELOG.md; then
    echo "error: no entry for ${TAG} in CHANGELOG.md" >&2
    echo "  Add '## ${TAG} — $(date +%Y-%m-%d)' and bullet points first." >&2
    exit 1
fi
echo "  ✓ CHANGELOG entry found"

# 2. Bump version in AppInfo.swift
CURRENT_VERSION="$(grep -E 'static let displayVersion' Sources/HiveKit/App/AppInfo.swift \
    | sed -E 's/.*= "([^"]+)".*/\1/')"
echo "==> Bumping displayVersion: ${CURRENT_VERSION} → ${VERSION}"
run sed -i '' \
    "s/static let displayVersion = \"[^\"]*\"/static let displayVersion = \"${VERSION}\"/" \
    Sources/HiveKit/App/AppInfo.swift

# 3. Tests
echo "==> Running tests"
run swift test

# 4. Build .app
echo "==> Building app"
run bash scripts/build-app.sh

# 5. Zip
ZIP="dist/Hive-${TAG}.zip"
echo "==> Creating ${ZIP}"
run rm -f "$ZIP"
run bash -c "cd dist && zip -r 'Hive-${TAG}.zip' Hive.app"

# ── PREPARE-only: stop here ────────────────────────────────────────────────────
if $PREPARE; then
    echo ""
    echo "✓ Prepared ${TAG} — version bumped, built, and zipped."
    echo "  Next: push branch, open PR to main, then run --publish after merge."
    exit 0
fi

# ── Legacy all-in-one: commit + tag + push + GH release ───────────────────────
NOTES="$(awk "/^## ${TAG}/{found=1; next} found && /^## v/{exit} found{print}" CHANGELOG.md | sed '/^[[:space:]]*$/d')"
echo "==> Release notes preview:"
echo "${NOTES}" | sed 's/^/  /'

echo "==> Committing and tagging ${TAG}"
run git add Sources/HiveKit/App/AppInfo.swift
run git commit -m "chore: bump version to ${VERSION}"
run git tag "${TAG}"
run git push origin main "${TAG}"

if $DRY_RUN; then
    echo ""
    echo "  [dry-run] gh release create ${TAG} ${ZIP} --title ${TAG} --notes ..."
    echo ""
    echo "✓ Dry run complete — everything looks good for ${TAG}"
else
    echo "==> Creating GitHub release ${TAG}"
    gh release create "${TAG}" "${ZIP}" \
        --title "${TAG}" \
        --notes "${NOTES}"
    echo ""
    echo "✓ Released ${TAG}"
    echo "  https://github.com/PisitchaiR/hive/releases/tag/${TAG}"
fi
