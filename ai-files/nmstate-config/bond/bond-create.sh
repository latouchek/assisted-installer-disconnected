export AI_URL='http://192.167.124.1:8090'
export CLUSTER_SSHKEY=$(cat ~/.ssh/id_ed25519.pub)
export PULL_SECRET=$(cat pull-secret.txt | jq -R .)
export NODE_SSH_KEY="$CLUSTER_SSHKEY"

jq -n --arg SSH_KEY "$NODE_SSH_KEY" --arg NMSTATE_YAML1 "$(cat ~/bond/nmstate-bond-worker0.yaml)" --arg NMSTATE_YAML2 "$(cat ~/bond/nmstate-bond-worker1.yaml)"--arg NMSTATE_YAML3 "$(cat ~/bond/nmstate-bond-worker2.yaml)"  '{
  "ssh_public_key": $SSH_KEY,
  "image_type": "full-iso",
  "static_network_config": [
    {
      "network_yaml": $NMSTATE_YAML1,
      "mac_interface_map": [{"mac_address": "0c:c4:7a:64:c1:64", "logical_nic_name": "ens1"}, {"mac_address": "0c:c4:7a:64:c1:65", "logical_nic_name": "eno2"}]
    },
    {
      "network_yaml": $NMSTATE_YAML2,
      "mac_interface_map": [{"mac_address": "0c:c4:7a:64:c1:7e", "logical_nic_name": "ens1"}, {"mac_address": "0c:c4:7a:64:c1:7f", "logical_nic_name": "eno2"}]
    },
    {
      "network_yaml": $NMSTATE_YAML3,
      "mac_interface_map": [{"mac_address": "0c:c4:7a:64:c1:82", "logical_nic_name": "ens1"}, {"mac_address": "0c:c4:7a:64:c1:83", "logical_nic_name": "eno2"}]
    }
  ]
}' > bond-workers
