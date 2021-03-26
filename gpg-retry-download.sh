#!/bin/bash

error() {
    echo "ERROR: $1"
    exit 1
}

warn() {
  echo "WARN: $1"
}

info() {
    echo "INFO: $1"
}

usage() {
    echo "usage: $(basename $0) <gpg-key-ids>
       <gpg-key-ids> : space separated list of gpg key IDs"
    exit 1
}

gpgKeyIds="$*"

if [[ -z "$gpgKeyIds" ]]; then
    echo "ERROR: gpg key IDs not set."
    usage
fi

# Timeout after trying for 5 min
let TIMEOUT_DATE=$(date +'%s')+300

gpgCheckMultiKeyServer() {
  gpgCheckSuccess=1
  for server in $(shuf -e ha.pool.sks-keyservers.net \
                          hkp://p80.pool.sks-keyservers.net:80 \
                          keyserver.ubuntu.com \
                          hkp://keyserver.ubuntu.com:80); do \
      gpg --keyserver "${server}" --recv-keys $gpgKeyId && gpgCheckSuccess=0 && break || : ; \
  done; warn "Could not download gpg keys from list of keyservers"
}

for gpgKeyId in ${gpgKeyIds}; do
  info "Attempting to download gpg key ($gpgKeyId)."
  until gpgCheckMultiKeyServer && [ "${gpgCheckSuccess}" == "0" ]; do
      info "Download of gpg keys failed. Sleeping for a second then retrying..."
      sleep 1
      if [ "$(date +'%s')" -gt $TIMEOUT_DATE ]; then
        error "Timeout retrying to download gpg key ($gpgKeyId)."
      fi
  done
done
