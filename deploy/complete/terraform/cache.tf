resource "oci_redis_redis_cluster" "mushop_cache" {
  compartment_id     = var.compartment_ocid
  display_name       = "mushop-cache"
  node_count         = 1
  node_memory_in_gbs = 2
  software_version   = "REDIS_7_0"
  subnet_id          = oci_core_subnet.mushop_node_subnet.id
}
