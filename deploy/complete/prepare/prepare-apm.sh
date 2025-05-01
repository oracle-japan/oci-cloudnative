#!/bin/sh

# Get CompartmentID
compartment_id=$(oci iam compartment list --include-root --query "data[*].id" --raw-output | sed '/^\[/d;/^\]/d;s/^[[:space:]]*//;s/"//g')
echo "Compartment ID: ${compartment_id}"

# Create Policy
oci iam policy create --name OCI_APM_Policy --description OCI_APM_Policy --compartment-id "${compartment_id}" --statements '["Allow group APM-Admins to manage apm-domains in compartment id '${compartment_id}'"]'