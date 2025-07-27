# WinRM Configuration Script for Ansible
param([string]$ListenerPort = "5986")

Write-Host "Starting WinRM configuration..." -ForegroundColor Green

try {
    # Create temp directory
    if (!(Test-Path "C:\temp")) { New-Item -ItemType Directory -Path "C:\temp" -Force }

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