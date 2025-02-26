resource "oci_streaming_stream_pool" "mushop_stream_pool" {
  compartment_id = var.compartment_ocid
  name           = "mushop-stream-pool"
}

resource "oci_streaming_stream" "mushop_stream_shipments" {
  stream_pool_id     = oci_streaming_stream_pool.mushop_stream_pool.id
  name               = "mushop-shipments"
  partitions         = 1
  retention_in_hours = 24
}

resource "oci_streaming_stream" "mushop_stream_orders" {
  stream_pool_id     = oci_streaming_stream_pool.mushop_stream_pool.id
  name               = "mushop-orders"
  partitions         = 1
  retention_in_hours = 24
}
