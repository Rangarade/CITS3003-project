import socket
import os
import time

HOST = "0.0.0.0"
PORT = 9001

BACKUP_DIR = os.path.join(os.path.dirname(__file__), "backups")

USERS = {
    "backup_admin": True
}

TOKEN_OFFSET = 17
TOKEN_TIMEOUT = 30

SESSIONS = {}

SESSION_TIMEOUT = 120
DIAGNOSTIC_SESSION_TIMEOUT = 3600

SECURITY_LOG = os.path.join(BACKUP_DIR, "logs", "security.log")
SESSION_DEBUG_LOG = os.path.join(BACKUP_DIR, "logs", "session_debug.log")


def generate_token(username):
    timestamp = int(time.time())
    token = f"{username}-{timestamp + TOKEN_OFFSET}"
    return token, timestamp


def create_session(username, timeout=None):
    session_id = f"NETOPS-{int(time.time())}-{len(SESSIONS) + 1}"

    SESSIONS[session_id] = {
        "username": username,
        "role": "administrator",
        "created": time.time(),
        "active": True,
        "timeout": timeout or SESSION_TIMEOUT
    }

    return session_id


def session_valid(session_id):
    if session_id not in SESSIONS:
        return False

    session = SESSIONS[session_id]

    if not session["active"]:
        return False

    if time.time() - session["created"] > session["timeout"]:
        session["active"] = False
        return False

    return True


server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

server.bind((HOST, PORT))
server.listen(5)

print()
print("==========================================")
print("        NEON//WIRE DATA NODE v4.2")
print("        CORPORATE NETWORK TERMINAL")
print("==========================================")
print(f"NODE STATUS : ONLINE")
print(f"LISTEN PORT : {PORT}")
print(f"ARCHIVE     : {BACKUP_DIR}")
print("SECURITY    : ACTIVE")
print("==========================================")
print()


admin_session = create_session(
    "backup_admin",
    DIAGNOSTIC_SESSION_TIMEOUT
)

print(f"[IDENTITY] Administrative session established")
print(f"[DIAGNOSTIC] Session credential: {admin_session}")


with open(SESSION_DEBUG_LOG, "w") as file:
    file.write(
        "NEON//WIRE SESSION DIAGNOSTICS\n"
        "==============================\n\n"
        "IDENTITY SERVICE: NWS-SESSION/2.1\n"
        "NODE: NW-042\n\n"
        "Diagnostic event: administrative session established\n"
        "Identity: backup_admin\n"
        "Clearance: administrator\n"
        "Session status: ACTIVE\n\n"
        "Session credential:\n"
        f"{admin_session}\n\n"
        "Diagnostic notice:\n"
        "Session credentials are classified information.\n"
        "Diagnostic output should never be transmitted outside\n"
        "the Identity Persistence subsystem.\n"
    )


with open(SECURITY_LOG, "w") as file:
    file.write(
        "NEON//WIRE SECURITY LOG\n"
        "=======================\n\n"
        "AUTHENTICATION SERVICE: NWS-AUTH/3.7\n"
        "NODE: NW-042\n"
        "STATUS: OPERATIONAL\n\n"
    )


