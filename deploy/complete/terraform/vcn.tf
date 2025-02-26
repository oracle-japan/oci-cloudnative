data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All.*"]
    regex  = true
  }
}

locals {
  all_services = data.oci_core_services.all_services.services.0
  protocol = {
    all  = "all"
    icmp = "1"
    tcp  = "6"
  }
}

resource "oci_core_vcn" "mushop_vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = "10.0.0.0/16"
  display_name   = "mushop-vcn"
  dns_label      = "mushop"
}

resource "oci_core_internet_gateway" "mushop_internet_gateway" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.mushop_vcn.id
  display_name   = "mushop-internet-gateway"
  depends_on     = [oci_core_vcn.mushop_vcn]
}

resource "oci_core_nat_gateway" "mushop_nat_gateway" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.mushop_vcn.id
  display_name   = "mushop-nat-gateway"
  depends_on     = [oci_core_vcn.mushop_vcn]
}

resource "oci_core_service_gateway" "mushop_service_gateway" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.mushop_vcn.id
  display_name   = "mushop-service-gateway"
  services {
    service_id = local.all_services.id
  }
  depends_on = [oci_core_vcn.mushop_vcn]
}

resource "oci_core_route_table" "mushop_public_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.mushop_vcn.id
  display_name   = "mushop-public-route-table"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.mushop_internet_gateway.id
  }
  depends_on = [oci_core_vcn.mushop_vcn]
}

resource "oci_core_route_table" "mushop_private_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.mushop_vcn.id
  display_name   = "mushop-private-route-table"
  route_rules {
    destination       = local.all_services.cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.mushop_service_gateway.id
  }
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.mushop_nat_gateway.id
  }
  depends_on = [oci_core_vcn.mushop_vcn]
}

resource "oci_core_security_list" "mushop_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.mushop_vcn.id
  display_name   = "mushop-security-list"
  ingress_security_rules {
    protocol    = local.protocol.tcp
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    protocol    = local.protocol.icmp
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    icmp_options {
      type = "3"
      code = "4"
    }
  }
  ingress_security_rules {
    protocol    = local.protocol.icmp
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    icmp_options {
      type = "3"
    }
  }
  ingress_security_rules {
    protocol    = local.protocol.tcp
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  ingress_security_rules {
    protocol    = local.protocol.tcp
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "6379"
      min = "6379"
    }
  }
  egress_security_rules {
    protocol         = local.protocol.tcp
    destination      = local.all_services.cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    stateless        = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  egress_security_rules {
    protocol         = local.protocol.all
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    stateless        = "false"
  }
  depends_on = [oci_core_vcn.mushop_vcn]
}

