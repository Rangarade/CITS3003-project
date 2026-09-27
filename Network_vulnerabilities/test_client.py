import socket

client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client.connect(("127.0.0.1", 9001))


def receive_until_prompt():
    data = b""

    while b"> " not in data:
        chunk = client.recv(4096)

        if not chunk:
            break

        data += chunk

    return data.decode()


print(receive_until_prompt())

while True:
    command = input("> ")

    if command.lower() == "exit":
        break

    client.sendall((command + "\n").encode())

    response = receive_until_prompt()
    print(response)

client.close()