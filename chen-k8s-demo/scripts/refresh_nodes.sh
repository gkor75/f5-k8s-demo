#!/bin/bash
# update nodes if VTEP Mac Addr changes
curl  curl --stderr /dev/null -k -u admin:admin -H "Content-Type: application/json"  "https://10.1.10.240/mgmt/tm/sys" | jq .selfLink -r | grep -E ver=1[23]
if [ $? != 0 ]
  then
  macAddr1=$(curl --stderr /dev/null -k -u admin:admin -H "Content-Type: application/json"  "https://10.1.10.240/mgmt/tm/net/tunnels/tunnel/~Common~flannel_vxlan/stats?options=all-properties"|jq '.entries."https://localhost/mgmt/tm/net/tunnels/tunnel/~Common~flannel_vxlan/stats"."nestedStats".entries.macAddr.description' -r)
  macAddr2=$(curl --stderr /dev/null -k -u admin:admin -H "Content-Type: application/json"  "https://10.1.10.241/mgmt/tm/net/tunnels/tunnel/~Common~flannel_vxlan/stats?options=all-properties"|jq '.entries."https://localhost/mgmt/tm/net/tunnels/tunnel/~Common~flannel_vxlan/stats"."nestedStats".entries.macAddr.description' -r)
  else
      macAddr1=$(curl --stderr /dev/null -k -u admin:admin -H "Content-Type: application/json"  "https://10.1.10.240/mgmt/tm/net/tunnels/tunnel/~Common~flannel_vxlan/stats?options=all-properties"|jq '.entries."https://localhost/mgmt/tm/net/tunnels/tunnel/~Common~flannel_vxlan/~Common~flannel_vxlan/stats"."nestedStats".entries.macAddr.description' -r)
      macAddr2=$(curl --stderr /dev/null -k -u admin:admin -H "Content-Type: application/json"  "https://10.1.10.241/mgmt/tm/net/tunnels/tunnel/~Common~flannel_vxlan/stats?options=all-properties"|jq '.entries."https://localhost/mgmt/tm/net/tunnels/tunnel/~Common~flannel_vxlan/~Common~flannel_vxlan/stats"."nestedStats".entries.macAddr.description' -r)
      fi
    
sed -e "s/MAC_ADDR/$macAddr1/g" bigip1-node.yaml |kubectl replace -f -
sed -e "s/MAC_ADDR/$macAddr2/g" bigip2-node.yaml |kubectl replace -f -
