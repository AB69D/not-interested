#!/usr/bin/env bash
# Run this script ONCE to generate your release signing keystore.
# Keep the generated .jks file secure — never commit it to git.
# After running, follow the printed instructions to add secrets to GitHub.
set -euo pipefail

KEYSTORE_FILE="not_interested_release.jks"
KEY_ALIAS="not_interested"

echo "================================================"
echo "  Not Interested — Release Keystore Generator"
echo "================================================"
echo ""
echo "You will be prompted to enter a password TWICE:"
echo "  1. Store password  (protects the .jks file)"
echo "  2. Key password    (protects the key inside; use the SAME password)"
echo ""
echo "Pick a strong password and write it down — you'll need it later."
echo ""

keytool -genkey -v \
  -keystore "$KEYSTORE_FILE" \
  -alias "$KEY_ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -dname "CN=Not Interested, OU=App, O=YonderChat, L=Unknown, ST=Unknown, C=BD"

KEYSTORE_B64=$(base64 -i "$KEYSTORE_FILE")

echo ""
echo "================================================"
echo "  SUCCESS — now add these secrets to GitHub:"
echo "  Repo → Settings → Secrets → Actions → New"
echo "================================================"
echo ""
echo "Secret 1 — Name: KEYSTORE_BASE64"
echo "Value (copy everything between the lines):"
echo "----"
echo "$KEYSTORE_B64"
echo "----"
echo ""
echo "Secret 2 — Name: KEY_ALIAS"
echo "Value: $KEY_ALIAS"
echo ""
echo "Secret 3 — Name: KEY_PASSWORD"
echo "Value: (the password you just entered)"
echo ""
echo "Secret 4 — Name: STORE_PASSWORD"
echo "Value: (same password)"
echo ""
echo "After adding the secrets, delete this .jks file from your machine"
echo "or move it somewhere safe (NOT inside the project folder)."
echo ""
echo "To create a release: git tag v1.0.0 && git push origin v1.0.0"
