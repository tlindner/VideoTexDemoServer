VideoTex Demo Server
====================

This is a python script that attempts to show off some features of VideoTex terminal emulator.

VideoTex is the software used in Radio Shack's AgVision and VideoTex computers. It is also available as a cartridge for the TRS-80 Color Computer.

Start the server with the command:

`python3 vtds.py`

It will display the port number it has opened a listening socket on.

The medium resolution graphic feature will display a list of jpeg files in the current directory. After one is chosen the python server will resize the jpeg to 128 x 96 and dither it to by level color per pixel.

The upload binary function currently only will upload the file named "keyscn2.bin" to address $E00. Then change the currently viewed page to 2 ($400). Then execute the code at $E00. This willl cause the VideoTex software to hang up.

The only feature in the reference manual I could not get to work is changing the text caret graphic.


Other Files
===========

- lorem.txt: sample text used by the server
- pick.jpg: Sample image used by the server
- woman.jpg: Sample image used by the server
- pick.jpg: Sample image used by the server
- keyscn2.asm: Source to keyboard scan program the server can send to the machine
- keyscn2.bin: Assembled binary of keyscn2.asm
- build.sh: Build script for keyscn2.asm

Known problems
==============

1. Trying to retrieve text a second time in the same session will fail. But the third time will work.
2. Changing the cursor graphic doesn't see to work.
3. The server does not implement block retry.

Documentation
=============
https://colorcomputerarchive.com/search?q=videotex

--
tim lindner
tlindner@macmess.org
November 2022
