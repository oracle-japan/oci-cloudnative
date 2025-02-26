resource "oci_logging_log_group" "mushop_log_group" {
  compartment_id = var.compartment_ocid
  display_name   = "mushop"
}

resource "oci_logging_log" "mushop_devops_log" {
  log_group_id = oci_logging_log_group.mushop_log_group.id
  log_type     = "SERVICE"
  display_name = "mushop-devops-log"
  configuration {
    compartment_id = var.compartment_ocid
    source {
      category    = "all"
      resource    = oci_devops_project.mushop_devops_project.id
      service     = "devops"
      source_type = "OCISERVICE"
    }
  }
}
