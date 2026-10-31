#!/bin/bash
# Creates the self-signed "ClipVee" code signing certificate that build-release.sh signs with.
# Signing every release with the same certificate lets macOS keep ClipVee's Accessibility
# permission across updates. The certificate holds only the name below, and its private key
# stays in your login keychain. Back it up from Keychain Access (File > Export Items).
set -euo pipefail
name="${1:-ClipVee}"

if security find-certificate -c "$name" >/dev/null 2>&1; then
  echo "A certificate named \"$name\" is already in your keychain." >&2
  exit 1
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
umask 077

cat >"$work/cert.cnf" <<EOF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $name
[ext]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
subjectKeyIdentifier = hash
EOF

/usr/bin/openssl req -x509 -newkey rsa:3072 -nodes -days 3650 -config "$work/cert.cnf" \
  -keyout "$work/key.pem" -out "$work/cert.pem" 2>/dev/null
# The bundle only exists for the moment it takes to import it, so its password is throwaway.
transfer=$(/usr/bin/openssl rand -hex 16)
/usr/bin/openssl pkcs12 -export -inkey "$work/key.pem" -in "$work/cert.pem" -name "$name" \
  -out "$work/identity.p12" -passout "pass:$transfer"
security import "$work/identity.p12" -k "$HOME/Library/Keychains/login.keychain-db" \
  -P "$transfer" -T /usr/bin/codesign >/dev/null

echo "Created \"$name\":"
/usr/bin/openssl x509 -in "$work/cert.pem" -noout -subject -issuer -enddate -fingerprint -sha256
