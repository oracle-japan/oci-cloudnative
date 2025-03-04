data "oci_objectstorage_namespace" "mushop_namespace" {
  compartment_id = var.compartment_ocid
}

resource "time_offset" "future" {
  offset_months = 1
}

locals {
  namespace   = data.oci_objectstorage_namespace.mushop_namespace.namespace
  future_time = time_offset.future.rfc3339
}

resource "oci_objectstorage_bucket" "mushop_bucket" {
  compartment_id = var.compartment_ocid
  namespace      = local.namespace
  name           = "mushop-bucket"
}

resource "oci_objectstorage_preauthrequest" "mushop_preauthenticated_request" {
  access_type  = "AnyObjectReadWrite"
  bucket       = oci_objectstorage_bucket.mushop_bucket.name
  namespace    = local.namespace
  name         = "mushop-preauthenticated-request"
  time_expires = local.future_time
}
