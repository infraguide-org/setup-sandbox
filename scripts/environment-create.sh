#!/usr/bin/env bash

##############################################################################
# vars
LAB_INFRA_NODES_GR1="dns|proxy|registry"
LAB_INFRA_NODES_GR2="deployment|recorder"

##############################################################################
# Infra nodes group1
print-create-env-commands  | grep -E "name +($LAB_INFRA_NODES_GR1)" | bash

echo ""
echo "Waiting for the first group to get prapared"; sleep 200
echo ""
##############################################################################
# Infra nodes group2
print-create-env-commands  | grep -E "name +($LAB_INFRA_NODES_GR2)" | bash

##############################################################################
# More nodes
print-create-env-commands  | grep -v -E "name +($LAB_INFRA_NODES_GR1|$LAB_INFRA_NODES_GR2)" | bash
