import socket
import os
import re
import subprocess
import time

PORT = 8000
API_CONFIG_PATH = "lib/config/api_config.dart"

def get_active_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Doesn't actually send traffic, just uses the OS routing table to find the local IP
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

def kill_port(port):
    try:
        # Ask Windows for processes blocking our target port
        output = subprocess.check_output(f'netstat -ano | findstr :{port}', shell=True).decode()
        for line in output.split('\n'):
            if f':{port}' in line and 'LISTENING' in line:
                pid = line.strip().split()[-1]
                if pid and pid != '0':
                    print(f"[*] Found crashed backend keeping Port {port} hijacked (PID: {pid}). Eradicating...")
                    os.system(f'taskkill /F /PID {pid} >nul 2>&1')
                    time.sleep(1) # Give OS a second to free the port
    except subprocess.CalledProcessError:
        pass # Port is entirely free!

def update_dart_config(ip):
    if not os.path.exists(API_CONFIG_PATH):
        print(f"[!] Could not find Flutter config at: {API_CONFIG_PATH}")
        return

    with open(API_CONFIG_PATH, 'r', encoding='utf-8') as f:
        content = f.read()

    # Dynamically inject the newly discovered IP into the constants!
    new_http = f"'http://{ip}:{PORT}'"
    new_ws = f"'ws://{ip}:{PORT}'"

    content = re.sub(r"'http://[\d\.]+:\d+'", new_http, content)
    content = re.sub(r"'ws://[\d\.]+:\d+'", new_ws, content)

    with open(API_CONFIG_PATH, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"[*] Auto-Fixed Flutter Networking -> IP matched to {ip}!")

if __name__ == "__main__":
    print("="*50)
    print(" [~] Sajelo Guru - Automatic Dev Launcher [~]")
    print("="*50)
    
    # 1. Terminate any ghost Uvicorn instances instantly
    kill_port(PORT)
    
    # 2. Get active IP and auto-inject it into Dart!
    ip = get_active_ip()
    update_dart_config(ip)
    
    print(f"[*] Booting Python Backend purely on {ip}:{PORT}...\n")
    # 3. Hop down into backend directory and execute
    os.chdir("backend")
    try:
        subprocess.run(["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", str(PORT), "--reload"])
    except KeyboardInterrupt:
        print("\n[*] Server shutdown complete.")
