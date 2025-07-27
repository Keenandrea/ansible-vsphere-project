{% for vm in vms %}
output "{{ vm.name | replace('-', '_') }}_ip" {
  description = "IP address of {{ vm.name }}"
  value       = vsphere_virtual_machine.{{ vm.name | replace('-', '_') }}.default_ip_address
}

output "{{ vm.name | replace('-', '_') }}_id" {
  description = "VM ID of {{ vm.name }}"
  value       = vsphere_virtual_machine.{{ vm.name | replace('-', '_') }}.id
}
{% endfor %}
