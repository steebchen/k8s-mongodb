#!/bin/sh
##
# Script to remove/undepoy all project resources from GKE & GCE.
##

# Delete mongod stateful set + mongodb service + secrets + host vm configuer daemonset
kubectl delete statefulsets mongod
kubectl delete services mongo
kubectl delete secret shared-bootstrap-data
kubectl delete daemonset hostvm-configurer
sleep 3
