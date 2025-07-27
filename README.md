# Ansible + Terraform VMware vSphere Automation

A comprehensive infrastructure-as-code solution for provisioning and configuring both Linux and Windows VMware vSphere virtual machines using Terraform for infrastructure provisioning and Ansible for configuration management.

## 🚀 Features

- **Multi-OS Support**: Deploy both Linux and Windows VMs simultaneously
- **Automated VM Provisioning**: Deploy multiple VMs with custom specifications
- **Infrastructure as Code**: Declarative configuration using Terraform
- **Dual Configuration Management**: Post-deployment configuration with Ansible for both SSH (Linux) and WinRM (Windows)
- **Template-Based Deployment**: Clone VMs from existing templates with customization
- **Network Configuration**: Static IP assignment and network customization
- **Security Hardening**: SSH key management for Linux, WinRM HTTPS for Windows
- **Windows Package Management**: Chocolatey integration for Windows software installation
- **Automated Updates**: Linux package updates and Windows Update management
- **Modular Design**: Reusable roles and organized project structure
- **Vault Integration**: Secure credential management with Ansible Vault

## 📋 Prerequisites

### Software Requirements

- **Ansible** >= 2.12
- **Terraform** >= 1.0
- **Python** >= 3.8
- **SSH access** to target Linux VMs
- **WinRM access** to target Windows VMs

### VMware vSphere Requirements

- VMware vSphere environment (vCenter Server)
- **Linux VM template** prepared for cloning (Ubuntu/CentOS recommended)
- **Windows VM template** prepared for cloning (Windows Server 2016/2019/2022)
- VMware Tools installed on both templates
- Appropriate permissions for VM creation and management
- Network and storage resources configured
- DNS resolution for vCenter Server

### Windows Template Requirements

- Windows Server 2016/2019/2022 template
- Administrator account enabled and accessible
- PowerShell execution policy allowing script execution
- Network configured for static IP assignment
- Windows Firewall configured to allow initial connections

### Permissions Required

Your vSphere user account needs the following permissions:
- Datastore > Allocate space
- Network > Assign network
- Resource > Assign virtual machine to resource pool
- Virtual machine > Configuration (all)
- Virtual machine > Interaction (all)
- Virtual machine > Inventory (all)
- Virtual machine > Provisioning (all)

## 🛠️ Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd ansible-vsphere-project
```

### 2. Install Ansible Collections

```bash
ansible-galaxy collection install -r requirements.yml
```

### 3. Install Terraform

**macOS (Homebrew):**
```bash
brew install terraform
```

**Linux (Ubuntu/Debian):**
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### 4. Install Windows Support (Optional)

If managing Windows VMs from a Linux control machine:
```bash
pip install pywinrm
```

**Verify Installation:**
```bash
terraform version
ansible --version
ansible-doc -l | grep win_ # Should show Windows modules
```

## ⚙️ Configuration

### 1. Environment Variables

Update `inventory/group_vars/all.yml` with your vSphere environment details:

```yaml
# vSphere Connection Details
vcenter_hostname: "vcenter.example.com"
vcenter_username: "administrator@vsphere.local"
vcenter_datacenter: "Datacenter1"
vcenter_cluster: "Cluster1"
vcenter_datastore: "datastore1"
vcenter_network: "VM Network"

# Templates
vm_template: "ubuntu-20.04-template"        # Default Linux template
windows_template: "windows-2019-template"   # Windows template

# Windows Configuration
windows_admin_user: "Administrator"
winrm_port: 5986
winrm_transport: "ssl"
```

### 2. Mixed Environment VM Specifications

Define both Linux and Windows VMs in the `vms` list:

```yaml
vms:
  # Linux VMs
  - name: "web-server-01"
    cpu: 2
    memory: 4096
    disk_size: 40
    network: "VM Network"
    ip: "192.168.1.100"
    gateway: "192.168.1.1"
    dns: ["8.8.8.8", "8.8.4.4"]
    os_type: "linux"
    template: "ubuntu-20.04-template"
  
  - name: "db-server-01"
    cpu: 4
    memory: 8192
    disk_size: 100
    network: "VM Network"
    ip: "192.168.1.101"
    gateway: "192.168.1.1"
    dns: ["8.8.8.8", "8.8.4.4"]
    os_type: "linux"
    template: "ubuntu-20.04-template"
  
  # Windows VMs
  - name: "win-server-01"
    cpu: 4
    memory: 8192
    disk_size: 80
    network: "VM Network"
    ip: "192.168.1.102"
    gateway: "192.168.1.1"
    dns: ["8.8.8.8", "8.8.4.4"]
    os_type: "windows"
    template: "windows-2019-template"
    admin_password: "{{ vault_windows_admin_password }}"
  
  - name: "win-app-01"
    cpu: 2
    memory: 4096
    disk_size: 60
    network: "VM Network"
    ip: "192.168.1.103"
    gateway: "192.168.1.1"
    dns: ["8.8.8.8", "8.8.4.4"]
    os_type: "windows"
    template: "windows-2019-template"
    admin_password: "{{ vault_windows_admin_password }}"
