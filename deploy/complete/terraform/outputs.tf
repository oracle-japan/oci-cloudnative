output "mushop_preauthenticated_request_url" {
  value       = oci_objectstorage_preauthrequest.mushop_preauthenticated_request.full_path
  description = "Pre-authenticated URL for Object Storage."
}
