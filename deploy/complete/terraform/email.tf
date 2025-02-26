resource "oci_email_sender" "mushop_sender" {
  compartment_id = var.compartment_ocid
  email_address  = var.email_address
}
