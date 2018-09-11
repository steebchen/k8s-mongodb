#!/bin/sh
##
# Script to deploy a Kubernetes project with a StatefulSet running a MongoDB Replica Set, to GKE.
##

# Create keyfile for the MongoD cluster as a Kubernetes shared secret
TMPFILE=$(mktemp)
/usr/bin/openssl rand -base64 741 > $TMPFILE
kubectl create secret generic shared-bootstrap-data --from-file=internal-auth-mongodb-keyfile=$TMPFILE
rm $TMPFILE

# Create mongodb service with mongod stateful-set
kubectl apply -f ../resources/mongo.yaml
echo

# Wait until the final (3rd) mongod has started properly
echo "Waiting for the 3 containers to come up (`date`)..."
echo " (IGNORE any reported not found & connection errors)"
sleep 30
echo -n "  "
until kubectl --v=0 exec mongod-2 -c mongod-container -- mongo --quiet --eval 'db.getMongo()'; do
    sleep 5
    echo -n "  "
done
echo "...mongod containers are now running (`date`)"
echo

# Print current deployment state
kubectl get persistentvolumes
echo
kubectl get all

