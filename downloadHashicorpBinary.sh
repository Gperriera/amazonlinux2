#!/bin/bash -ex

# Usage and example
usage() {
    echo -e "\nUsage: \"./$0 -app consul -version 1.5.1\"\n"
    echo    " -h or --help    : Show this help menu."
    echo    " -a or --app     : The Hashicorp application you want to download (either 'consul' or 'vault')."
    echo    " -v or --version : The version of the Hashicorp application you want to download"
}

while [[ $# -gt 0 ]]; do
    opt="$1"
    shift;
    case "$opt" in
	"-a"|"--app"      ) app="$1"; shift;;
	"-v"|"--version"  ) version="$1"; shift;;
	"-h"|"--help"     ) usage
					            exit 0;;
	*                 ) echo "ERROR: Invalid option: \""$opt"\"" >&2
                      usage
				              exit 1;;
    esac
done

if [[ "${app}" == "" ]]; then
  echo "ERROR: Application was not provided" >&2
  usage
  exit 1
fi

if [[ "${version}" == "" ]]; then
  echo "ERROR: Invalid version: \"${version}\"" >&2
  usage
  exit 1
fi

hashicorpUrl="https://releases.hashicorp.com"

echo "INFO: Downloading zip file for \"${app}\""
curl --connect-timeout 5 --speed-limit 10000 --speed-time 5 --location \
                --retry 10 --retry-max-time 300 --output ${app}_${version}_linux_amd64.zip \
                ${hashicorpUrl}/${app}/${version}/${app}_${version}_linux_amd64.zip

echo "INFO: Downloading SHA256SUMS file for \"${app}\""
curl --connect-timeout 5 --speed-limit 10000 --speed-time 5 --location \
                --retry 10 --retry-max-time 300 --output ${app}_${version}_SHA256SUMS \
                ${hashicorpUrl}/${app}/${version}/${app}_${version}_SHA256SUMS

echo "INFO: Downloading SHA256SUMS signature file for \"${app}\""
curl --connect-timeout 5 --speed-limit 10000 --speed-time 5 --location \
                --retry 10 --retry-max-time 300 --output ${app}_${version}_SHA256SUMS.sig \
                ${hashicorpUrl}/${app}/${version}/${app}_${version}_SHA256SUMS.sig

echo "INFO: Checking signature of SHA256SUMS and verifying the shasum of the binary"
gpg --verify ${app}_${version}_SHA256SUMS.sig ${app}_${version}_SHA256SUMS
#shasum -a 256 -c ${app}_${version}_SHA256SUMS


echo "INFO: Comparing sha256sum of zip file against signed SHA256SUMS"
zip_sha256sum=$(sha256sum ${app}_${version}_linux_amd64.zip | cut -d' ' -f1)
signed_sha256sum=$(cat ${app}_${version}_SHA256SUMS | grep ${app}_${version}_linux_amd64.zip | cut -d' ' -f1)
if [[ "${zip_sha256sum}" != "${signed_sha256sum}" ]]; then
  echo "ERROR: sha256sum for ${app} zip file did not match signed sha256sum"
  exit 1
fi

echo "INFO: Unzipping zip file"
unzip ${app}_${version}_linux_amd64.zip
upx -9 ${app}
rm ${app}_${version}_SHA256SUMS ${app}_${version}_SHA256SUMS.sig ${app}_${version}_linux_amd64.zip
