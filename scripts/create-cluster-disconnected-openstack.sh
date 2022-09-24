
export AI_URL='http://10.17.3.1:8090'
export BASE_DNS_DOMAIN='lab.local'
export CLUSTER_NAME="ocpd"
export MACHINE_CIDR="10.17.3.0/24"
export VERSION="4.10"
jq -n  --arg PULLSECRET "$(cat pull-secret.json)" --arg SSH_KEY "$(cat ~/.ssh/id_ed25519.pub)" --arg VERSION "$VERSION" --arg DOMAIN "$BASE_DNS_DOMAIN" --arg CLUSTERN "$CLUSTER_NAME" --arg CIDR "$MACHINE_CIDR" '{
    "kind": "Cluster",
    "name": $CLUSTERN,
    "openshift_version": $VERSION,
    "base_dns_domain": $DOMAIN,
    "hyperthreading": "all",
    "schedulable_masters": false,
    "platform": {
      "type": "baremetal"
     },
    "user_managed_networking": true,
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
        "cidr": $CIDR
      }
    ],
    "network_type": "OVNKubernetes",
    "additional_ntp_source": "ntp1.hetzner.de",
    "vip_dhcp_allocation": false,
    "high_availability_mode": "Full",
    "hosts": [], 
    "ssh_public_key": $SSH_KEY,
    "pull_secret": $PULLSECRET
}' > deployment.json

curl -s -X POST "$AI_URL/api/assisted-install/v2/clusters" \
  -d @./deployment.json \
  --header "Content-Type: application/json" \
  | jq .

export CLUSTER_ID=$(curl -s -X GET "$AI_URL/api/assisted-install/v2/clusters?with_hosts=true" -H "accept: application/json" -H "get_unregistered_clusters: false"| jq -r '.[].id')
echo $CLUSTER_ID
rm -f deployment.json


####Get install-config.yaml###
curl -X 'GET'   "$AI_URL/api/assisted-install/v2/clusters/$CLUSTER_ID/install-config"   -H 'accept: application/json'   -H 'Content-Type: application/json'|jq -r .


######prepare infra####

jq -n --arg CLUSTERID "$CLUSTER_ID" --arg PULLSECRET "$(cat pull-secret.json)" \
      --arg SSH_KEY "$(cat ~/.ssh/id_ed25519.pub)" \
      --arg VERSION "$VERSION"  '{
  "name": "ocpd_infra-env",
  "openshift_version": $VERSION,
  "pull_secret": $PULLSECRET,
  "ssh_authorized_key": $SSH_KEY,
  "image_type": "full-iso",
  "cluster_id": $CLUSTERID
}' > infraenv.json

curl -H "Content-Type: application/json" -X POST -d @infraenv.json ${AI_URL}/api/assisted-install/v2/infra-envs | jq .

export INFRAENV_ID=$(curl -X GET "$AI_URL/api/assisted-install/v2/infra-envs" -H "accept: application/json" | jq -r '.[].id' | awk 'NR<2')
echo $INFRAENV_ID

rm -rf infraenv.json

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
####Download ISO
ISO_URL=$(curl -X GET "$AI_URL/api/assisted-install/v2/infra-envs/$INFRAENV_ID/downloads/image-url" -H "accept: application/json"|jq -r .url)


curl -X GET "$ISO_URL" -H "accept: application/octet-stream" -o /opt/discovery_image_ocpd.iso
####Deploy nodes
terraform  -chdir=../terraform/ocp4-openstack apply -auto-approve

Sleep 120 

#####Trigger deployment##### 

curl -X POST \
  "$AI_URL/api/assisted-install/v2/clusters/$CLUSTER_ID/actions/install" \
  -H "accept: application/json" \
  -H "Content-Type: application/json"


######Wait for deployment to  completes #### 
read -p "Press any key when deployment is done " -n1 -s


#####Download config#####
rm -rf ~/.kube
mkdir ~/.kube
curl -X GET $AI_URL/api/assisted-install/v2/clusters/$CLUSTER_ID/downloads/credentials?file_name=kubeconfig \
     -H 'accept: application/octet-stream' > /root/.kube/config