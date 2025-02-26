resource "oci_functions_application" "mushop_application" {
  compartment_id = var.compartment_ocid
  display_name   = "mushop-app"
  subnet_ids = [
    oci_core_subnet.mushop_public_subnet.id
  ]
  shape = "GENERIC_X86"
}
