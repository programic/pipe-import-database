#!/usr/bin/env bash

set -o errexit
set -o pipefail

# Include common.sh script
source "$(dirname "${0}")/common.sh"

: ${AWS_ACCESS_KEY_ID?"You need to set the AWS_ACCESS_KEY_ID environment variable."}
: ${AWS_SECRET_ACCESS_KEY?"You need to set the AWS_SECRET_ACCESS_KEY environment variable."}
: ${AWS_DEFAULT_REGION?"You need to set the AWS_DEFAULT_REGION environment variable."}
: ${S3_BUCKET?"You need to set the S3_BUCKET environment variable."}
: ${DIGITALOCEAN_ACCESS_TOKEN?"You need to set the DIGITALOCEAN_ACCESS_TOKEN environment variable."}
: ${DIGITALOCEAN_DATABASE_ID?"You need to set the DIGITALOCEAN_DATABASE_ID environment variable."}
: ${MYSQL_DATABASE?"You need to set the MYSQL_DATABASE environment variable."}
: ${MYSQL_USER?"You need to set the MYSQL_USER environment variable."}
: ${MYSQL_PASSWORD?"You need to set the MYSQL_PASSWORD environment variable."}

import_mysql() {

  s3_key_latest=""
  s3_bucket_slices=(${S3_BUCKET//\// })

  # Get subfolder from bucket slices and escape for regex
  subs=$(printf "%s/" "${s3_bucket_slices[@]:1}")
  subs=$(echo "${subs}" | sed -e 's/\//\\\//g')

  # First get all objects inside the bucket/directory
  for s3_key in $(aws s3 ls s3://${S3_BUCKET} --recursive | awk '{print $4}'); do

    # Check if database is found
    regex="^${subs}(.+)\/${MYSQL_DATABASE}_(.+).sql.gz$"

    if [[ $s3_key =~ $regex ]]; then
      s3_key_latest=$s3_key
    fi
  done
  
  if [ $s3_key_latest == "" ]; then
        fail "No backup found"
  fi

  success "Found latest backup: \"${s3_key_latest}\""
  
  s3_object_compressed="$(mktemp -u).sql.gz"
  s3_object="$(mktemp -u).sql"

  aws s3api get-object --bucket ${s3_bucket_slices[0]} --key "${s3_key_latest}" ${s3_object_compressed} > /dev/null
  gunzip -c ${s3_object_compressed} > ${s3_object}
  success "Downloaded and extracted the latest backup"

  # Get public ip address of this container
  public_ip=$(curl -s ipinfo.io/ip)

  # Add public id address to firewall and get the created firewall uuids, so we can remove them later
  firewall_info=$(doctl databases firewalls append "${DIGITALOCEAN_DATABASE_ID}" --rule "ip_addr:${public_ip}" --output=json)
  firewall_uuids=$(echo "${firewall_info}" | jq -r ".[] | select(.type==\"ip_addr\") | select(.value==\"${public_ip}\") | .uuid")
  success "Setup the database firewall to allow the public ip address \"${public_ip}\""

  db_info=$(doctl databases connection "${DIGITALOCEAN_DATABASE_ID}" --output=json)
  success "Get host and port of the database"
  
  mysql \
    --host "$(echo "${db_info}" | jq -r '.host')" \
    --port=$(echo "${db_info}" | jq -r '.port') \
    --user ${MYSQL_USER} \
    --password="${MYSQL_PASSWORD}" \
    ${MYSQL_DATABASE} < ${s3_object}
  
  success "The backup has been successfully imported"

  for firewall_uuid in ${firewall_uuids}; do
    doctl databases firewalls remove "${DIGITALOCEAN_DATABASE_ID}" --uuid "${firewall_uuid}" > /dev/null
  done

  success "Cleaned up the public ip address from the firewall"
}

import_mysql