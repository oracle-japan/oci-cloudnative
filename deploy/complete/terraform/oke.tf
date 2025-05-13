#data "oci_core_images" "node_pool_images" {
#  compartment_id           = var.compartment_ocid
#  shape                    = "VM.Standard.E5.Flex"
#  operating_system         = "Oracle Linux"
#  operating_system_version = "8"
#  sort_by                  = "TIMECREATED"
#  sort_order               = "DESC"
#}

#locals {
#  oke_image_id = data.oci_core_images.node_pool_images.images[0].id
#}

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.compartment_ocid
  ad_number      = 1
}

data "oci_containerengine_cluster_option" "cluster_option" {
  cluster_option_id = "all"
  compartment_id    = var.compartment_ocid
}

resource "oci_containerengine_cluster" "mushop_oke" {
  compartment_id     = var.compartment_ocid
  vcn_id             = oci_core_vcn.mushop_vcn.id
  name               = "mushop-cluster"
  kubernetes_version = reverse(sort(data.oci_containerengine_cluster_option.cluster_option.kubernetes_versions))[0]
  type               = "ENHANCED_CLUSTER"
  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.mushop_k8s_api_endpoint_subnet.id
  }
  options {
    service_lb_subnet_ids = [oci_core_subnet.mushop_svclb_subnet.id]

    kubernetes_network_config {
      services_cidr = "10.96.0.0/16"
      pods_cidr     = "10.244.0.0/16"
    }
  }
}

locals {
  node_pool_node_shape = data.oci_core_shapes.node_shapes.shapes.0.name
  oke_image_id = data.oci_core_images.node_images.images.0.id
}

data "oci_core_shapes" "node_shapes" {
  compartment_id = var.compartment_ocid
  filter {
    name   = "name"
    values = ["VM.Standard.E.*Flex"]
    regex  = true
  }
}

data "oci_core_images" "node_images" {
  compartment_id = var.compartment_ocid
  filter {
    name   = "display_name"
    values = ["Oracle-Linux-8\\.10-20.*"]
    regex  = true
  }
}

resource "oci_containerengine_node_pool" "mushop_node_pool" {
  cluster_id         = oci_containerengine_cluster.mushop_oke.id
  compartment_id     = var.compartment_ocid
  name               = "mushop-node-pool"
  node_shape         = local.node_pool_node_shape
  kubernetes_version = reverse(sort(data.oci_containerengine_cluster_option.cluster_option.kubernetes_versions))[0]
  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domain.ad.name
      subnet_id           = oci_core_subnet.mushop_node_subnet.id
    }
    size = 3
  }
  node_source_details {
    image_id    = local.oke_image_id
    source_type = "IMAGE"
  }
  node_shape_config {
    ocpus         = 1
    memory_in_gbs = 16
  }
}
