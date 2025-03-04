resource "oci_identity_dynamic_group" "mushop_dynamic_group" {
  compartment_id = var.compartment_ocid
  name           = "mushop-dynamic-group"
  description    = "Dynamic Group for Mushop"
  matching_rule = format(
    "Any {All {resource.type = 'devopsrepository', resource.compartment.id = '%s'},All {resource.type = 'devopsbuildpipeline', resource.compartment.id = '%s'},All {resource.type = 'devopsdeploypipeline', resource.compartment.id = '%s'}}",
    var.compartment_ocid,
    var.compartment_ocid,
    var.compartment_ocid
  )
}

resource "oci_identity_policy" "mushop_policy" {
  compartment_id = var.compartment_ocid
  description    = "OCI DevOps Policy for Mushop"
  name           = "mushop-policy"
  statements = [
    format("allow dynamic-group %s to manage devops-family in tenancy", oci_identity_dynamic_group.mushop_dynamic_group.id),
    format("allow dynamic-group %s to manage all-artifacts in tenancy", oci_identity_dynamic_group.mushop_dynamic_group.id),
    format("allow dynamic-group %s to use ons-topics in tenancy", oci_identity_dynamic_group.mushop_dynamic_group.id),
    format("allow dynamic-group %s to manage cluster-family in tenancy", oci_identity_dynamic_group.mushop_dynamic_group.id)
  ]
}