```

### 3. Secure Credentials

Create an Ansible Vault file for sensitive information:

```bash
ansible-vault create inventory/group_vars/vault.yml
```

Add your credentials:
```yaml
# vCenter credentials
vault_vcenter_password: "your_vcenter_password_here"

# Windows VM credentials
vault_windows_admin_password: "YourSecureWindowsPassword123!"
vault_windows_ansible_password: "AnotherSecurePassword456!"
```

### 4. WinRM Configuration Script

Create the PowerShell script for WinRM configuration:

```bash
mkdir -p terraform/scripts
```

Create `terraform/scripts/ConfigureWinRM.ps1` with the following content:

```powershell
# WinRM Configuration Script for Ansible
param([string]$ListenerPort = "5986")

Write-Host "Starting WinRM configuration..." -ForegroundColor Green

try {
    # Create temp directory
    if (!(Test-Path "C:\temp")) { 
        New-Item -ItemType Directory -Path "C:\temp" -Force 
    }

    # Enable WinRM
    Enable-PSRemoting -Force -SkipNetworkProfileCheck
    Set-Service -Name WinRM -StartupType Automatic

    # Configure WinRM settings
    winrm set winrm/config '@{MaxTimeoutms="1800000"}'
    winrm set winrm/config/service '@{AllowUnencrypted="false"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'
    winrm set winrm/config/service/auth '@{CredSSP="true"}'

    # Create certificate and HTTPS listener
    $cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My
    New-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{Transport="HTTPS";Address="*"} -ValueSet @{Hostname=$env:COMPUTERNAME;CertificateThumbprint=$cert.Thumbprint;Port=$ListenerPort}

    # Configure firewall
    netsh advfirewall firewall add rule name="WinRM HTTPS" dir=in action=allow protocol=TCP localport=$ListenerPort
    netsh advfirewall firewall add rule name="WinRM HTTP" dir=in action=allow protocol=TCP localport=5985

    Write-Host "WinRM configured successfully!" -ForegroundColor Green
    "WinRM configured at $(Get-Date)" | Out-File -FilePath "C:\temp\winrm-config.log"

} catch {
    Write-Error "WinRM configuration failed: $($_.Exception.Message)"
    exit 1
}
```

### 5. SSH Key Setup (Linux VMs)

Ensure you have SSH keys generated for Linux VMs:
```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

The public key (`~/.ssh/id_rsa.pub`) will be automatically deployed to Linux VMs.

## 🚀 Usage

### Quick Start - Mixed Environment

Deploy complete infrastructure with both Linux and Windows VMs:

```bash
ansible-playbook playbooks/site.yml --ask-vault-pass
```

### Step-by-Step Deployment

#### 1. Provision Infrastructure Only

```bash
ansible-playbook playbooks/provision.yml --ask-vault-pass
```

#### 2. Configure All VMs

```bash
ansible-playbook playbooks/configure.yml --ask-vault-pass
```

#### 3. Configure Only Linux VMs

```bash
ansible-playbook playbooks/configure.yml --ask-vault-pass --limit linux_vms
```

#### 4. Configure Only Windows VMs

```bash
ansible-playbook playbooks/configure.yml --ask-vault-pass --limit windows_vms
```

### Testing Connectivity

#### Test Linux VMs (SSH)
```bash
ansible linux_vms -m ping
ansible linux_vms -m shell -a "uname -a"
```

#### Test Windows VMs (WinRM)
```bash
ansible windows_vms -m win_ping
ansible windows_vms -m win_shell -a "Get-ComputerInfo | Select-Object WindowsProductName, TotalPhysicalMemory"
```

