# VideoTex Demo Server
#
# by tim lindner
# November 2022

import socket
import random

HOST = "127.0.0.1"	# Standard loopback interface address (localhost)
PORT = 65432  # Port to listen on (non-privileged ports are > 1023)

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
	s.bind((HOST, PORT))
	s.listen()
	conn, addr = s.accept()
	mode = 0
	next_mode = 0
	input = b''
	interrogate = b''
	
	with conn:
		print(f"Connected by {addr}")
		while True:
			# Wait for initial keyboard input
			if mode==0:
				data = conn.recv(1024)
				if not data:
					break

				if data == b'\r':
					# send interrogate sequence
					conn.sendall(b"\x1b\x49")
					# receive data with no echo
					next_mode = 7
					mode = 6;
			
			# Display main menu
			if mode==1:
				if interrogate != "":
					conn.sendall(b"\r\nTerminal code: ")
					conn.sendall(interrogate)
					
				conn.sendall(b"\r\nHere is the main menu:")			
				conn.sendall(b"\r\n1. Print Lorem Ipsum")
				conn.sendall(b"\r\n2. Display semi graphics")
				conn.sendall(b"\r\n3. Display med res graphics")
				conn.sendall(b"\r\n4. Load and run executable")
				conn.sendall(b"\r\n5. Log out")
				conn.sendall(b"\r\nChoose: ")
				input = b""
				next_mode = 3
				#Change sursor to red
				#conn.sendall(b"\x1b\x60\xaf")
				mode = 2

			# accept input end with \r then goto next_mode
			if mode==2:
				data = conn.recv(1024)
				if not data:
					break
		
				if data == b'\r':
					mode = next_mode
					conn.sendall(b"\r\n")
					# change cursor back to blue
					#conn.sendall(b"\x1b\x60\xbf")
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
					mode = 8
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
			
			# accept input end with \r (no echo) then goto next_mode
			if mode == 6:
				data = conn.recv(1024)
				if not data:
					break
		
				if data == b'\r':
					mode = next_mode
				elif data == b'\b':
					input = input[:-1]
				else:
					input = input + data;
			
			# save interrogate
			if mode == 7:
				interrogate = input
				mode = 1
			
			# ask how many colored squared to print
			if mode == 8:
				conn.sendall(b"\r\nDraw how many squares? ")
				input = b""
				next_mode = 9
				mode = 2

			# draw semi graphics squares in random positions
			if mode == 9:
				# clear screen
				conn.sendall(b"\x1b\x6a")
				# put in semi graphics mode
				conn.sendall(b"\x1b\x47\x34")
				
				for i in range(int(input)):
					conn.sendall(b"\x1b\x59")
					x = 0x20 + random.randrange(30)
					y = 0x20 + random.randrange(13)
					c = 128 + random.randrange(127)
					conn.sendall(bytes(chr(y),'latin_1'))
					conn.sendall(bytes(chr(x),'latin_1'))
					conn.sendall(bytes(chr(c),'latin_1'))
					
				# put in alpha only mode
				conn.sendall(b"\x1b\x47\x4e")
				
				# position cursor at bottom of screen
				conn.sendall(b"\x1b\x59")
				x = 0x20
				y = 0x20 + 15
				conn.sendall(bytes(chr(y),'latin_1'))
				conn.sendall(bytes(chr(x),'latin_1'))
				conn.sendall(b"Press <enter> to continue")
				
				mode = 2
				input = b""
				next_mode = 1
					
					
					
  					