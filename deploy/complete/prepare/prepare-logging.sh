#!/bin/sh

# Get CompartmentID
compartment_id=$(oci iam compartment list --include-root --query "data[*].id" --raw-output | sed '/^\[/d;/^\]/d;s/^[[:space:]]*//;s/"//g')
echo "Compartment ID: ${compartment_id}"

# Create Dynamic-Group
oci iam dynamic-group create --name OCI_Logging_Dynamic_Group --description OCI_Logging_Dynamic_Group --matching-rule "any {instance.compartment.id = '${compartment_id}'}"

# Create Policy
oci iam policy create --name OCI_Logging_Policy --description OCI_Logging_Policy --compartment-id "${compartment_id}" --statements '["Allow dynamic-group Default/OCI_Logging_Dynamic_Group to use log-content in compartment id '${compartment_id}'"]'