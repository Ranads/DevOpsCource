variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "UAE North"
}

variable "vm_names" {
  description = "Map of VM names"
  type        = map(string)
  default = {
    dev  = "DevOps-Dev"
    test = "DevOps-Test"
    prod = "DevOps-Prod"
  }
}

variable "admin_username" {
  description = "Admin username for SSH"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "/home/ranadunix/.ssh/id_rsa.pub"
}

variable "my_ip" {
  description = "Public IP allowed for SSH/HTTP"
  type        = string
  default     = "0.0.0.0/0"
}
variable "vm_size" {
  description = "The size (SKU) of the Azure VM"
  type        = string
  default     = "Standard_B1s"
}