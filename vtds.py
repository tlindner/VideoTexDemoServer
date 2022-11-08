# VideoTex Demo Server
#
# by tim lindner
# November 2022

import socket

HOST = "127.0.0.1"	# Standard loopback interface address (localhost)
PORT = 65432  # Port to listen on (non-privileged ports are > 1023)

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
	s.bind((HOST, PORT))
	s.listen()
	conn, addr = s.accept()
	mode = 0
	next_mode = 0
	input = b''
	
	with conn:
		print(f"Connected by {addr}")
		while True:
			# Wait for initial keyboard input
			if mode==0:
				data = conn.recv(1024)
				if not data:
					break

				if data == b'\r':
					mode = 1;
			
			# Display main menu
			if mode==1:
				conn.sendall(b"\r\nHere is the main menu:")
				conn.sendall(b"\r\n1. Print Lorem Ipsum")
				conn.sendall(b"\r\n2. Display lo res graphics")
				conn.sendall(b"\r\n3. Display med res graphics")
				conn.sendall(b"\r\n4. Load and run executable")
				conn.sendall(b"\r\n5. Log out")
				conn.sendall(b"\r\nChoose: ")
				input = b""
				next_mode = 3
				mode = 2

			# accept input end with \r then goto next_mode
			if mode==2:
				data = conn.recv(1024)
				if not data:
					break
		
				if data == b'\r':
					mode = next_mode
					conn.sendall(b"\r\n")
				elif data == b'\b':
					input = input[:-1]
					if len(input)>0:
						conn.sendall(b"\b")
				else:
					input = input + data;
					conn.sendall(data)
					
			# handle main menu selection
			if mode==3:
				if input == b"1":
					mode = 4
				elif input == b"2":
					mode = 1
				elif input == b"3":
					mode = 1
				elif input == b"4":
					mode = 1
				elif input == b"5":
					break;
				else:
					mode = 1
			
			# ask how manu word to print of lorem ipsum
			if mode == 4:
				conn.sendall(b"\r\nHow many words? ")
				input = b""
				next_mode = 5
				mode = 2
			
			if mode == 5:
				from pathlib import Path
				fd = Path('lorem.txt').read_text()
				
				count = int(input)
				
				for element in fd:
					if element == " ":
						count = count - 1
					
					if count == 0:
						break;
						
					conn.sendall(bytes(element,'utf-8'))
			
				conn.sendall(b"\r\nPress <enter> to continue")
				next_mode = 1
				mode = 2
