data "oci_objectstorage_namespace" "mushop_namespace" {
  compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "mushop_bucket" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.mushop_namespace.namespace
  name           = "mushop-bucket"
}
