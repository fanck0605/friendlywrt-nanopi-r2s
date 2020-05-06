#!/bin/sh
# Copyright (c) 2020, Chuck <fanck0605@qq.com>
#
# this script is writing for openwrt
# this script need the interface named 'lan'
# to use this script, you must install 'jq' first
# we need the `jq` to parse `ifstatus`'s result

# usage: `/bin/sh /path/to/check_wan4.sh >/dev/null 2>&1 &`

logger 'Check Wan4: Script started!'

get_ipv4_address() {
  if ! if_status=$(ifstatus $1); then
    return 1
  fi
  echo $if_status | jq -r '."ipv4-address"[0]."address"'
}

if ! lan_addr=$(get_ipv4_address lan); then
  logger "Check Wan4: Don't support your network environment!"
  exit 1
fi

fail_count=0

while :; do
  sleep 2s

  # try to connect
  if ping -W 1 -c 1 "$lan_addr" >/dev/null 2>&1; then
    # No problem!
    fail_count=0
    continue
  fi

  if [ $fail_count -ge 3 ]; then
    # Here we clear the counter first.
    fail_count=0

    # Must have some problem! We refresh the ip address and try again!
    lan_addr=$(get_ipv4_address lan)

    if ping -W 1 -c 1 "$lan_addr" >/dev/null 2>&1; then
      continue
    fi

    logger 'Check Wan4: Network problem! Firewall reloading...'
    /etc/init.d/firewall reload >/dev/null 2>&1
    sleep 2s

    if ping -W 1 -c 1 "$lan_addr" >/dev/null 2>&1; then
      continue
    fi

    logger 'Check Wan4: Network problem! Network reloading...'
    /etc/init.d/network reload >/dev/null 2>&1
    sleep 2s
  else
    # May have some problem
    logger "Check Wan4: Network may have some problem!"
    fail_count=$((fail_count + 1))
    continue
  fi
done
