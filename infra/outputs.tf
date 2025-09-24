output "rdp_username" {
  description = "RDP username"
  value       = "opc"
}

output "rdp_password" {
  description = "RDP password if generated (blank when SSH key provided and password not forced)"
  value       = try(random_password.rdp_password.result, "")
  sensitive   = true
}
