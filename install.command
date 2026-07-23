#!/bin/bash
# Double-click this file to install the Cryptonote font for your user.
cd "$(dirname "$0")"
mkdir -p ~/Library/Fonts
cp -f Cryptonote.ttf ~/Library/Fonts/
echo "Installed Cryptonote.ttf -> ~/Library/Fonts/"
echo "Open any app (TextEdit, Pages, Notes-in-a-textbox, VS Code) and set the"
echo "display font to 'Cryptonote'. Switch the font back to reveal (decrypt)."
