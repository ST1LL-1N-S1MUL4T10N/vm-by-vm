Clear-Host

Echo "Keep alive with scroll Lock..."

$WShell = New-Object -com "Wscript.Shell"

while($true) {
}

$WShell.sendkeys("{SCROLLLOCK}") 
Start-Sleep -Milliseconds 100 
$WShell.sendkeys("{SCROLLLOCK}") 
Echo "STAY ALIVE" 
Start-Sleep -Seconds 300