#### Test All VMs
```bash
# This will use appropriate connection method for each OS
ansible vms -m ping             # Linux VMs only
ansible windows_vms -m win_ping # Windows VMs only
```

### Advanced Usage

#### Deploy with Custom Variables

```bash
ansible-playbook playbooks/site.yml --ask-vault-pass -e "vm_template=centos-8-template"
```

#### Windows-Specific Operations

```bash
# Install software via Chocolatey
ansible windows_vms -m win_chocolatey -a "name=firefox state=present"

# Manage Windows services
ansible windows_vms -m win_service -a "name=Spooler state=started"

# Run PowerShell commands
ansible windows_vms -m win_shell -a "Get-Service | Where-Object Status -eq 'Running'"

# Check Windows updates
ansible windows_vms -m win_updates -a "category_names=['SecurityUpdates'] state=searched"
```

#### Linux-Specific Operations

```bash
# Install packages
ansible linux_vms -m package -a "name=nginx state=present" --become

# Manage services
ansible linux_vms -m service -a "name=nginx state=started enabled=yes" --become

# Run shell commands
ansible linux_vms -m shell -a "df -h"
```

### Remote Access

#### Windows VMs
```bash
# RDP (if enabled)
mstsc /v:192.168.1.102

# PowerShell remoting
Enter-PSSession -ComputerName 192.168.1.102 -Credential Administrator
```

#### Linux VMs
```bash
# SSH
ssh ubuntu@192.168.1.100
```

### Standalone Terraform Usage

If you prefer to use Terraform directly:

```bash
cd terraform
# Ensure ConfigureWinRM.ps1 exists in scripts/ directory
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## 📁 Project Structure

```
ansible-vsphere-project/
├── README.md
├── ansible.cfg                 # Ansible configuration
├── requirements.yml            # Required collections (includes Windows)
├── inventory/
│   ├── hosts.yml              # Inventory file
│   └── group_vars/
│       ├── all.yml            # Global variables
│       └── vault.yml          # Encrypted variables
├── playbooks/
│   ├── site.yml               # Main playbook
│   ├── provision.yml          # Infrastructure provisioning
│   └── configure.yml          # VM configuration (Linux + Windows)
├── roles/
│   ├── terraform/             # Terraform automation role
│   │   ├── tasks/main.yml
│   │   ├── templates/
│   │   │   ├── main.tf.j2     # Supports both Linux and Windows
│   │   │   ├── variables.tf.j2
│   │   │   └── terraform.tfvars.j2
│   │   └── vars/main.yml
│   ├── vm-config/             # Linux VM configuration role
│   │   ├── tasks/main.yml
│   │   ├── handlers/main.yml
│   │   └── templates/
│   └── windows-config/        # Windows VM configuration role
│       ├── tasks/main.yml
│       ├── handlers/main.yml
│       └── templates/
└── terraform/                 # Standalone Terraform files
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── terraform.tfvars
    └── scripts/
        └── ConfigureWinRM.ps1  # Windows WinRM setup script
```

## 🔧 Customization

### Adding New VMs

#### Linux VM
```yaml
vms:
  - name: "new-linux-server"
    cpu: 2
    memory: 4096
    disk_size: 50
    ip: "192.168.1.110"
    os_type: "linux"
    template: "ubuntu-22.04-template"
    # ... other parameters
```

#### Windows VM
```yaml
vms:
  - name: "new-windows-server"
    cpu: 4
    memory: 8192
    disk_size: 80
    ip: "192.168.1.111"
    os_type: "windows"
    template: "windows-2022-template"
    admin_password: "{{ vault_windows_admin_password }}"
    # ... other parameters
```

### Custom Linux Configuration

Modify `roles/vm-config/tasks/main.yml`:

```yaml
- name: Install custom applications
  package:
    name:
      - docker.io
      - nginx
      - mysql-server
    state: present
```

### Custom Windows Configuration

Modify `roles/windows-config/tasks/main.yml`:

```yaml
- name: Install custom Windows software
  win_chocolatey:
    name:
      - iis
      - sql-server-express
      - visual-studio-code
    state: present

- name: Configure IIS
  win_feature:
    name: IIS-WebServerRole
    state: present
