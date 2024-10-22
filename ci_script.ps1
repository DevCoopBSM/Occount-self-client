param (
    [string]$stage
)

# 배포 경로 설정
$DeploymentPath = "C:\DeploymentPath"

# GitLab Runner 작업 디렉토리 설정
$BuildPath = $env:CI_PROJECT_DIR

# 프로세스 이름 설정
$ProcessName = "devcoop_self_counter_v1"

# 환경 변수 설정
$env:DB_HOST = $env:DB_HOST
echo "DB_HOST: $env:DB_HOST"

if ($stage -ne "deploy") {
    echo "Only deploy stage is supported"
    exit 1
}

echo "Starting deployment process..."

# 1. 기존 프로세스 종료
$process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
if ($process) {
    echo "Stopping existing $ProcessName process..."
    Stop-Process -Name $ProcessName -Force
} else {
    echo "No existing $ProcessName process found."
}

# 2. 배포 디렉토리 준비
if (-not (Test-Path $DeploymentPath)) {
    New-Item -ItemType Directory -Force -Path $DeploymentPath
    echo "Created deployment directory: $DeploymentPath"
} else {
    echo "Cleaning existing deployment directory..."
    Remove-Item -Path "$DeploymentPath\*" -Recurse -Force
}

# 3. 아티팩트 복사
$ArtifactPath = Join-Path $BuildPath "build_$($env:CI_PIPELINE_ID)"
Write-Host "Checking artifact directory:"
Get-ChildItem -Path $ArtifactPath -Recurse
echo "Copying artifacts from $ArtifactPath to $DeploymentPath"
Copy-Item -Path "$ArtifactPath\*" -Destination $DeploymentPath -Recurse -Force

# 4. 설정 파일 업데이트 (필요한 경우)
# 예: $env:DB_HOST 값을 사용하여 설정 파일 업데이트
# Update-ConfigFile -Path "$DeploymentPath\config.json" -DbHost $env:DB_HOST

# 5. 권한 설정 (필요한 경우)
# 예: Set-Acl -Path $DeploymentPath -AclObject $aclObject

# 6. 애플리케이션 시작
$taskName = "Start${ProcessName}Task"
echo "Starting application using task: $taskName"
schtasks /run /tn $taskName

# 7. 상태 확인
Start-Sleep -Seconds 10  # 애플리케이션이 시작될 때까지 대기
$newProcess = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
if ($newProcess) {
    echo "Application started successfully. Process ID: $($newProcess.Id)"
} else {
    echo "Warning: Application may not have started properly."
}

echo "Deployment process completed."