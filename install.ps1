Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoUrl = if ($env:REPO_URL) { $env:REPO_URL } else { "https://github.com/notysozu/kelsa.ai" }
$RepoBranch = if ($env:REPO_BRANCH) { $env:REPO_BRANCH } else { "main" }
$DefaultDirName = if ($env:DEFAULT_DIR_NAME) { $env:DEFAULT_DIR_NAME } else { "kelsa.ai" }
$InstallDir = if ($env:INSTALL_DIR) { $env:INSTALL_DIR } else { "" }
$StartApp = if ($env:START_APP) { $env:START_APP } else { "1" }
$InstallUpdate = if ($env:INSTALL_UPDATE) { $env:INSTALL_UPDATE } else { "0" }
$AppHost = if ($env:APP_HOST_VALUE) { $env:APP_HOST_VALUE } else { "0.0.0.0" }
$AppPort = if ($env:APP_PORT_VALUE) { $env:APP_PORT_VALUE } else { "8090" }
$AppReload = if ($env:APP_RELOAD_VALUE) { $env:APP_RELOAD_VALUE } else { "false" }

function Write-Log {
    param([string]$Message)
    Write-Host "[kelsa-install] $Message"
}

function Fail {
    param([string]$Message)
    throw "[kelsa-install] $Message"
}

