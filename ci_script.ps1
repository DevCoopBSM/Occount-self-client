param (
    [string]$DeploymentPath
)

# 프로세스 이름 설정
$ProcessName = "devcoop_self_counter_v1"

# 기존 프로세스 종료
$process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
if ($process) {
    Write-Host "Stopping existing $ProcessName process..."
    Stop-Process -Name $ProcessName -Force
} else {
    Write-Host "No existing $ProcessName process found."
}

# 애플리케이션 실행
$exePath = Join-Path $DeploymentPath "$ProcessName.exe"
if (Test-Path $exePath) {
    Write-Host "Starting application: $exePath"
    Start-Process -FilePath $exePath
} else {
    Write-Host "Error: Executable not found at $exePath"
}

# 상태 확인
Start-Sleep -Seconds 10
$newProcess = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
if ($newProcess) {
    Write-Host "Application started successfully. Process ID: $($newProcess.Id)"
} else {
    Write-Host "Warning: Application may not have started properly."
}

Write-Host "Deployment process completed."