param(
  [string]$KeyName = "digitalworld-hermes_ed25519"
)

$sshDir = Join-Path $HOME ".ssh"
$keyPath = Join-Path $sshDir $KeyName

New-Item -ItemType Directory -Force -Path $sshDir | Out-Null

if (Test-Path $keyPath) {
  Write-Host "Key existiert bereits: $keyPath" -ForegroundColor Yellow
} else {
  ssh-keygen -t ed25519 -a 100 -f $keyPath -C "digital-world.dev hermes"
}

Write-Host "Public Key:" -ForegroundColor Green
Get-Content "$keyPath.pub"
