variable "compartment_ocid" {
  description = "OCID of the compartment to create resources in"
  type        = string
}

variable "region" {
  description = "OCI region identifier (e.g., us-ashburn-1)"
  type        = string
}

variable "tenancy_ocid" {
  description = "OCI Tenancy OCID (for provider auth)"
  type        = string
  default     = ""
}

variable "user_ocid" {
  description = "OCI User OCID (for provider auth)"
  type        = string
  default     = ""
}

variable "fingerprint" {
  description = "OCI API key fingerprint (for provider auth)"
  type        = string
  default     = ""
}

variable "private_key_path" {
  description = "Path to OCI API private key (for provider auth)"
  type        = string
  default     = ""
}

variable "private_key" {
  description = "Base64-encoded OCI API private key content (preferred)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssh_public_key" {
  description = "SSH public key for opc user (optional)"
  type        = string
  default     = ""
}

variable "display_name" {
  description = "Display name for the instance"
  type        = string
  default     = "dev-workstation-ol9-a1"
}

variable "ad_index" {
  description = "Availability domain index (0-based)"
  type        = number
  default     = 0
}

variable "vcn_cidr" {
  description = "CIDR for the VCN"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet"
  type        = string
  default     = "10.10.1.0/24"
}

variable "ocpus" {
  description = "Number of OCPUs for A1 Flex"
  type        = number
  default     = 1
}

variable "memory_gbs" {
  description = "Memory (GB) for A1 Flex"
  type        = number
  default     = 6
}

variable "shape" {
  description = "Compute shape (e.g., VM.Standard.A1.Flex or VM.Standard.E4.Flex)"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "tags" {
  description = "Freeform tags"
  type        = map(string)
  default     = { project = "dev-workstation" }
}
