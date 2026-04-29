; Forward mouse side-buttons (XButton1/back, XButton2/forward) as F13/F14
; only when a terminal window is focused. Browsers and other apps keep
; their normal back/forward behaviour.
;
; Setup:
;   1. Install AutoHotkey v2 (https://www.autohotkey.com/v2/).
;   2. Drop a shortcut to this file into shell:startup so it runs at logon.
;
; Pair with the matching <F13>/<F14> keymaps in nvim's keymaps.lua.

#Requires AutoHotkey v2.0
#SingleInstance Force

#HotIf WinActive("ahk_exe wezterm-gui.exe") || WinActive("ahk_exe WindowsTerminal.exe")
XButton1::Send("^o")
XButton2::Send("^i")
#HotIf

