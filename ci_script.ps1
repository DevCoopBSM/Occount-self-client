param (
    [string]$stage
)

# 작업 디렉토리 설정
$workingDirectory = "C:\Users\KB\Devcoop\devcoop_self_counter_v1"

# 현재 작업 디렉토리 변경
Set-Location $workingDirectory

# 환경 변수 설정
$env:DB_HOST = $env:DB_HOST
echo "DB_HOST: $env:DB_HOST"

switch ($stage) {
    "setup" {
        echo "Setting up Flutter environment..."
        flutter --version
        git pull
    }
    "build" {
        echo "Running pub get..."
        # 기존 프로세스 종료 (counter.exe)
        $process = Get-Process -Name "counter" -ErrorAction SilentlyContinue
        if ($process) {
            echo "Stopping existing counter.exe process..."
            Stop-Process -Name "counter" -Force
        } else {
            echo "No existing counter.exe process found."
        }
        flutter pub get
        echo "Building the Flutter application..."
        flutter build windows --release --dart-define=DB_HOST=$env:DB_HOST

        # 빌드 완료 후 메시지 출력
        echo "Flutter application built successfully."
    }
    "deploy" {
        echo "Deploying the application..."

        # 기존 프로세스 종료 (counter.exe)
        $process = Get-Process -Name "counter" -ErrorAction SilentlyContinue
        if ($process) {
            echo "Stopping existing counter.exe process..."
            Stop-Process -Name "counter" -Force
        } else {
            echo "No existing counter.exe process found."
        }

        # 수동으로 생성한 작업 스케줄러 작업 실행
        $taskName = "StartCounterExeTask"
        schtasks /run /tn $taskName

        # 배포 완료 후 메시지 출력
        echo "Flutter application deployed successfully."
        
        # 로그 파일 읽기 및 출력
        $logFilePath = "C:\Users\KB\Devcoop\devcoop_self_counter_v1\db_host_log.txt"
        if (Test-Path $logFilePath) {
            Get-Content $logFilePath
        } else {
            echo "Log file not found."
        }
    }
    default {
        echo "Invalid stage specified"
        exit 1
    }
}
