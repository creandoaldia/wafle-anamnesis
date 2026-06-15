param(
    [Parameter(Mandatory)]
    [string]$ProcessName,
    [Parameter(Mandatory)]
    [string]$Command
)

# ── 1. Ensure Python Scripts in PATH ──────────────────────────────────
$pythonDirs = @(
    "$env:LOCALAPPDATA\Programs\Python\Python314\Scripts",
    "$env:LOCALAPPDATA\Programs\Python\Python313\Scripts",
    "$env:LOCALAPPDATA\Programs\Python\Python312\Scripts"
)
foreach ($dir in $pythonDirs) {
    if ((Test-Path $dir) -and ($dir -notin $env:PATH)) {
        $env:PATH = "$dir;$env:PATH"
    }
}

# ── 2. Kill orphans by parent-process check ──────────────────────────
# An orphan is any process whose parent is dead or not an mcp-launcher
$candidates = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
$orphans = @()
foreach ($proc in $candidates) {
    $parentPid = (Get-CimInstance Win32_Process -Filter "ProcessId=$($proc.Id)" -ErrorAction SilentlyContinue).ParentProcessId
    $parent = Get-Process -Id $parentPid -ErrorAction SilentlyContinue
    $isOrphan = $false
    if (-not $parent) {
        $isOrphan = $true  # parent dead → orphan
    } elseif ($parent.ProcessName -ne 'powershell') {
        $isOrphan = $true  # not launched by launcher → orphan
    } else {
        $parentCmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$parentPid" -ErrorAction SilentlyContinue).CommandLine
        if ($parentCmd -notlike '*mcp-launcher*') {
            $isOrphan = $true  # its PowerShell is NOT an mcp-launcher → orphan
        }
    }
    if ($isOrphan) {
        $orphans += $proc
    }
}
if ($orphans) {
    $orphanIds = ($orphans | ForEach-Object { $_.Id }) -join ','
    Write-Host "[mcp-launcher] Killing orphan $ProcessName PIDs: $orphanIds"
    $orphans | ForEach-Object { taskkill /f /pid $_.Id 2>$null | Out-Null }
}

# ── 3. Run the MCP server (inherits stdin/stdout for JSON-RPC) ────────
$mcpExitCode = 0
$mcpError = $null
try {
    Invoke-Expression $Command
    $mcpExitCode = $LASTEXITCODE
} catch {
    $mcpExitCode = 1
    $mcpError = $_.Exception.Message
    Write-Error "[mcp-launcher] Failed to start $ProcessName: $mcpError"
}

# ── 4. Auto-save MCP errors to Engram memory ─────────────────────────
if ($mcpExitCode -ne 0) {
    $engramBin = "C:\web-ai-lab\tools\engram\bin\engram.exe"
    $title = "mcp-error: $ProcessName exited with $mcpExitCode"
    $details = "**What**: MCP server $ProcessName exited with code $mcpExitCode"
    $details += " | **Why**: $Command"
    if ($mcpError) { $details += " | **Error**: $mcpError" }
    $details += " | **When**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $null = & $engramBin save $title $details --type bugfix --project web-ai-lab --scope project 2>&1
}

exit $mcpExitCode
