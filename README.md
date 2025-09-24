OCI Developer Workstation (Oracle Linux 9 on A1 Flex)

This repo provisions an Oracle Cloud developer workstation VM with:
- Oracle Linux 9 (AArch64) on `VM.Standard.A1.Flex` (2 OCPUs / 12 GB RAM)
- XFCE + xrdp for remote desktop
- VSCodium (open-source VS Code build, a code-oss equivalent)
- Node.js LTS, Python, Docker (with Compose plugin)
- Lightweight monitoring stack (Prometheus + Grafana + node-exporter + cAdvisor)

Networking opens ports: `22/tcp` (SSH) and `3389/tcp` (RDP). Monitoring ports are internal only.

What gets created
- VCN + public subnet, internet gateway, route table, and security list
- One compute instance with public IP and cloud-init provisioning
- System services for xrdp and monitoring stack via Docker Compose

Inputs and secrets
GitHub Actions expects these repository secrets:
- `OCI_TENANCY_OCID`
- `OCI_USER_OCID`
- `OCI_FINGERPRINT`
- `OCI_REGION`
- One of the following for the private key:
  - `OCI_PRIVATE_KEY_B64` (base64-encoded PEM, preferred), or
  - `OCI_PRIVATE_KEY_PEM` (base64-encoded PEM, alt name), or
  - `OCI_PRIVATE_KEY` (raw PEM content; CI will base64-encode and also write a file fallback)
- `OCI_COMPARTMENT_OCID`
- Optional: `SSH_PUBLIC_KEY` (recommended). If omitted, an RDP password is generated.

Optional tuning secrets for CI retries:
- `OCI_REGION_CANDIDATES`: space-separated list of regions to try (e.g., `uk-london-1 eu-frankfurt-1 eu-amsterdam-1`).
- `OCI_AD_INDEX`: prefer a specific AD index (0-based).
- `OCI_OCPU`: desired OCPUs (default 2); CI falls back to 1 on capacity errors.

Terraform variables (with safe defaults) are in `infra/variables.tf` and can be overridden with TF vars if needed.

Outputs
After apply, GitHub Actions commits `deployment/outputs.json` back to the repo with:
- `public_ip`
- `rdp_username`
- `rdp_password` (only if generated)

RDP (macOS) quick start
- Install Microsoft Remote Desktop from the Mac App Store.
- Connect to the public IP on port 3389.
- Username: `opc`
- Password: from `deployment/outputs.json` (if generated), or your own.

Project layout
- `infra/` – Terraform root and cloud-init template
- `.github/workflows/deploy.yml` – CI that runs Terraform and saves outputs
- `deployment/outputs.json` – Populated by CI after apply

Notes
- Oracle Linux user: `opc` (default). SSH remains key-only; password is used for xrdp only.
- The monitoring stack is local to the VM by default. To expose Grafana/Prometheus, add rules to the security list and firewall.

Capacity fallbacks
- Primary shape defaults to `VM.Standard.A1.Flex` (ARM). CI can auto-fallback to `VM.Standard.E4.Flex` (x86) if A1 capacity is unavailable.
- Configure optional secrets to influence retries:
  - `OCI_REGION_CANDIDATES`: space-separated list of regions to try in order.
  - `OCI_AD_INDEX`: pin a specific AD index.
  - `OCI_OCPU`: desired OCPUs (default 2).
  - `OCI_SHAPE_PRIMARY`: override primary shape (default A1 Flex).
  - `OCI_SHAPE_FALLBACK`: override fallback shape (default E4 Flex).
