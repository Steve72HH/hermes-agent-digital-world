param(
  [string]$HostAlias = "hermes-dw",
  [string]$User = "admin",
  [string]$Hostname,
  [string]$KeyName = "digitalworld-hermes_ed25519",
  [int]$Port = 22
)

if (-not $Hostname) {
  $Hostname = Read-Host "Server-IP oder Hostname"
}

$sshDir = Join-Path $HOME ".ssh"
$config = Join-Path $sshDir "config"
$keyPath = Join-Path $sshDir $KeyName

New-Item -ItemType Directory -Force -Path $sshDir | Out-Null

$block = @"

Host $HostAlias
    HostName $Hostname
    User $User
    Port $Port
    IdentityFile $keyPath
    IdentitiesOnly yes
"@

Add-Content -Path $config -Value $block
Write-Host "SSH Config ergänzt. Test:" -ForegroundColor Green
Write-Host "ssh $HostAlias"
