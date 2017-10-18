#!/bin/bash

set -e
set -x
set -o pipefail
set -u

ORIG_PWD="${PWD}"

# Create our own GOPATH
export GOPATH="${ORIG_PWD}/go"

# Symlink our source dir from inside of our own GOPATH
mkdir -p "${GOPATH}/src/github.com/govau"
ln -s "${ORIG_PWD}/src" "${GOPATH}/src/github.com/govau/cf-healthcheck"
cd "${GOPATH}/src/github.com/govau/cf-healthcheck"

# Cache glide deps
export GLIDE_HOME="${ORIG_PWD}/src/.glide_cache"
mkdir -p "${GLIDE_HOME}"

# Install go deps
glide install

# Write our status file
DATE="$(date)"
ID="$(openssl rand -hex 32)"
mkdir -p "${ORIG_PWD}/src/data"
cat <<EOF > "${ORIG_PWD}/src/data/status.json"
{
    "id": "${ID}",
    "date": "${DATE}"
}
EOF

# Generate the stuff
go generate

# Build the thing
go build

# Run Go tests
go test $(go list ./... | grep -v "/vendor/")

# Copy artefacts to output directory
cp -R \
        "${ORIG_PWD}/src/cf-healthcheck" \
        "${ORIG_PWD}/src/Procfile" \
    "${ORIG_PWD}/build"

# Write manifest
cp "${ORIG_PWD}/src/manifest-template.yml" "${ORIG_PWD}/manifest/manifest.yml"
printf "\ndomain: $DOMAIN\n" >> "${ORIG_PWD}/manifest/manifest.yml"

# Write SHA256
EXPECTED_RESULT="$(openssl dgst -sha256 < "${ORIG_PWD}/src/data/status.json" | sed 's/^.* //')"
cat <<EOF > "${ORIG_PWD}/test/check.sh"
#!/bin/bash

set -e
set -x
set -o pipefail
set -u

RESULT="\$(curl "http://cf-healthcheck.${DOMAIN}" | openssl dgst -sha256 | sed 's/^.* //')"

[[ "\${RESULT}" -eq "${EXPECTED_RESULT}" ]] || exit 1
EOF

chmod a+x "${ORIG_PWD}/test/check.sh"

echo "Script to test is:"
cat "${ORIG_PWD}/test/check.sh"
