export $BASTIONIP=10.145.145.97  #replace by your bastion IP
export AI_URL='http://$BASTIONIP:8090'
export NIC_CONFIG='bond-static'

jq -n  --arg PULLSECRET "$(cat privaterepo.json)" --arg SSH_KEY "$(cat ~/.ssh/id_ed25519.pub)" '{
    "kind": "Cluster",
    "name": "ocpd",
    "openshift_version": "4.10",
    "base_dns_domain": "lab.local",
    "hyperthreading": "all",
    "api_vip": "10.145.145.107",
    "ingress_vip": "10.145.145.108",
    "schedulable_masters": false,
    "platform": {
      "type": "baremetal"
     },
    "user_managed_networking": false,
    "cluster_networks": [
      {
        "cidr": "172.20.0.0/16",
        "host_prefix": 23
      }
    ],
    "service_networks": [
      {
        "cidr": "172.31.0.0/16"
      }
    ],
    "machine_networks": [
      {
        "cidr": "10.145.145.96/27"
      }
    ],
    "network_type": "OVNKubernetes",
    "additional_ntp_source": "ntp1.hetzner.de",
    "vip_dhcp_allocation": false,
    "high_availability_mode": "Full",
    "hosts": [], 
    "ssh_public_key": $SSH_KEY,
    "pull_secret": $PULLSECRET
}' > deployment-disconnected.json

curl -s -X POST "$AI_URL/api/assisted-install/v2/clusters" \
  -d @./deployment-disconnected.json \
  --header "Content-Type: application/json" \
  | jq .

export CLUSTER_ID=$(curl -s -X GET "$AI_URL/api/assisted-install/v2/clusters?with_hosts=true" -H "accept: application/json" -H "get_unregistered_clusters: false"| jq -r '.[].id')
echo $CLUSTER_ID
rm -f deployment-disconnected.json
######convert install-config.yaml to json###
yq -cR . install-config.yaml > repo.json


####Modify install-config and specify repo +CA#####
curl -X 'PATCH' \
  "$AI_URL/api/assisted-install/v2/clusters/$CLUSTER_ID/install-config" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d @./repo.json
####get patched install-config.yaml###
curl -X 'GET'   "$AI_URL/api/assisted-install/v2/clusters/$CLUSTER_ID/install-config"   -H 'accept: application/json'   -H 'Content-Type: application/json'|jq -r .

rm -rf repo.json

######prepare infra####

jq -n --arg CLUSTERID "$CLUSTER_ID" --arg PULLSECRET "$(cat pull-secret-privaterepo.json)" \
      --arg SSH_KEY "$(cat ~/.ssh/id_ed25519.pub)" \
      --arg NMSTATEM_YAML0 "$(cat ./$NIC_CONFIG/nmstate-$NIC_CONFIG-master0.yaml)" --arg NMSTATEM_YAML1 "$(cat ./$NIC_CONFIG/nmstate-$NIC_CONFIG-master1.yaml)" --arg NMSTATEM_YAML2 "$(cat ./$NIC_CONFIG/nmstate-$NIC_CONFIG-master2.yaml)" \
      --arg NMSTATE_YAML0 "$(cat ./$NIC_CONFIG/nmstate-$NIC_CONFIG-worker0.yaml)" --arg NMSTATE_YAML1 "$(cat ./$NIC_CONFIG/nmstate-$NIC_CONFIG-worker1.yaml)" --arg NMSTATE_YAML2 "$(cat ./$NIC_CONFIG/nmstate-$NIC_CONFIG-worker2.yaml)" '{
  "name": "ocpd_infra-env",
  "openshift_version": "4.10",
  "pull_secret": $PULLSECRET,
  "ssh_authorized_key": $SSH_KEY,
  "image_type": "full-iso",
  "cluster_id": $CLUSTERID,
  "static_network_config": [
    {
      "network_yaml": $NMSTATEM_YAML0,
      "mac_interface_map": [{"mac_address": "aa:bb:cc:11:42:10", "logical_nic_name": "ens192"}]
    },
    {
      "network_yaml": $NMSTATEM_YAML1,
      "mac_interface_map": [{"mac_address": "aa:bb:cc:11:42:11", "logical_nic_name": "ens192"}]
    },
    {
      "network_yaml": $NMSTATEM_YAML2,
      "mac_interface_map": [{"mac_address": "aa:bb:cc:11:42:12", "logical_nic_name": "ens192"}]
    },
    {
      "network_yaml": $NMSTATE_YAML0,
      "mac_interface_map": [{"mac_address": "aa:bb:cc:11:42:20", "logical_nic_name": "ens192"}, {"mac_address": "aa:bb:cc:11:42:50", "logical_nic_name": "ens224"}]
    },
    {
      "network_yaml": $NMSTATE_YAML1,
      "mac_interface_map": [{"mac_address": "aa:bb:cc:11:42:21", "logical_nic_name": "ens192"}, {"mac_address": "aa:bb:cc:11:42:51", "logical_nic_name": "ens224"}]
    },
    {
      "network_yaml": $NMSTATE_YAML2,
      "mac_interface_map": [{"mac_address": "aa:bb:cc:11:42:22", "logical_nic_name": "ens192"}, {"mac_address": "aa:bb:cc:11:42:52", "logical_nic_name": "ens224"}]
    }
  ]
}' > nmstate-$NIC_CONFIG

