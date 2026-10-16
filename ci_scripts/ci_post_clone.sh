#!/bin/sh
# Xcode Cloud runs this after cloning. Secrets.xcconfig is git-ignored,
# so rebuild it from the workflow's environment variables.
set -eu

for name in SUPABASE_URL SUPABASE_ANON_KEY FACEBOOK_APP_ID DEVELOPMENT_TEAM; do
  eval "value=\${$name:-}"
  if [ -z "$value" ]; then
    echo "error: $name is not set in the Xcode Cloud workflow" >&2
    exit 1
  fi
done

# xcconfig treats "//" as a comment, so split it with $() like Secrets.example.xcconfig
supabase_url=$(printf '%s' "$SUPABASE_URL" | sed 's#//#/$()/#')

cat > "$CI_PRIMARY_REPOSITORY_PATH/Config/Secrets.xcconfig" <<EOF
SUPABASE_URL = $supabase_url
SUPABASE_ANON_KEY = $SUPABASE_ANON_KEY
FACEBOOK_APP_ID = $FACEBOOK_APP_ID
DEVELOPMENT_TEAM = $DEVELOPMENT_TEAM
EOF

echo "Wrote Config/Secrets.xcconfig"

# Package.resolved is written by the local (older) Xcode. Re-resolve with
# Xcode Cloud's Xcode so the build doesn't reject it as out of date.
xcodebuild -resolvePackageDependencies \
  -project "$CI_PRIMARY_REPOSITORY_PATH/TwentyFour.xcodeproj" \
  -scheme TwentyFour
