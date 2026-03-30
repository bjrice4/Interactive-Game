# Interactive Game
A System Verilog-based FPGA game displayed on a monitor using VGA output. 
## To Run:
Open files in Quartus Prime. This project used a DE0-CV (name filter: 5CEBA4F23C7) board.
## The Game:
First, the hungry character walks onto the screen and automatically stops when it reaches the center. The goal of this game is to have the character eat all the blue squares (the "food") that appear and move around the screen (eating is described as the blue squares making it into the open mouth). Eventually, the character gets too full and the game ends.

The mouth can be opened by pressing KEY0. The food can be moved around by SW0 (x-axis) and SW9 (y-axis). Everytime the food is successfully eaten by the characters the value increments and is shown on the HEX display.
