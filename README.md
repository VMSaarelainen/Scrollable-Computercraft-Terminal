# What is Scrollable?
Scrollable is a small script that makes it possible to scroll with the Page Up/Page Down and End keys in the ComputerCraft terminals and pocket computers. Debug print to your hearts content!
# Installation
The script is small enough to drag & drop into any computer. Literally just open a computer and drop the .lua file into your game client. To download from GitHub, click the green "<> Code" dropdown and download as ZIP, or get the script directly from this pastebin link: https://pastebin.com/6BaLNYjk
For ease of use I recommend naming the file "Scrollable.lua" and placing it at the root of the file system.
# Usage
If you followed my recommendation above simply use: Scrollable <program you want to run> <args>
For example: Scrollable miningprogram 5
should execute "miningprogram" with the argument "5", and allow you to scroll the terminal output.

This also works with monitors, but you do need to open the actual terminal to scroll the output.
Example: monitor <side> Scrollable <program you want to run> <args>

If you named the file differently or placed it elsewhere, just replace Scrollable with the path to this script. Do note that you may need to change the path to your own program in this case.
# Controls
	Page Up/Page Down: Scroll line by line
	End: Skip to bottom
	Hold Del: Terminate BOTH Scrollable and your own program.
# I don't have Page Up/Down keys or my own program uses them
You can change the controls in function _ScrollableTerminalFunc()_ at line 140.
# How does it work?
In ComputerCraft, the built-in system functions (including the print function) can be accessed and modified through the secret environment variable "\_G". Any modifications to these functions will make subsequent system calls execute with your modifications until the computer is reset. This script replaces the default print function with another function that keeps a larger buffer of terminal output, then runs a simple program to respond to key presses, draw a simple menu bar and execute the program whose output you wish to scroll in.
# What about namespace pollution?
Besides overriding the standard print function while running, there isn't any! This script is contained entirely within the local variable scrollableTerminal at runtime. The print function should also be replaced with the standard system function when this script is terminated.
# Bugs or improvements?
It's been a long time since I wrote this, but since this is a fairly simple script feel free to modify, fix or fork this to suit your needs!

# Demo

https://github.com/VMSaarelainen/Scrollable-Computercraft-Terminal/assets/55636497/2bcab3dd-62e4-44f0-8b15-c0793a76a25d

