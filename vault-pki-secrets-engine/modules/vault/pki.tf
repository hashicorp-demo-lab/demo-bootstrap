resource "vault_mount" "root" {
  path                      = "demo-pki-root"
  type                      = "pki"
  description               = "This is an example root PKI secret engine mount"
  default_lease_ttl_seconds = 31536000
  max_lease_ttl_seconds     = 31536000
}

resource "vault_pki_secret_backend_root_cert" "this" {
  depends_on         = [vault_mount.root]
  backend            = vault_mount.root.path
  type               = "internal"
  common_name        = "Root CA Vault PKI Demo"
  format             = "pem"
  private_key_format = "der"
  key_type           = "rsa"
  key_bits           = 4096
  ttl                = "315360000"
  ou                 = "Solutions Engineering & Architecture "
  organization       = "hashi-demo-lab"
  country            = "AU"
  locality           = "Sydney"
  province           = "NSW"
}

resource "vault_mount" "intermediate" {
  path                      = "demo-pki-intermediate"
  type                      = "pki"
  description               = "This is an example intermediate PKI secret engine mount"
  default_lease_ttl_seconds = 15778800
  max_lease_ttl_seconds     = 15778800
}
resource "vault_pki_secret_backend_intermediate_cert_request" "this" {
  backend     = vault_mount.intermediate.path
  type        = vault_pki_secret_backend_root_cert.this.type
  common_name = "SubOrg Intermediate CA"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "this" {
  backend      = vault_mount.root.path
  csr          = vault_pki_secret_backend_intermediate_cert_request.this.csr
  common_name  = "SubOrg Intermediate CA"
  ou           = "SubUnit"
  organization = "SubOrg"
  country      = "AU"
  locality     = "Sydney"
  province     = "NSW"
  revoke       = true
}

resource "vault_pki_secret_backend_intermediate_set_signed" "example" {
  backend     = vault_mount.intermediate.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.this.certificate
}

resource "vault_pki_secret_backend_config_urls" "this" {
  backend = vault_mount.intermediate.path
  issuing_certificates = [
    "http://127.0.0.1:8200/v1/pki/ca",
  ]
  crl_distribution_points = [
    "http://127.0.0.1:8200/v1/pki/crl",
  ]
}

resource "vault_pki_secret_backend_role" "this" {
  backend          = vault_mount.intermediate.path
  name             = "my_role"
  allowed_domains  = ["example.com", "hashibank.com"]
  allow_subdomains = true
  max_ttl          = 180
  organization     = ["hashi-demo-lab"]
  ou               = ["Solutions Engineering and Architecture"]
}