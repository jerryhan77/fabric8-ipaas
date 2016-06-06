#!/bin/bash

#This script is called by maven to deploy the secret after the maven validate phase.
#Note that for this script to succeed you must oc login first

if [ ! -f "../elasticsearch/target/secret/elasticsearch-v1/public.key" ]; then
  echo "ERROR: Please run 'mvn -Pssl package' to create the elasticsearch public.key"
  exit 1
fi

if [ ! -f "../apiman-gateway/target/secret/apiman-gateway/public.key" ]; then
  echo "ERROR: Please run 'mvn -Pssl package' to create the apiman-gateway public.key"
  exit 1
fi


# deleting existing secret if there
oc get secret apiman-keystore | grep 'Opaque' &> /dev/null
if [ $? == 0 ]; then
  echo -- Delete existing secret/apiman-keystore
  oc delete secret apiman-keystore
fi

truststorePw=`cat target/secret/apiman/truststore.password`

if [ -f "target/secret/apiman/truststore" ]; then
  rm target/secret/apiman/truststore
fi

echo -- Import Elasticsearch \"public.key\" into truststore
keytool -noprompt -importcert -keystore target/secret/apiman/truststore \
        -alias elasticsearch-v1 \
        -file ../elasticsearch/target/secret/elasticsearch-v1/public.key \
        -storepass $truststorePw 
echo -- Import Apiman-gateway \"public.key\" into truststore
keytool -noprompt -importcert -keystore target/secret/apiman/truststore \
        -alias apiman-gateway \
        -file ../apiman-gateway/target/secret/apiman-gateway/public.key \
        -storepass $truststorePw 

# create the new secret
echo -- Create new secret/apiman-keystore
oc secrets new apiman-keystore \
     gateway.user=target/secret/apiman/gateway.user \
     apiman.properties=target/secret/apiman/apiman.properties \
     keystore=target/secret/apiman/keystore \
     keystore.password=target/secret/apiman/keystore.password \
     truststore=target/secret/apiman/truststore \
     truststore.password=target/secret/apiman/truststore.password
#     client.keystore=target/secret/apiman/client.keystore \
#     client.keystore.password=target/secret/apiman/client.keystore.password

# oc create route passthrough apiman --service apiman