```

### Multiple Environments

Create environment-specific variable files:

```bash
inventory/group_vars/
├── production.yml
├── staging.yml
└── development.yml
```

Use with:
```bash
ansible-playbook playbooks/site.yml -e @inventory/group_vars/production.yml --ask-vault-pass
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Authentication Failures
```bash
# Verify vCenter connectivity
ping vcenter.example.com

# Check credentials
ansible-vault view inventory/group_vars/vault.yml

# Test Windows WinRM connectivity
ansible windows_vms -m win_ping -vvv
```

#### 2. WinRM Connection Issues
```bash
# Check WinRM listeners on Windows VM
ansible windows_vms -m win_shell -a "winrm enumerate winrm/config/listener"

# Verify firewall rules
ansible windows_vms -m win_shell -a "netsh advfirewall firewall show rule name='WinRM HTTPS'"

# Test from Ansible control machine
telnet 192.168.1.102 5986
```

#### 3. Template Not Found
```bash
# List available templates in vCenter UI
# Update vm_template/template variables in all.yml
```

#### 4. Network Configuration Issues
```bash
# Verify network name in vCenter
# Check for IP address conflicts
# Ensure gateway is reachable from both Windows and Linux VMs
```

#### 5. Windows PowerShell Execution Policy
```bash
# Check execution policy on Windows VM
ansible windows_vms -m win_shell -a "Get-ExecutionPolicy"

# Set execution policy if needed
ansible windows_vms -m win_shell -a "Set-ExecutionPolicy RemoteSigned -Force"
```

#### 6. Terraform State Issues
```bash
# Reset Terraform state (use with caution)
cd terraform
terraform destroy
rm -rf .terraform terraform.tfstate*
terraform init
```

### Debug Mode

Enable verbose output:
```bash
ansible-playbook playbooks/site.yml -vvv --ask-vault-pass
```

### Logging

Check Ansible logs for both connection types:
```bash
tail -f /var/log/ansible.log
```

## 🔒 Security Considerations

### General Security
- Store all passwords in Ansible Vault
- Regularly rotate vCenter credentials
- Implement network segmentation
- Enable VM encryption if required
- Regular security updates on templates

### Linux-Specific Security
- Use SSH key authentication instead of passwords
- Disable root login via SSH
- Configure firewall rules (UFW/iptables)
- Regular package updates

### Windows-Specific Security
- Use strong Administrator passwords
- Configure Windows Firewall appropriately
- Enable Windows Defender or alternative antivirus
- Regular Windows Updates
- Consider disabling WinRM HTTP listener after setup
- Use HTTPS WinRM connections only in production

### WinRM Security Best Practices
```yaml
# Disable HTTP listener after initial setup
- name: Remove WinRM HTTP listener (production)
  win_shell: |
    Remove-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{Address="*";Transport="HTTP"}
  when: environment == "production"
```

## 📚 Resources

- [Ansible VMware Collection Documentation](https://docs.ansible.com/ansible/latest/collections/community/vmware/)
- [Ansible Windows Documentation](https://docs.ansible.com/ansible/latest/user_guide/windows.html)
- [Terraform vSphere Provider](https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs)
- [WinRM Configuration Guide](https://docs.ansible.com/ansible/latest/user_guide/windows_setup.html)
- [VMware vSphere API Documentation](https://developer.vmware.com/apis/vsphere-automation/latest/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [PowerShell DSC with Ansible](https://docs.ansible.com/ansible/latest/collections/ansible/windows/win_dsc_module.html)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Test with both Linux and Windows VMs
4. Commit your changes (`git commit -m 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:

1. Check the [Troubleshooting](#-troubleshooting) section
2. Review [Issues](../../issues) for known problems
3. Create a new [Issue](../../issues/new) for bug reports
4. Join our [Discussions](../../discussions) for general questions

### Platform-Specific Support

- **Linux Issues**: Include `ansible linux_vms -m setup` output
- **Windows Issues**: Include `ansible windows_vms -m win_shell -a "Get-ComputerInfo"` output
- **WinRM Issues**: Include firewall and listener configuration details

## 🏷️ Version History

- **v1.0.0** - Initial release with Linux VM provisioning
- **v1.1.0** - Added configuration management for Linux
- **v1.2.0** - Enhanced security and vault integration
- **v2.0.0** - **Added Windows VM support with WinRM configuration**
- **v2.1.0** - **Enhanced mixed environment management and Chocolatey integration**

---

**Built with ❤️ using Ansible and Terraform for Multi-Platform Infrastructure Automation**