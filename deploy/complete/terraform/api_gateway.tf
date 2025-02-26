resource "oci_apigateway_gateway" "mushop_api_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "mushop-gateway"
  subnet_id      = oci_core_subnet.mushop_public_subnet.id
  endpoint_type  = "PUBLIC"
}
