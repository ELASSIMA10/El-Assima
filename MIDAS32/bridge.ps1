$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:9999/") # Changement de port pour éviter les conflits
try {
    $listener.Start()
    Write-Host "`n===============================================" -ForegroundColor Green
    Write-Host "   SERVEUR MIXAGE MIDAS M32 OPÉRATIONNEL" -ForegroundColor Green
    Write-Host "===============================================" -ForegroundColor Green
    Write-Host "1. OUVRIR SUR PC : Ouvrez le fichier index.html du bureau"
    Write-Host "2. OUVRIR SUR IPHONE : http://votre_ip:9999" -ForegroundColor Yellow
    Write-Host "-----------------------------------------------"
    
    $udp = New-Object System.Net.Sockets.UdpClient
    $htmlPath = Join-Path $PSScriptRoot "index.html"

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request; $response = $context.Response
        $response.AddHeader("Access-Control-Allow-Origin", "*")
        $response.AddHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        
        $path = $request.Url.LocalPath
        
        if ($path -eq "/" -or $path -eq "/index.html") {
            if (Test-Path $htmlPath) {
                $content = [System.IO.File]::ReadAllBytes($htmlPath)
                $response.ContentType = "text/html"; $response.OutputStream.Write($content, 0, $content.Length)
            }
        } 
        elseif ($path.Contains("/ch/")) {
            $parts = $path.Split("/")
            # Log pour confirmer la réception
            Write-Host "RECU >> $path" -ForegroundColor Gray
            
            if ($parts.Count -ge 5) {
                $ch = $parts[2]; $type = $parts[3]; $val = [float]$parts[4] / 100.0
                $query = [System.Web.HttpUtility]::ParseQueryString($request.Url.Query)
                $targetIP = if ($query["target"]) { $query["target"] } else { "192.168.1.200" }

                # Envoi UDP
                $oscAddr = switch($type) { "fader"{"/ch/$ch/mix/fader"} "gain"{"/ch/$ch/config/gain"} default{"/ch/$ch/mix/fader"} }
                $pAddr = $oscAddr + "`0"; while ($pAddr.Length % 4 -ne 0) { $pAddr += "`0" }
                $pType = ",f`0`0"; $pVal = [System.BitConverter]::GetBytes([float]$val)
                if ([System.BitConverter]::IsLittleEndian) { [System.Array]::Reverse($pVal) }
                $packet = [System.Text.Encoding]::ASCII.GetBytes($pAddr) + [System.Text.Encoding]::ASCII.GetBytes($pType) + $pVal
                $udp.Send($packet, $packet.Length, $targetIP, 10023)
                Write-Host "TABLE >> $targetIP : $oscAddr -> $val" -ForegroundColor Yellow
            }
            $buffer = [System.Text.Encoding]::UTF8.GetBytes("OK")
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        $response.Close()
    }
} catch {
    Write-Host "ERREUR: Impossible de lancer le serveur. Fermez les autres fenêtres noires." -ForegroundColor Red
    Write-Host $_.Exception.Message
} finally { $listener.Stop(); $udp.Close() }
