param(
    [string]$Project = "web-ai-lab"
)

$sep = "=" * 52

Write-Host $sep
Write-Host "CONTINUITY LOADER - Session continuity & sync status"
Write-Host $sep
Write-Host ""

# 1. Load continuity metadata
$continuity = "C:\web-ai-lab\.continuity-meta.json"
if (Test-Path $continuity) {
    $meta = Get-Content $continuity -Encoding UTF8 | ConvertFrom-Json
    Write-Host "  Last session: $($meta.last_session)"
    Write-Host "  State: $($meta.state)"
    if ($meta.pending_tasks) {
        Write-Host "  Pending:"
        $meta.pending_tasks | ForEach-Object { Write-Host "    -> $_" }
    }
}
Write-Host ""

# 2. Check cloud/autosync status
$engramBin = "C:\web-ai-lab\tools\engram\bin\engram.exe"
$cloudStatus = & $engramBin cloud status 2>&1 |
    Select-String -NotMatch "Update available|To update|CategoryInfo|NativeCommandError|RemoteException" |
    Select-String "status|Server|Auth|Sync|daemon"

if ($cloudStatus) {
    Write-Host "  Cloud sync status:"
    $cloudStatus | ForEach-Object { Write-Host "    $_" }
}
Write-Host ""

Write-Host $sep
Write-Host "Notes:"
Write-Host "  - Past errors are NOT loaded here (saves context)."
Write-Host "  - When debugging, search: engram search mcp-error: --project <name>"
Write-Host "  - When changing architecture, search: engram search decision --project <name>"
Write-Host $sep