function Test-Command {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-PythonVersion {
    param([string]$CommandName)
    try {
        & $CommandName -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" | Out-Null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Refresh-ProcessPath {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $segments = @($env:Path, $machinePath, $userPath) | Where-Object { $_ }
    $env:Path = ($segments -join ";")
}

function Get-PythonCommand {
    foreach ($candidate in @("py", "python", "python3")) {
        if (Test-Command $candidate) {
            if ($candidate -eq "py") {
                try {
                    & py -3.11 -c "import sys; print(sys.executable)" 2>$null | Out-Null
                    if ($LASTEXITCODE -eq 0) {
                        return "py -3.11"
                    }
                }
                catch {}

                try {
                    & py -3 -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" 2>$null | Out-Null
                    if ($LASTEXITCODE -eq 0) {
                        return "py -3"
                    }
                }
                catch {}
            }
            elseif (Test-PythonVersion $candidate) {
                return $candidate
            }
        }
    }

    return $null
}

function Invoke-Python {
    param(
        [Parameter(Mandatory = $true)][string]$PythonCommand,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    if ($PythonCommand.StartsWith("py ")) {
        $parts = $PythonCommand.Split(" ")
        & py $parts[1] @Arguments
    }
    else {
        & $PythonCommand @Arguments
    }

    if ($LASTEXITCODE -ne 0) {
        Fail "Python command failed: $PythonCommand $($Arguments -join ' ')"
    }
}

function Invoke-PythonCapture {
    param(
        [Parameter(Mandatory = $true)][string]$PythonCommand,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    if ($PythonCommand.StartsWith("py ")) {
        $parts = $PythonCommand.Split(" ")
        $output = & py $parts[1] @Arguments
    }
    else {
        $output = & $PythonCommand @Arguments
    }

    if ($LASTEXITCODE -ne 0) {
        Fail "Python command failed: $PythonCommand $($Arguments -join ' ')"
    }

    return ($output | Out-String).Trim()
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Install-SystemDependencies {
    if (Test-Command "winget") {
        Write-Log "Installing Git and Python with winget if needed"
        if (-not (Test-Command "git")) {
            & winget install --id Git.Git --silent --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -ne 0) { Fail "winget could not install Git" }
        }
        if (-not (Get-PythonCommand)) {
            & winget install --id Python.Python.3.11 --silent --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -ne 0) { Fail "winget could not install Python" }
        }
        Refresh-ProcessPath
        return
    }

    if (Test-Command "choco") {
        Write-Log "Installing Git and Python with Chocolatey if needed"
        if (-not (Test-Command "git")) {
            & choco install git -y
            if ($LASTEXITCODE -ne 0) { Fail "Chocolatey could not install Git" }
        }
        if (-not (Get-PythonCommand)) {
            & choco install python311 -y
            if ($LASTEXITCODE -ne 0) { Fail "Chocolatey could not install Python" }
        }
        Refresh-ProcessPath
        return
    }

    Fail "Neither winget nor choco is available. Install Git and Python 3.10+ manually, then rerun."
}

function Resolve-ProjectDir {
    $cwd = (Get-Location).Path
    if ((Test-Path (Join-Path $cwd "main.py")) -and (Test-Path (Join-Path $cwd "requirements.txt")) -and (Test-Path (Join-Path $cwd "index.html"))) {
        return $cwd
    }

    if ($InstallDir) {
        return $InstallDir
    }

    return (Join-Path $cwd $DefaultDirName)
}

function Prepare-Repo {
    param([string]$ProjectDir)

    if ((Test-Path (Join-Path $ProjectDir "main.py")) -and (Test-Path (Join-Path $ProjectDir "requirements.txt"))) {
        Write-Log "Using existing project checkout at $ProjectDir"
        if ($InstallUpdate -eq "1" -and (Test-Path (Join-Path $ProjectDir ".git"))) {
            Write-Log "Refreshing repository because INSTALL_UPDATE=1"
            git -C $ProjectDir fetch origin $RepoBranch
            git -C $ProjectDir pull --ff-only origin $RepoBranch
        }
        return
    }

    if ((Test-Path $ProjectDir) -and -not (Test-Path $ProjectDir -PathType Container)) {
        Fail "Install target exists but is not a directory: $ProjectDir"
    }

    Write-Log "Cloning repository into $ProjectDir"
    git clone --branch $RepoBranch --single-branch $RepoUrl $ProjectDir
    if ($LASTEXITCODE -ne 0) {
        Fail "git clone failed"
    }
}

function Ensure-EnvFile {
    param(
        [string]$ProjectDir,
        [string]$PythonCommand
    )

    $envFile = Join-Path $ProjectDir ".env"
    $exampleFile = Join-Path $ProjectDir ".env.example"

    if (-not (Test-Path $envFile)) {
        if (Test-Path $exampleFile) {
            Copy-Item $exampleFile $envFile
            Write-Log "Created .env from .env.example"
        }
        else {
            $defaultEnv = @"
SESSION_SECRET=
APP_HOST=$AppHost
APP_PORT=$AppPort
APP_RELOAD=$AppReload
SESSION_COOKIE_SECURE=false
SESSION_COOKIE_SAMESITE=lax
SESSION_COOKIE_MAX_AGE=604800
AUTOMATION_API_KEY=
HINDSIGHT_ENABLED=false
HINDSIGHT_BASE_URL=https://api.hindsight.vectorize.io
HINDSIGHT_API_KEY=
"@
            Write-Utf8NoBom -Path $envFile -Content $defaultEnv
            Write-Log "Created .env with default values"
        }
    }
    else {
        Write-Log "Keeping existing .env"
    }

    $sessionSecret = Invoke-PythonCapture -PythonCommand $PythonCommand -Arguments @("-c", "import secrets; print(secrets.token_urlsafe(48))")
    $automationKey = Invoke-PythonCapture -PythonCommand $PythonCommand -Arguments @("-c", "import secrets; print(secrets.token_urlsafe(32))")

    $content = Get-Content -Path $envFile
    $placeholders = @(
        "replace-with-a-long-random-secret",
        "replace-with-a-shared-secret-for-n8n",
        "replace-this-with-a-long-random-secret"
    )

    $defaults = [ordered]@{
        "SESSION_SECRET" = $sessionSecret
        "APP_HOST" = $AppHost
        "APP_PORT" = $AppPort
        "APP_RELOAD" = $AppReload
        "SESSION_COOKIE_SECURE" = "false"
        "SESSION_COOKIE_SAMESITE" = "lax"
        "SESSION_COOKIE_MAX_AGE" = "604800"
        "AUTOMATION_API_KEY" = $automationKey
        "HINDSIGHT_ENABLED" = "false"
        "HINDSIGHT_BASE_URL" = "https://api.hindsight.vectorize.io"
        "HINDSIGHT_API_KEY" = ""
    }

    $seen = New-Object System.Collections.Generic.HashSet[string]
    $updated = New-Object System.Collections.Generic.List[string]

    foreach ($line in $content) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#") -or -not $line.Contains("=")) {
            $updated.Add($line)
            continue
        }

        $parts = $line.Split("=", 2)
        $key = $parts[0]
        $value = $parts[1].Trim()
        [void]$seen.Add($key)

        if ($key -eq "SESSION_SECRET" -and ([string]::IsNullOrWhiteSpace($value) -or $placeholders -contains $value)) {
            $updated.Add("$key=$sessionSecret")
        }
        elseif ($key -eq "AUTOMATION_API_KEY" -and ([string]::IsNullOrWhiteSpace($value) -or $placeholders -contains $value)) {
            $updated.Add("$key=$automationKey")
        }
        elseif (($key -in @("APP_HOST", "APP_PORT", "APP_RELOAD")) -and [string]::IsNullOrWhiteSpace($value)) {
            $updated.Add("$key=$($defaults[$key])")
        }
        else {
            $updated.Add($line)
        }
    }

    foreach ($entry in $defaults.GetEnumerator()) {
        if (-not $seen.Contains($entry.Key)) {
            $updated.Add("$($entry.Key)=$($entry.Value)")
        }
    }

    Write-Utf8NoBom -Path $envFile -Content (($updated -join "`n").TrimEnd() + "`n")
}

function Setup-Venv {
    param(
        [string]$ProjectDir,
        [string]$PythonCommand
    )

    $venvDir = Join-Path $ProjectDir ".venv"
    $venvPython = Join-Path $venvDir "Scripts\python.exe"

    if (-not (Test-Path $venvDir)) {
        Write-Log "Creating virtual environment"
        Invoke-Python -PythonCommand $PythonCommand -Arguments @("-m", "venv", $venvDir)
    }
    else {
        Write-Log "Reusing existing virtual environment"
    }

    if (-not (Test-Path $venvPython)) {
        Fail "virtual environment python was not created correctly"
    }

    Write-Log "Installing Python dependencies"
    & $venvPython -m pip install --upgrade pip
    if ($LASTEXITCODE -ne 0) { Fail "pip upgrade failed" }
    & $venvPython -m pip install -r (Join-Path $ProjectDir "requirements.txt")
    if ($LASTEXITCODE -ne 0) { Fail "dependency install failed" }
}

function Start-App {
    param([string]$ProjectDir)

    if ($StartApp -ne "1") {
        Write-Log "Skipping app start because START_APP=$StartApp"
        return
    }

    $venvPython = Join-Path $ProjectDir ".venv\Scripts\python.exe"
    Write-Log "Starting kelsa.ai at http://127.0.0.1:$AppPort"
    Push-Location $ProjectDir
    try {
        & $venvPython "main.py"
        if ($LASTEXITCODE -ne 0) {
            Fail "application start failed"
        }
    }
    finally {
        Pop-Location
    }
}

Write-Log "Beginning automated install for $RepoUrl"

if (-not (Test-Command "git") -or -not (Get-PythonCommand)) {
    Install-SystemDependencies
}

if (-not (Test-Command "git")) {
    Fail "Git is still unavailable after installation"
}

$pythonCommand = Get-PythonCommand
if (-not $pythonCommand) {
    Fail "Python 3.10+ is still unavailable after installation"
}

$projectDir = Resolve-ProjectDir
Prepare-Repo -ProjectDir $projectDir
Ensure-EnvFile -ProjectDir $projectDir -PythonCommand $pythonCommand
Setup-Venv -ProjectDir $projectDir -PythonCommand $pythonCommand

Write-Log "Installation completed successfully"
Write-Log "Project directory: $projectDir"
Write-Log "You can rerun without launching by setting START_APP=0"

Start-App -ProjectDir $projectDir
