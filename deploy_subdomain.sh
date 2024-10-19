#!/bin/bash

# Cloudflare API 정보 설정
API_TOKEN=$CF_API_TOKEN  # GitHub Secrets로부터 가져옵니다.
ZONE_ID=$CF_ZONE_ID      # GitHub Secrets로부터 가져옵니다.

# 루트 도메인 설정 (moontree.me)
ROOT_DOMAIN="moontree.me"

# subdomain.json에서 서브도메인과 대상 도메인을 읽어옵니다
for row in $(jq -r 'to_entries[] | @base64' subdomain.json); do
  _jq() {
    echo ${row} | base64 --decode | jq -r ${1}
  }

  SUBDOMAIN=$(_jq '.key')
  TARGET=$(_jq '.value')

  # 완전한 서브도메인 (예: 202420505.moontree.me)
  FULL_SUBDOMAIN="$SUBDOMAIN.$ROOT_DOMAIN"

  # 기존 DNS 레코드 확인 (CNAME 레코드가 있는지 확인)
  DNS_RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$FULL_SUBDOMAIN&type=CNAME" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

  # DNS 레코드가 있으면 업데이트, 없으면 생성
  if [ "$DNS_RECORD_ID" != "null" ]; then
    echo "Updating existing CNAME record for $FULL_SUBDOMAIN"
    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID" \
      -H "Authorization: Bearer $API_TOKEN" \
      -H "Content-Type: application/json" \
      --data '{"type":"CNAME","name":"'$FULL_SUBDOMAIN'","content":"'$TARGET'","ttl":1,"proxied":false}'
  else
    echo "Creating new CNAME record for $FULL_SUBDOMAIN"
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
      -H "Authorization: Bearer $API_TOKEN" \
      -H "Content-Type: application/json" \
      --data '{"type":"CNAME","name":"'$FULL_SUBDOMAIN'","content":"'$TARGET'","ttl":1,"proxied":false}'
  fi

  echo "CNAME for $FULL_SUBDOMAIN -> $TARGET has been applied."
done