while True:
    client, address = server.accept()

    print(f"[LINK] Incoming connection from {address}")

    authenticated = False
    current_token = None
    token_created = None
    session_id = None

    client.sendall(
        b"\n"
        b"+------------------------------------------+\n"
        b"|          NEON//WIRE DATA NODE           |\n"
        b"|          CORPORATE TERMINAL             |\n"
        b"+------------------------------------------+\n"
        b"\n"
        b"NODE       : NW-042\n"
        b"LINK       : SECURE\n"
        b"STATUS     : ONLINE\n"
        b"IDENTITY   : UNAUTHENTICATED\n"
        b"SECURITY   : ACTIVE\n"
        b"\n"
        b"Enter HELP for available interfaces.\n"
        b"> "
    )

    while True:
        try:
            raw_data = client.recv(1024)

        except (ConnectionResetError, ConnectionAbortedError, OSError) as e:
            print(f"[LINK] Connection error from {address}: {e}")
            break

        if not raw_data:
            break

        data = raw_data.decode().strip()

        if data.upper() == "HELP":
            client.sendall(
                b"\n"
                b"NEON//WIRE OPERATIONAL INTERFACES\n"
                b"---------------------------------\n"
                b"HELP                 - Display interfaces\n"
                b"AUTH <identity>      - Request access challenge\n"
                b"TOKEN <challenge>    - Submit access challenge\n"
                b"TIME                 - Display node clock\n"
                b"LIST [directory]     - Browse archive\n"
                b"GET <filename>       - Retrieve archive record\n"
            )

        elif data.upper().startswith("AUTH "):
            parts = data.split(" ", 1)

            if len(parts) != 2:
                client.sendall(
                    b"\nUsage: AUTH <identity>\n"
                )

            else:
                username = parts[1].strip()

                if username not in USERS:
                    client.sendall(
                        b"\nIDENTITY NOT RECOGNISED.\n"
                    )

                else:
                    current_token, token_created = generate_token(username)

                    print(
                        f"[AUTH] Challenge issued for {username}: "
                        f"{current_token}"
                    )

                    with open(SECURITY_LOG, "a") as file:
                        file.write(
                            f"[{time.strftime('%Y-%m-%d %H:%M:%S')}]\n"
                            f"Identity: {username}\n"
                            f"Request: AUTHENTICATION\n"
                            f"Node clock: {token_created}\n"
                            f"Challenge: "
                            f"{token_created + TOKEN_OFFSET}\n"
                            f"Result: CHALLENGE ISSUED\n\n"
                        )

                    client.sendall(
                        b"\nACCESS CHALLENGE ISSUED.\n"
                        b"Submit TOKEN <challenge> to continue.\n"
                    )

        elif data.upper().startswith("TOKEN "):
            token = data[6:].strip()

            if current_token is None:
                client.sendall(
                    b"\nNO ACTIVE ACCESS CHALLENGE.\n"
                )

            elif time.time() - token_created > TOKEN_TIMEOUT:
                authenticated = False
                current_token = None
                token_created = None
                session_id = None

                client.sendall(
                    b"\nACCESS CHALLENGE EXPIRED.\n"
                    b"Request a new challenge with AUTH <identity>.\n"
                )

            elif token == current_token:
                authenticated = True
                session_id = create_session("backup_admin")

                print(
                    f"[AUTH] Session established: {session_id}"
                )

                with open(SECURITY_LOG, "a") as file:
                    file.write(
                        f"[{time.strftime('%Y-%m-%d %H:%M:%S')}]\n"
                        f"Identity: backup_admin\n"
                        f"Request: SESSION ESTABLISHED\n"
                        f"Result: ACCEPTED\n\n"
                    )

                client.sendall(
                    b"\nACCESS GRANTED.\n"
                    b"Administrative identity established.\n"
                )

            else:
                client.sendall(
                    b"\nINVALID ACCESS CHALLENGE.\n"
                )

        elif data.upper() == "TIME":
            client.sendall(
                f"\nNEON//WIRE NODE CLOCK: {int(time.time())}\n"
                .encode()
            )

        elif data.upper().startswith("ATTACH "):
            supplied = data[7:].strip()

            if supplied in SESSIONS:
                session = SESSIONS[supplied]

                if session_valid(supplied):
                    session_id = supplied
                    authenticated = True

                    print(
                        f"[SESSION] Credential attached: {supplied}"
                    )

                    client.sendall(
                        b"\nSESSION CREDENTIAL ACCEPTED.\n"
                        b"Identity context restored.\n"
                    )

                else:
                    client.sendall(
                        b"\nSESSION CREDENTIAL EXPIRED.\n"
                    )

            else:
                client.sendall(
                    b"\nSESSION CREDENTIAL NOT RECOGNISED.\n"
                )

        elif data.upper() == "ADMIN":
            if not authenticated or not session_valid(session_id):
                authenticated = False

                client.sendall(
                    b"\nADMINISTRATIVE ACCESS REQUIRED.\n"
                )

            else:
                session = SESSIONS[session_id]

                if session["role"] != "administrator":
                    client.sendall(
                        b"\nINSUFFICIENT CLEARANCE.\n"
                    )

                else:
                    client.sendall(
                        b"\n"
                        b"NEON//WIRE RESTRICTED RECORD\n"
                        b"-----------------------------\n"
                        b"Clearance: ADMINISTRATOR\n"
                        b"Session validation: PASSED\n"
                        b"\n"
                        b"CTF-ADMIN-CODE: "
                        b"FLAG{leaked_session_credential}\n"
                    )

        elif data.upper() == "REPORT":
            if not authenticated or not session_valid(session_id):
                authenticated = False

                client.sendall(
                    b"\nADMINISTRATIVE ACCESS REQUIRED.\n"
                )

            else:
                client.sendall(
                    b"\n"
                    b"NEON//WIRE SECURITY REPORT\n"
                    b"--------------------------\n"
                    b"Report access: GRANTED\n"
                    b"Identity validation: PASSED\n"
                    b"\n"
                    b"CTF-ADMIN-CODE: "
                    b"FLAG{predictable_auth_token}\n"
                )

        elif data.upper().startswith("LIST"):
            path = data[4:].strip()

            if path == "":
                directory = BACKUP_DIR
            else:
                directory = os.path.join(BACKUP_DIR, path)

            if os.path.isdir(directory):
                entries = os.listdir(directory)

                response = (
                    f"\nARCHIVE DIRECTORY: "
                    f"{path or 'backups/'}\n"
                    f"---------------------------------\n"
                )

                for entry in entries:
                    full_path = os.path.join(directory, entry)

                    if os.path.isdir(full_path):
                        response += f"[DIR]  {entry}/\n"
                    else:
                        response += f"[FILE] {entry}\n"

                client.sendall(response.encode())

            else:
                client.sendall(
                    b"\nARCHIVE DIRECTORY NOT FOUND.\n"
                )

        elif data.upper().startswith("GET "):
            filename = data[4:].strip()

            restricted_files = {
                "config/admin.txt",
                "logs/session_debug.log"
            }

            if filename in restricted_files and not authenticated:
                client.sendall(
                    b"\nCLEARANCE REQUIRED FOR THIS RECORD.\n"
                )

            else:
                filepath = os.path.join(BACKUP_DIR, filename)

                if os.path.isfile(filepath):
                    with open(filepath, "rb") as file:
                        client.sendall(
                            b"\n" + file.read()
                        )

                else:
                    client.sendall(
                        b"\nARCHIVE RECORD NOT FOUND.\n"
                    )

        else:
            client.sendall(
                b"\nUNKNOWN INTERFACE.\n"
                b"Enter HELP for available interfaces.\n"
            )

        client.sendall(b"\n> ")

    client.close()
    print(f"[LINK] Connection closed: {address}")