resource "oci_core_security_list" "mushop_k8s_api_endpoint_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.mushop_vcn.id
  display_name   = "oke-k8s-api-endpoint-security-list"
  ingress_security_rules {
    protocol    = local.protocol.tcp
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  ingress_security_rules {
    protocol    = local.protocol.tcp
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  ingress_security_rules {
    protocol    = local.protocol.tcp
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "12250"
      min = "12250"
    }
  }
  ingress_security_rules {
    protocol    = local.protocol.icmp
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    icmp_options {
      type = "3"
      code = "4"
    }
  }
  ingress_security_rules {
    protocol    = local.protocol.tcp
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  egress_security_rules {
    protocol         = local.protocol.tcp
    destination      = local.all_services.cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    stateless        = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  egress_security_rules {
    protocol         = local.protocol.tcp
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    stateless        = "false"
  }
  egress_security_rules {
    protocol         = local.protocol.icmp
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    stateless        = "false"
    icmp_options {
      type = "3"
      code = "4"
    }
  }
  egress_security_rules {
    protocol         = local.protocol.all
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    stateless        = "false"
  }
  depends_on = [oci_core_vcn.mushop_vcn]
}

resource "oci_core_security_list" "mushop_node_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.mushop_vcn.id
  display_name   = "oke-node-security-list"
  ingress_security_rules {
    protocol    = local.protocol.all
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    protocol    = local.protocol.icmp
    source      = "10.0.0.0/28"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    icmp_options {
      type = "3"
      code = "4"
    }
  }
  ingress_security_rules {
    protocol    = local.protocol.tcp
    source      = "10.0.10.0/28"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    protocol    = local.protocol.tcp
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    protocol    = local.protocol.tcp
    source      = "10.0.20.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "31687"
      min = "31687"
    }
  }
  ingress_security_rules {
    protocol    = local.protocol.tcp
    source      = "10.0.20.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "10256"
      min = "10256"
    }
  }
  ingress_security_rules {
    protocol    = local.protocol.tcp
    source      = "10.0.20.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "32197"
      min = "32197"
    }
  }
  egress_security_rules {
    protocol         = local.protocol.all
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    stateless        = "false"
  }
  egress_security_rules {
    protocol         = local.protocol.tcp
    destination      = "10.0.0.0/28"
    destination_type = "CIDR_BLOCK"
    stateless        = "false"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  egress_security_rules {
    protocol         = local.protocol.tcp
    destination      = "10.0.0.0/28"
    destination_type = "CIDR_BLOCK"
    stateless        = "false"
    tcp_options {
      max = "12250"
      min = "12250"
    }
  }
  egress_security_rules {
    protocol         = local.protocol.icmp
    destination      = "10.0.0.0/28"
    destination_type = "CIDR_BLOCK"
    stateless        = "false"
    icmp_options {
      type = "3"
      code = "4"
    }
  }
  egress_security_rules {
    protocol         = local.protocol.tcp
    destination      = local.all_services.cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    stateless        = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  egress_security_rules {
    protocol         = local.protocol.icmp
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    stateless        = "false"
    icmp_options {
      type = "3"
      code = "4"
    }
  }
  egress_security_rules {
    protocol         = local.protocol.all
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    stateless        = "false"
  }
  depends_on = [oci_core_vcn.mushop_vcn]
}

resource "oci_core_security_list" "mushop_svclb_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.mushop_vcn.id
  display_name   = "oke-lb-security-list"
  ingress_security_rules {
    protocol    = local.protocol.tcp
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "80"
      min = "80"
    }
  }
  ingress_security_rules {
    protocol    = local.protocol.tcp
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  egress_security_rules {
    protocol         = local.protocol.tcp
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    stateless        = "false"
    tcp_options {
      max = "31687"
      min = "31687"
    }
  }
  egress_security_rules {
    protocol         = local.protocol.tcp
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    stateless        = "false"
    tcp_options {
      max = "10256"
      min = "10256"
    }
  }
  egress_security_rules {
    protocol         = local.protocol.tcp
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    stateless        = "false"
    tcp_options {
      max = "32197"
      min = "32197"
    }
  }
  depends_on = [oci_core_vcn.mushop_vcn]
}


resource "oci_core_subnet" "mushop_k8s_api_endpoint_subnet" {
  cidr_block     = "10.0.0.0/28"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.mushop_vcn.id
  security_list_ids = [
    oci_core_security_list.mushop_k8s_api_endpoint_security_list.id
  ]
  display_name               = "oke-k8s-api-endpoint-subnet"
  route_table_id             = oci_core_route_table.mushop_public_route_table.id
  prohibit_public_ip_on_vnic = false
  dns_label                  = "k8sapi"
  depends_on                 = [oci_core_vcn.mushop_vcn]
}

resource "oci_core_subnet" "mushop_node_subnet" {
  cidr_block     = "10.0.10.0/24"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.mushop_vcn.id
  security_list_ids = [
    oci_core_security_list.mushop_node_security_list.id
  ]
  display_name               = "oke-node-subnet"
  route_table_id             = oci_core_route_table.mushop_private_route_table.id
  prohibit_public_ip_on_vnic = true
  dns_label                  = "node"
  depends_on                 = [oci_core_vcn.mushop_vcn]
}

resource "oci_core_subnet" "mushop_svclb_subnet" {
  cidr_block     = "10.0.20.0/24"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.mushop_vcn.id
  security_list_ids = [
    oci_core_security_list.mushop_svclb_security_list.id
  ]
  display_name               = "oke-svclb-subnet"
  route_table_id             = oci_core_route_table.mushop_public_route_table.id
  prohibit_public_ip_on_vnic = false
  dns_label                  = "svclb"
  depends_on                 = [oci_core_vcn.mushop_vcn]
}

resource "oci_core_subnet" "mushop_public_subnet" {
  cidr_block     = "10.0.30.0/24"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.mushop_vcn.id
  security_list_ids = [
    oci_core_security_list.mushop_security_list.id
  ]
  display_name               = "mushop-public-subnet"
  route_table_id             = oci_core_route_table.mushop_public_route_table.id
  prohibit_public_ip_on_vnic = false
  dns_label                  = "public"
  depends_on                 = [oci_core_vcn.mushop_vcn]
}
