param([string]$CloudflaredPath = 'cloudflared.exe', [switch]$Preview)
$ErrorActionPreference = 'Stop'
$backend = $PSScriptRoot
$privateDir = Join-Path $backend '.private'
New-Item -ItemType Directory -Path $privateDir -Force | Out-Null
$pythonExe = (Get-Command python -ErrorAction Stop).Source
$accessFile = Join-Path $privateDir 'access.txt'
function Test-CharacterAPI([string]$base) {
    if (-not (Test-Path -LiteralPath $accessFile)) { return $false }
    try {
        $accessCode = [IO.File]::ReadAllText($accessFile).Trim()
        $health = Invoke-RestMethod ($base + '/api/health') -Headers @{ Authorization = 'Bearer ' + $accessCode } -TimeoutSec 6
        return [bool]$health.ready
    } catch { return $false }
}
if ($Preview -and (Test-CharacterAPI 'http://127.0.0.1:8787')) {
    $header = @{ Authorization = 'Bearer ' + [IO.File]::ReadAllText($accessFile).Trim() }
    $currentApi = Invoke-RestMethod 'http://127.0.0.1:8787/api/health' -Headers $header -TimeoutSec 6
    if ($currentApi.school_protocol -ne 3) {
        $ownedPidFile = Join-Path $privateDir 'server.pid'
        if (-not (Test-Path -LiteralPath $ownedPidFile)) { throw 'Update the running character API before opening the school preview.' }
        $ownedId = [int]([IO.File]::ReadAllText($ownedPidFile).Trim())
        $owned = Get-CimInstance Win32_Process -Filter ('ProcessId='+$ownedId)
        $listener = Get-NetTCPConnection -LocalPort 8787 -State Listen -ErrorAction SilentlyContinue | Where-Object OwningProcess -eq $ownedId
        if (-not $owned -or $owned.Name -notmatch '^python(?:w)?\.exe$' -or $owned.CommandLine -notmatch '(?:^|[\s"\\])server\.py(?:$|[\s"])' -or -not $listener) {
            throw 'The running game API could not be identified as the Life Quest game process.'
        }
        Stop-Process -Id $ownedId
        Wait-Process -Id $ownedId -ErrorAction SilentlyContinue
    }
}
if (-not (Test-CharacterAPI 'http://127.0.0.1:8787')) {
    $serverProcess = Start-Process -FilePath $pythonExe -ArgumentList 'server.py' -WorkingDirectory $backend -WindowStyle Hidden -RedirectStandardOutput (Join-Path $privateDir 'server-output.log') -RedirectStandardError (Join-Path $privateDir 'server-error.log') -PassThru
    Set-Content -LiteralPath (Join-Path $privateDir 'server.pid') -Value $serverProcess.Id
    for ($attempt=0; $attempt -lt 30; $attempt++) {
        Start-Sleep -Milliseconds 400
        if (Test-CharacterAPI 'http://127.0.0.1:8787') { break }
        if ($serverProcess.HasExited) { throw 'Character API did not start. Check backend/.private/server-error.log.' }
    }
}
if (-not (Test-CharacterAPI 'http://127.0.0.1:8787')) { throw 'Start Ollama with qwen3:1.7b, then run this script again.' }
$relay = ''
$connectionFile = Join-Path $privateDir 'connection.json'
if (Test-Path -LiteralPath $connectionFile) {
    $previous = Get-Content -LiteralPath $connectionFile -Raw | ConvertFrom-Json
    if ($previous.server_url -and (Test-CharacterAPI $previous.server_url)) { $relay = $previous.server_url }
}
if (-not $relay) {
    $cloudflared = (Get-Command $CloudflaredPath -ErrorAction Stop).Source
    $relayLog = Join-Path $privateDir 'relay-error.log'
    $relayProcess = Start-Process -FilePath $cloudflared -ArgumentList 'tunnel','--no-autoupdate','--protocol','http2','--edge-ip-version','4','--url','http://127.0.0.1:8787' -WorkingDirectory $backend -WindowStyle Hidden -RedirectStandardOutput (Join-Path $privateDir 'relay-output.log') -RedirectStandardError $relayLog -PassThru
    Set-Content -LiteralPath (Join-Path $privateDir 'relay.pid') -Value $relayProcess.Id
    $relayDeadline = [DateTime]::UtcNow.AddSeconds(50)
    while ([DateTime]::UtcNow -lt $relayDeadline) {
        Start-Sleep -Seconds 1
        if ($relayProcess.HasExited) { throw 'Phone relay did not start. Check backend/.private/relay-error.log.' }
        if (Test-Path -LiteralPath $relayLog) {
            $found = [regex]::Match((Get-Content -LiteralPath $relayLog -Raw),'https://[a-z0-9-]+\.trycloudflare\.com')
            if ($found.Success -and (Test-CharacterAPI $found.Value)) { $relay = $found.Value; break }
        }
    }
    if (-not $relay) {
        if (-not $relayProcess.HasExited) { Stop-Process -Id $relayProcess.Id }
        throw 'The temporary phone relay did not become reachable. The PC game API is still available locally. Try again to create a working mobile link.'
    }
}
$accessCode = [IO.File]::ReadAllText($accessFile).Trim()
$gamePath = if ($Preview) { 'life-quest-preview' } else { 'life-quest' }
$gameUrl = 'https://yeswanth1570.github.io/kalyana-kathal/' + $gamePath + '/'
$phoneLink = $gameUrl + '#api=' + [Uri]::EscapeDataString($relay) + '&key=' + [Uri]::EscapeDataString($accessCode)
[IO.File]::WriteAllText($connectionFile,(@{server_url=$relay;client_url=$gameUrl} | ConvertTo-Json))
$escaped = [System.Net.WebUtility]::HtmlEncode($phoneLink)
$html = '<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Your private Qwen game link</title><body style="font:18px system-ui;background:#203936;color:#f6e9cf;padding:32px;max-width:800px;margin:auto"><h1>Your private phone link</h1><p>Open this link on your phone. Keep the PC, Ollama and this relay running. Anyone with the link can use this game chat connection, so keep it private.</p><p><a style="color:#e3ba73" href="'+$escaped+'">Play Kalyana Kathal with Qwen on this PC</a></p><textarea style="width:100%;height:130px;font:16px system-ui">'+$escaped+'</textarea><p>Copy the link above to your phone. Restarting a temporary relay changes the address; run Start-Phone-Chat.ps1 again for a new link.</p></body>'
[IO.File]::WriteAllText((Join-Path $privateDir 'phone-link.html'),$html)
Write-Output ('Qwen on PC is ready. Private phone link saved in: ' + (Join-Path $privateDir 'phone-link.html'))
Write-Output ('HTTPS game API: ' + $relay)
Write-Output 'No router or firewall settings changed. Ollama remains loopback-only.'
