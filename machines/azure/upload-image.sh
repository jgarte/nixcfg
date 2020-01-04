#!/usr/bin/env bash
set -euo pipefail
set -x

attr="${1:-"azbuildworld"}"

nix-build ../../default.nix -A "${attr}" --out-link "azure"

source ./common.sh

if ! az group show -n "${group}" &>/dev/null; then
  az group create --name "${group}" --location "${location}"
fi

if ! az disk show -g "${group}" -n "${img_name}" &>/dev/null; then
  bytes="$(stat -c %s ${img_file})"
  size="30"
  az disk create \
    --resource-group "${group}" \
    --name "${img_name}" \
    --for-upload true --upload-size-bytes "${bytes}"

  timeout=$(( 60 * 60 )) # disk access token timeout
  sasurl="$(\
    az disk grant-access \
      --access-level Write \
      --resource-group "${group}" \
      --name "${img_name}" \
      --duration-in-seconds ${timeout} \
        | jq -r '.accessSas'
  )"

  azcopy copy "${img_file}" "${sasurl}" \
    --blob-type PageBlob 
    
  az disk revoke-access \
    --resource-group "${group}" \
    --name "${img_name}"
fi

if ! az image show -g "${group}" -n "${img_name}" &>/dev/null; then
  diskid="$(az disk show -g "${group}" -n "${img_name}" -o json | jq -r .id)"

  az image create \
    --resource-group "${group}" \
    --name "${img_name}" \
    --source "${diskid}" \
    --os-type "linux" >/dev/null
fi

imageid="$(az image show -g "${group}" -n "${img_name}" -o json | jq -r .id)"
echo "${imageid}"
