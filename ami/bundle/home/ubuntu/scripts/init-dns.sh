#!/bin/bash

# Every time server boots up it is given a new public IP. This script update
# a specified A record in an AWS hosted zone to match the current public IP of
# this server

# Based on https://willwarren.com/2014/07/03/roll-dynamic-dns-service-using-amazon-route53/

set -o errexit

region=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r ".region")

hosted_zone_id=$(aws ssm get-parameter --name "/minecraft-server/hosted-zone-id" --query "Parameter.Value" --output text --region "$region")
record_name=$(aws ssm get-parameter --name "/minecraft-server/server-fqdn" --query "Parameter.Value" --output text --region "$region")
record_ttl=60
record_comment="Updated on $(date)"
record_type="A"

# Get the external IP address
public_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)
current_dns_value=$(dig +short minecraft.fastigy.com)

if [[ $public_ip == "$current_dns_value" ]]; then
    echo "IP is still $public_ip. Exiting"
    exit 0
else
    echo "IP has changed to $public_ip"
    # Fill a temp file with valid JSON
    tmpfile=$(mktemp /tmp/temporary-file.XXXXXXXX)

    function cleanup {
      rm "$tmpfile"
    }

    trap cleanup ERR EXIT

    cat > ${tmpfile} << EOF
    {
      "Comment":"$record_comment",
      "Changes":[
        {
          "Action":"UPSERT",
          "ResourceRecordSet":{
            "ResourceRecords":[
              {
                "Value":"$public_ip"
              }
            ],
            "Name":"$record_name",
            "Type":"$record_type",
            "TTL":$record_ttl
          }
        }
      ]
    }
EOF

    # Update the Hosted Zone record
    aws route53 change-resource-record-sets \
        --hosted-zone-id $hosted_zone_id \
        --change-batch file://"$tmpfile"
fi

