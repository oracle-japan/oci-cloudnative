#!/bin/sh
#Get CompartmentID
oci iam compartment list | grep compartment-id | head -n 1 > compartment-id.txt ; cut -f 2 -d ":" compartment-id.txt | tr -d ' ','"',',' | tee compartment-id-tee.txt &>/dev/null ; compartment_id=`cat ./compartment-id-tee.txt` ; rm -rf ./compartment-id* ; echo ${compartment_id}

#Create Dynamic-Group
oci iam dynamic-group create --name OCI_Logging_Dynamic_Group --description OCI_Logging_Dynamic_Group --matching-rule "any {instance.compartment.id = '${compartment_id}'}"

#Create Policy
oci iam policy create --name OCI_Logging_Policy --description OCI_Logging_Policy --compartment-id "${compartment_id}" --statements '["Allow dynamic-group Default/OCI_Logging_Dynamic_Group to use log-content in compartment id '${compartment_id}'"]'