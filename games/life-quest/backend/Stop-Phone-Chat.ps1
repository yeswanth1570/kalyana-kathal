# Stops only the game API and relay PIDs recorded by Start-Phone-Chat.ps1.
$ErrorActionPreference='Stop'
$privateDir=Join-Path $PSScriptRoot '.private'
foreach ($item in @(@{file='relay.pid';match='cloudflared'},@{file='server.pid';match='server.py'})) {
    $pidFile=Join-Path $privateDir $item.file
    if (-not(Test-Path -LiteralPath $pidFile)) { continue }
    $ownedId=[int]([IO.File]::ReadAllText($pidFile).Trim())
    $ownedProcess=Get-CimInstance Win32_Process -Filter ('ProcessId='+$ownedId) -ErrorAction SilentlyContinue
    if ($ownedProcess -and $ownedProcess.CommandLine -match [regex]::Escape($item.match)) {
        Stop-Process -Id $ownedId
        Write-Output ('Stopped game process '+$ownedId)
    }
}
Write-Output 'The game connection is stopped. Ollama and other applications were left running.'
