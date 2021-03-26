#!/bin/bash -ex

error() {
  echo "ERROR: $1"
  exit 1
}

info() {
  echo "INFO: $1"
}

# check required settings
[ "${javaDownloadUrl}" != "" ] || error "javaDownloadUrl needs to be set"

[ "${javaMd5Checksum}" != "" ] || error "javaMd5Checksum needs to be set"

info "downloading Java from ${javaDownloadUrl}"
JAVA_RPM_PATH="/java.rpm"

# timeout if Java doesn't download within 5 minutes
let TIMEOUT_DATE=$(date +'%s')+300
until curl --connect-timeout 5 --speed-limit 10000 --speed-time 5 --location "${javaDownloadUrl}" > "${JAVA_RPM_PATH}"; do
  info "download of RPM failed. Sleeping for a second and retrying..."
  sleep 1
  if [ "$(date +'%s')" -gt $TIMEOUT_DATE ]; then
    error "timeout retrying the RPM download"
  fi
done
rpm -qp --qf '%{VERSION}\n' "${JAVA_RPM_PATH}"

info "validating the checksum on the downloaded Java rpm file"
generatedChecksum=$(md5sum -b "${JAVA_RPM_PATH}" | awk '{ print $1 }')
[ "${generatedChecksum}" == "${javaMd5Checksum}" ] || error "checksums for Java download don't match"
