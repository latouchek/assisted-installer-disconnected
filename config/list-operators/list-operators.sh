oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.10 | awk '{ print $1 }'| awk 'NR!=1 {print}' |awk '{print "       - name: "$0}' > list-redhat-operators.lst
cat list-redhat-operators.yaml list-redhat-operators.lst > result1.yaml
oc-mirror list operators --catalog=registry.redhat.io/redhat/certified-operator-index:v4.10 | awk '{ print $1 }'| awk 'NR!=1 {print}' |awk '{print "       - name: "$0}' > list-certified-operators.lst
cat list-certified-operators.yaml list-certified-operators.lst > result2.yaml
oc-mirror list operators --catalog=registry.redhat.io/redhat/community-operator-index:v4.10 | awk '{ print $1 }'| awk 'NR!=1 {print}' |awk '{print "       - name: "$0}' > list-community-operators.lst
cat list-community-operators.yaml list-community-operators.lst > result3.yaml
oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-marketplace-index:v4.10 | awk '{ print $1 }'| awk 'NR!=1 {print}' |awk '{print "       - name: "$0}' > list-redhat-marketplace-operators.lst
cat ImageSetConfig-template.yaml result1.yaml result2.yaml result3.yaml list-redhat-marketplace-operators.yaml list-redhat-marketplace-operators.lst > imageset-config-all-operators.yaml