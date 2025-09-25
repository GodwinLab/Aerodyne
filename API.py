import socket

def send_command(command):
    server_address = '127.0.0.1'
    server_port = 10001
    # server_port = 61001
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    try:
        sock.connect((server_address, server_port))

        message = f"wintel::{command}"
        print(f"Sending: {message}")
        sock.sendall(message.encode('utf-8'))

        # response = sock.recv(1024)
        # print(f"Received: {response.decode('utf-8')}")

    finally:
        print("Closing connection")
        sock.close()


class TcpClient:
    def __init__(self, host='localhost', port=10001):
        self.host = host
        self.port = port
        self.sock = None

    def connect(self):
        """Establish a connection to the TCP/IP server."""
        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.sock.connect((self.host, self.port))
            print(f"Connected to {self.host}:{self.port}")
        except Exception as e:
            print(f"Failed to connect: {e}")

    def send_message(self, command):
        """Send a message to the server."""
        message = f"wintel::{command}"
        # message = command
        if self.sock:
            try:
                self.sock.sendall(message.encode('utf-8'))
                print(f"Sent: {message}")
            except Exception as e:
                print(f"Failed to send message: {e}")

    def receive_message(self):
        """Receive a message from the server."""
        if self.sock:
            try:
                response = self.sock.recv(1024)  # Buffer size
                print(f"Received: {response.decode('utf-8')}")
                return response.decode('utf-8')
            except Exception as e:
                print(f"Failed to receive message: {e}")

    def close(self):
        """Close the connection."""
        if self.sock:
            try:
                self.sock.close()
                print("Connection closed")
            except Exception as e:
                print(f"Failed to close connection: {e}")

if __name__ == "__main__":
    # send_command("dno17")

    # client = TcpClient(host='127.0.0.1', port=61001)
    client = TcpClient(host='127.0.0.1', port=10001)
    client.connect()
    client.send_message("dno17")
    # response = client.receive_message()
    client.close()
