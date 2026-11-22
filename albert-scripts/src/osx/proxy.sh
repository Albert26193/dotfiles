#!/bin/bash

# @desc: 开启终端 HTTP/HTTPS/SOCKS5 代理并测试连通性
# @usage: ab.proxy.on [ip=127.0.0.1] [port=7890]
# @tags: network proxy
function ab.proxy.on {
  local proxy_ip_address="${1:-127.0.0.1}"
  local port="${2:-7890}"

  export http_proxy="http://${proxy_ip_address}:${port}"
  export https_proxy="http://${proxy_ip_address}:${port}"
  export all_proxy="socks5://${proxy_ip_address}:${port}"
  echo -e "proxy on, ip is ${proxy_ip_address}, port is ${port}"
  echo -e "please wait for 3 seconds to test..."

  local google_result
  google_result=$(curl -s --connect-timeout 3 -m 3 google.com)
  if [[ -z "${google_result}" ]]; then
    echo -e "proxy on failed, please check it."
    return 1
  else
    echo -e "proxy on success.🚀️🚀️🚀️"
    echo -e "your curl google's data length is: ${#google_result}"
    return 0
  fi
}

# @desc: 关闭终端代理并查询当前出口 IP
# @tags: network proxy
function ab.proxy.off {
  unset http_proxy
  unset https_proxy
  unset all_proxy
  echo -e "proxy turn off🌙️"
  curl cip.cc
  return 0
}
