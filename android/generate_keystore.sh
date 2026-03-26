#!/bin/bash

# Script to generate a signing keystore for release builds
# Usage: bash generate_keystore.sh

set -e

KEYSTORE_FILE="release.keystore"
KEYSTORE_PASSWORD="dailathon_2024_secure_key"
KEY_ALIAS="dailathon_dialer_release"
KEY_PASSWORD="dailathon_2024_secure_key"
DAYS_VALID=36500  # 100 years
KEYTOOL=$(which keytool || echo "keytool")

echo "Generating signing keystore..."
echo "This keystore will be used to sign APK/AAB for Play Store"
echo ""

# Check if keytool exists
if ! command -v $KEYTOOL &> /dev/null; then
    echo "ERROR: keytool not found. Ensure Java/Android SDK is installed."
    exit 1
fi

# Generate keystore only if it doesn't exist
if [ -f "$KEYSTORE_FILE" ]; then
    echo "WARNING: Keystore already exists at $KEYSTORE_FILE"
    read -p "Continue and overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Generate the keystore
$KEYTOOL -genkey -v \
    -keystore "$KEYSTORE_FILE" \
    -storetype PKCS12 \
    -storepass "$KEYSTORE_PASSWORD" \
    -keyalg RSA \
    -keysize 2048 \
    -validityDays $DAYS_VALID \
    -alias "$KEY_ALIAS" \
    -keypass "$KEY_PASSWORD" \
    -dname "CN=Dailathon Dialer,O=Dailathon,L=India,ST=India,C=IN"

echo ""
echo "✓ Keystore generated successfully!"
echo ""
echo "Keystore Details:"
echo "  File: $KEYSTORE_FILE"
echo "  Keystore Password: $KEYSTORE_PASSWORD"
echo "  Key Alias: $KEY_ALIAS"
echo "  Key Password: $KEY_PASSWORD"
echo "  Validity: $DAYS_VALID days"
echo ""
echo "Next steps:"
echo "1. Update signing.properties with the passwords above"
echo "2. Keep $KEYSTORE_FILE SECURE (add to .gitignore)"
echo "3. Run: ./gradlew bundleRelease"
echo ""
