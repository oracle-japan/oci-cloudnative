resource "oci_ons_notification_topic" "mushop_topic" {
  compartment_id = var.compartment_ocid
  name           = "mushop"
}

resource "oci_ons_subscription" "mushop_subscription" {
  compartment_id = var.compartment_ocid
  topic_id       = oci_ons_notification_topic.mushop_topic.topic_id
  protocol       = "EMAIL"
  endpoint       = var.email_address
}