curl -H "Content-Type: application/json" -X POST -d @nmstate-$NIC_CONFIG ${AI_URL}/api/assisted-install/v2/infra-envs | jq .

export INFRAENV_ID=$(curl -X GET "$AI_URL/api/assisted-install/v2/infra-envs" -H "accept: application/json" | jq -r '.[].id' | awk 'NR<2')
echo $INFRAENV_ID

rm -rf nmstate-$NIC_CONFIG


######Patch infra and add registries.conf and rootCA to ISO####

jq -n --arg OVERRIDE "{\"ignition\": {\"version\": \"3.1.0\"}, \"storage\": {\"files\": [{\"path\": \"/etc/pki/ca-trust/source/anchors/registry.crt\", \"mode\": 420, \"overwrite\": true, \"user\": {\"name\": \"root\"}, \"contents\": {\"source\": \"data:text/plain;base64,$(cat Certs/rootCA.pem | base64 -w 0)\"}}, {\"path\": \"/etc/containers/registries.conf\", \"mode\": 420, \"overwrite\": true, \"user\": {\"name\": \"root\"}, \"contents\": {\"source\": \"data:text/plain;base64,$(cat registries.conf | base64 -w 0)\"}}]}}" \
'{
   "ignition_config_override": $OVERRIDE
}' > ignition-registry

curl \
    --header "Content-Type: application/json" \
    --request PATCH \
    --data  @ignition-registry \
    "$AI_URL/api/assisted-install/v2/infra-envs/$INFRAENV_ID"

rm -rf ignition-registry

ISO_URL=$(curl -X GET "$AI_URL/api/assisted-install/v2/infra-envs/$INFRAENV_ID/downloads/image-url" -H "accept: application/json"|jq -r .url)

rm -rf /opt/discovery_image_ocpd.iso

curl -X GET "$ISO_URL" -H "accept: application/octet-stream" -o /opt/discovery_image_ocpd.iso

###We use govc to puplad the iSO to our DataStore###
govc datastore.upload -ds vsanDatastore /opt/discovery_image_ocpd.iso  ISO/discovery_image_ocpd.iso

terraform  -chdir=../terraform/ocp4-vsphere apply -auto-approve

Sleep 120 

#####Trigger deployment##### 

curl -X POST \
  "$AI_URL/api/assisted-install/v2/clusters/$CLUSTER_ID/actions/install" \
  -H "accept: application/json" \
  -H "Content-Type: application/json"


######Wait for deployment to  completes #### 
read -p "Press any key when deployment is done " -n1 -s



rm -rf ~/.kube
mkdir ~/.kube
curl -X GET $AI_URL/api/assisted-install/v2/clusters/$CLUSTER_ID/downloads/credentials?file_name=kubeconfig \
     -H 'accept: application/octet-stream' > /root/.kube/config