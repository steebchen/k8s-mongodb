#!/bin/sh
##
# Script to just deploy the MongoDB Service & StatefulSet back onto the exising Kubernetes cluster.
##

# Deploy just the mongodb service with mongod stateful-set only
kubectl apply -f ../resources/mongo.yaml
sleep 5

# Print current deployment state (unlikely to be finished yet)
kubectl get all
echo
echo "Keep running the following command until all 'mongod-n' pods are shown as running:  kubectl get all"
echo

