# Ansible + Terraform VMware vSphere Automation

A comprehensive infrastructure-as-code solution for provisioning and configuring VMware vSphere virtual machines using Terraform for infrastructure provisioning and Ansible for configuration management.

## 🚀 Features

- **Automated VM Provisioning**: Deploy multiple VMs simultaneously with custom specifications
- **Infrastructure as Code**: Declarative configuration using Terraform
- **Configuration Management**: Post-deployment configuration with Ansible
- **Template-Based Deployment**: Clone VMs from existing templates with customization
- **Network Configuration**: Static IP assignment and network customization
- **Security Hardening**: Basic firewall configuration and SSH key management
- **Modular Design**: Reusable roles and organized project structure
- **Vault Integration**: Secure credential management with Ansible Vault

## 📋 Prerequisites

### Software Requirements

- **Ansible** >= 2.12
- **Terraform** >= 1.0
- **Python** >= 3.8
- **SSH access** to target VMs

### VMware vSphere Requirements

- VMware vSphere environment (vCenter Server)
- VM template prepared for cloning (Ubuntu/CentOS recommended)
- Appropriate permissions for VM creation and management
- Network and storage resources configured
- DNS resolution for vCenter Server

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

**Verify Installation:**
```bash
terraform version
ansible --version
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

# VM Template
vm_template: "ubuntu-20.04-template"
```

### 2. VM Specifications

Define your VMs in the `vms` list:

```yaml
vms:
  - name: "web-server-01"
    cpu: 2
    memory: 4096
    disk_size: 40
    network: "VM Network"
    ip: "192.168.1.100"
    gateway: "192.168.1.1"
    dns: ["8.8.8.8", "8.8.4.4"]
  
  - name: "db-server-01"
    cpu: 4
    memory: 8192
    disk_size: 100
    network: "VM Network"
    ip: "192.168.1.101"
    gateway: "192.168.1.1"
    dns: ["8.8.8.8", "8.8.4.4"]
```

### 3. Secure Credentials

Create an Ansible Vault file for sensitive information:

```bash
ansible-vault create inventory/group_vars/vault.yml
```

Add your vCenter password:
```yaml
vault_vcenter_password: "your_vcenter_password_here"
```

### 4. SSH Key Setup

Ensure you have SSH keys generated:
```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

The public key (`~/.ssh/id_rsa.pub`) will be automatically deployed to VMs.

## 🚀 Usage

### Quick Start

Deploy complete infrastructure with a single command:

```bash
ansible-playbook playbooks/site.yml --ask-vault-pass
```

### Step-by-Step Deployment

#### 1. Provision Infrastructure Only

```bash
ansible-playbook playbooks/provision.yml --ask-vault-pass
```

#### 2. Configure VMs Only

```bash
ansible-playbook playbooks/configure.yml
```

### Advanced Usage

#### Deploy with Custom Variables

```bash
ansible-playbook playbooks/site.yml --ask-vault-pass -e "vm_template=centos-8-template"
```

#### Check Playbook Syntax

```bash
ansible-playbook playbooks/site.yml --syntax-check
```

#### Dry Run

```bash
ansible-playbook playbooks/site.yml --check --ask-vault-pass
```

### Standalone Terraform Usage

If you prefer to use Terraform directly:

```bash
cd terraform
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## 📁 Project Structure

```
ansible-vsphere-project/
├── README.md
├── ansible.cfg                 # Ansible configuration
├── requirements.yml            # Required collections
├── inventory/
│   ├── hosts.yml              # Inventory file
│   └── group_vars/
│       ├── all.yml            # Global variables
│       └── vault.yml          # Encrypted variables
├── playbooks/
│   ├── site.yml               # Main playbook
│   ├── provision.yml          # Infrastructure provisioning
│   └── configure.yml          # VM configuration
├── roles/
│   ├── terraform/             # Terraform automation role
│   │   ├── tasks/main.yml
│   │   ├── templates/
│   │   │   ├── main.tf.j2
│   │   │   ├── variables.tf.j2
│   │   │   └── terraform.tfvars.j2
│   │   └── vars/main.yml
│   └── vm-config/             # VM configuration role
│       ├── tasks/main.yml
│       ├── handlers/main.yml
│       └── templates/
└── terraform/                 # Standalone Terraform files
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── terraform.tfvars
```

## 🔧 Customization

### Adding New VMs

1. Add VM specification to `inventory/group_vars/all.yml`:
   ```yaml
   vms:
     - name: "app-server-01"
       cpu: 2
       memory: 2048
       disk_size: 30
       ip: "192.168.1.102"
       # ... other parameters
   ```

2. Run the provisioning playbook:
   ```bash
   ansible-playbook playbooks/provision.yml --ask-vault-pass
   ```

### Custom VM Configuration

Modify `roles/vm-config/tasks/main.yml` to add custom configuration tasks:

```yaml
- name: Install custom applications
  package:
    name:
      - docker.io
      - nginx
      - mysql-server
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
ansible-playbook playbooks/site.yml -e @inventory/group_vars/production.yml
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Authentication Failures
```bash
# Verify vCenter connectivity
ping vcenter.example.com

# Check credentials
ansible-vault view inventory/group_vars/vault.yml
```

#### 2. Template Not Found
```bash
# List available templates in vCenter
# Update vm_template variable in all.yml
```

#### 3. Network Configuration Issues
```bash
# Verify network name in vCenter
# Check IP address conflicts
# Ensure gateway is reachable
```

#### 4. Terraform State Issues
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

Check Ansible logs:
```bash
tail -f /var/log/ansible.log
```

## 🔒 Security Considerations

- Store all passwords in Ansible Vault
- Use SSH key authentication instead of passwords
- Regularly rotate vCenter credentials
- Implement network segmentation
- Enable VM encryption if required
- Regular security updates on templates

## 📚 Resources

- [Ansible VMware Collection Documentation](https://docs.ansible.com/ansible/latest/collections/community/vmware/)
- [Terraform vSphere Provider](https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs)
- [VMware vSphere API Documentation](https://developer.vmware.com/apis/vsphere-automation/latest/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:

1. Check the [Troubleshooting](#-troubleshooting) section
2. Review [Issues](../../issues) for known problems
3. Create a new [Issue](../../issues/new) for bug reports
4. Join our [Discussions](../../discussions) for general questions

## 🏷️ Version History

- **v1.0.0** - Initial release with basic VM provisioning
- **v1.1.0** - Added configuration management
- **v1.2.0** - Enhanced security and vault integration

---

**Built with ❤️ using Ansible and Terraform**