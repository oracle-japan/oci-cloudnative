resource "oci_database_autonomous_database" "mushop_atp" {
  compartment_id          = var.compartment_ocid
  display_name            = "mushop-db"
  db_name                 = "mushopdb"
  db_version              = "23ai"
  db_workload             = "OLTP"
  compute_count           = 2
  compute_model           = "ECPU"
  data_storage_size_in_gb = 20
  admin_password          = "oci_Cloud_Native_2025"
  subnet_id               = oci_core_subnet.mushop_public_subnet.id
}
