#RequireAdmin
#include <Array.au3>
#include "Includes\NomadMemory.au3"
#include "Includes\AOB.au3"
#include <Misc.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <ListViewConstants.au3>
#include <WindowsConstants.au3>
#include <ComboConstants.au3>
#include <File.au3>
#include "GUIrelated.au3"
#include "searchrelated.au3"
#include "aimrelated.au3"
#include "fileinfo.au3"
#include "relaxrelated.au3"
#include "tools.au3"
global $poshotkeys = "{Home}|{END}|{insert}|{delete}|{F1}|{F2}|{F3}|{F4}|{F5}|{F6}|{F7}|{F8}|{F9}|{F10}|{F11}|{F12}"
global $config = "config.ini"
global $osumap
global $User32 = dllopen("User32.dll")
if iniread($config,"GENERAL","FIRSTRUN",0) = 0 Then
   $windowname = inputbox("","enter your desired window name: " & @CRLF & @CRLF & "(can change again in the options)","")
   if @ERROR then _exit()
   $screenres = inputbox("","enter your screen resolution (for osu!): " & @CRLF & 'example: "1280x720" (no spaces and the "x" is necessary)' & @CRLF & @CRLF & "(can change again in the options)",@DesktopWidth & "x" & @DesktopHeight)
   if @ERROR then _exit()
   $sensibility = inputbox("","enter the ingame sensitivity: " & @CRLF & 'example: "1.32" (no spaces, use dot to separate the integer from decimal)' & @CRLF & @CRLF & "(can change again in the options)","1.00")
   if @error then _exit()
   iniwrite($config,"GENERAL","windowname",$windowname)
   iniwrite($config,"GENERAL","screenresolution",$screenres)
   iniwrite($config,"GENERAL","sensibility",$sensibility)
   iniwrite($config,"GENERAL","FIRSTRUN",1)
Else
   $error0 = 0
   $windowname = iniread($config,"GENERAL","windowname","0")
   if $windowname = "0" then error(1)
   $screenres = iniread($config,"GENERAL","screenresolution","0")
   if $screenres = "0" then error(1)
   $sensibility = iniread($config,"GENERAL","sensibility","0")
   if $sensibility = "0" then error(1)
EndIf
SplashTextOn("","please wait while we fetch stuff real quick :-)",500,100,default,default,32)
global $movetime = iniread($config,"aimbot","movetime",1000)
global $correctionradius = iniread($config,"aimcorrection","correctionradius",100)
global $accmin = iniread($config,"relax","accmin",0)
global $accmax = iniread($config,"relax","accmax",50)
global $holdmin = iniread($config,"relax","holdmin",40)
global $holdmax = iniread($config,"relax","holdmax",80)
global $maxinterval = iniread($config,"relax","maxinterval",179)
global $ycorrection = iniread($config,"aim","ycorrection",35)
global $slideracc = iniread($config,"aimbot","slideracc",20)
global $sliderspdcorrection = iniread($config,"aimbot","sliderspdcorrection",1)
global $lookonline = iniread($config,"GENERAL","lookonline",1)
global $usemouse = iniread($config,"relax","usemouse",1)
global $key = stringsplit(iniread($config,"relax","key","z,x"),",")
global $keycodes = getkeycodes()
global $htmlname = iniread($config,"GENERAL","htmlname","g5i60ntyqx.html")
global $hotkey = stringsplit(iniread($config,"GENERAL","hotkey","{END},{HOME}"),",")
global $spinlinemin = iniread($config,"autospin","spinlinemin",75)
global $spinlinemax = iniread($config,"autospin","spinlinemax",150)
global $spinvariation = IniRead($config,"autospin","spinvariation",10)
global $spinsps = iniread($config,"autospin","spinsps",10)
global $scanprecision = iniread($config,"Performance","scanprecision",256)
global $bezierprecision = iniread($config,"Performance","bezierprecision",0.001)
hotkeyset($hotkey[1],"_exit")
hotkeyset($hotkey[2],"mainguiloop")
$screenres = stringsplit($screenres,"x")
$sensibility = number($sensibility)
if not processexists("osu!.exe") Then
   error(2)
EndIf
$osupid = ProcessWait("osu!.exe")
global $osumap = _MemoryOpen($osupid)
if @error then error(@error+2)
global $loc = stringleft(Processgetlocation($osupid),stringlen(Processgetlocation($osupid))-8) & "Songs\"
$address = findaddress()
;$address = getaddress()
;$address = 0x00286EAC
if not IsArray($address) Then
   error(12)
EndIf
$h = WinGetHandle("osu!")
if @error then error(18)
$rect = dllstructcreate("struct;long left;long top;long right;long bottom;endstruct")
if @error then error(@error+6)
dllcall($User32,"bool","GetClientRect","hwnd",$h,"struct*",$rect)
if @error then error(19)
$screenres[1] = _MemoryRead($address[6],$osumap)
$screenres[2] = _MemoryRead($address[7],$osumap)
global $final = ""
global $mode = 0
global $xmod = ($screenres[2] / 496)
global $ymod = ($screenres[2] / 496)
global $scale = $screenres[2] / 480
global $marginLeft = ((640 - 512) * $scale / 2) + (($screenres[1] - (800 * $screenres[2] / 600)) / 2)
global $marginTop = ((480 - 384) * $scale / 2)
global $osuCoordX = dllstructgetdata($rect,1)
global $osuCoordY = dllstructgetdata($rect,2)
if $osuCoordY <= 0 and $osuCoordX <= 0 then
   $osuCoordY = 13
   $osuCoordX = 0
EndIf
global $listsongs
dim $listsongs[3]
global $listdiff
dim $listdiff[2][3]
$listdiff[1][1] = 1000000
global $songs
global $diffselected = ""
global $exitt = 0
global $songfile
global $version
global $coords
global $final
global $diff
;global $bpm
global $exit
global $spin
global $useinternal = 0
global $hardrock = 0
Global $buffer = DllStructCreate('dword')
global $bufferptr = DllStructGetPtr($buffer)
global $buffersize = DllStructGetSize($buffer)
;global $rtdll = dllopen("rt.dll")
;global $ntdll = dllopen("ntdll.dll")
splashoff()
#Region ### START koda GUI section ### Form=
$Form1 = GUICreate($windowname, 616, 420, 190, 213)
$menutab = GUICtrlCreateMenu("&options")
$hotkeystab = GUICtrlCreateMenuItem("hotkeys"&@TAB&"", $menutab)
$optionstab = GUICtrlCreateMenuItem("options"&@TAB&"", $menutab)
$securitytab = GUICtrlCreateMenuItem("security"&@TAB&"", $menutab)
$toolswin = GUICtrlCreateGroup("which tool?", 16, 272, 241, 120)
GUIStartGroup()
$relaxbox = GUICtrlCreateRadio("relax", 24, 296, 73, 17)
$aimccbox = GUICtrlCreateRadio("aim correction", 24, 320, 89, 17)
$aimbotbox = GUICtrlCreateRadio("auto", 24, 344, 65, 17)
$relaxccbox = GUICtrlCreateRadio("relax + aim correction", 120, 296, 137, 17)
$relaxbotbox = GUICtrlCreateRadio("relax + auto", 120, 320, 113, 17)
$spinrad = GUICtrlCreateRadio("spinhack only", 120, 344, 113, 17)
$spinbox = GUICtrlCreateCheckbox("spinhack", 24, 368, 89, 17)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$search = GUICtrlCreateInput("enter song name or beatmap id", 24, 16, 233, 21)
$listsongs[1] = GUICtrlCreateListView("song name|beatmap id", 8, 40, 314, 198, BitOR($GUI_SS_DEFAULT_LISTVIEW,$LVS_SORTASCENDING,$LVS_AUTOARRANGE,$WS_HSCROLL,$WS_VSCROLL))
GUICtrlSendMsg(-1, $LVM_SETCOLUMNWIDTH, 0, 300)
GUICtrlSendMsg(-1, $LVM_SETCOLUMNWIDTH, 1, 50)
$selectdiff = GUICtrlCreateGroup("which difficulty?", 376, 58, 137, 156)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$loadbutton = GUICtrlCreateButton("load", 520, 88, 75, 25)
global $Labelready = GUICtrlCreateLabel("ready", 400, 344, 38, 17)
global $Labelready2 = GUICtrlCreateLabel("no", 438, 344, 150, 17)
global $Labelstatus = GUICtrlCreateLabel("status:", 400, 368, 37, 17)
global $Labelstatus2 = GUICtrlCreateLabel("not initialized", 438, 368, 150, 17)
$initbutton = GUICtrlCreateButton("initalize", 264, 312, 75, 25)
$updatebutton = GUICtrlCreateButton("update song list", 256, 16, 99, 25)
$hrbox = GUICtrlCreateCheckbox("hard rock", 520, 64, 97, 17)
guiregistermsg($WM_COMMAND,"buttonpressed")
GUICtrlSetColor($Labelready2,"0xFF0000")
GUICtrlSetColor($Labelstatus2,"0xFF0000")
GUISetState(@SW_SHOW)
#EndRegion ### END koda GUI section ###
mainguiloop()

func findaddress();finds the address [1]-[4] time addresses [5] = active song [6] = xres [7] = yres
   dim $address[8]
   $aob = "B4 17 00 00 14 13 00 00 B8 17 00 00 14 13 00 00"
   $add = _AOBScan($osumap,$aob)
   $address[1] = $add + 0xA20
   $address[2] = $address[1] + 0x4
   $address[3] = $address[1] + 0x8
   $address[4] = $address[1] + 0xC
   $address[5] = $address[1] + 0xA34
   $address[6] = $address[1] + 0x160
   $address[7] = $address[6] + 0x4
   if $add <> 0 Then
      return $address
   EndIf
EndFunc

func _exit();exit tool and close handles
   msgbox(0,"exiting","see you next time!")
   if IsDeclared($osumap) then
      _MemoryClose($osumap)
   EndIf
   Exit
EndFunc

Func ProcessGetLocation($iPID); get process location, function not by me, got it in autoit forums
   Local $aProc = DllCall('kernel32.dll', 'hwnd', 'OpenProcess', 'int', BitOR(0x0400, 0x0010), 'int', 0, 'int', $iPID)
   If $aProc[0] = 0 Then Return SetError(1, 0, '')
   Local $vStruct = DllStructCreate('int[1024]')
   DllCall('psapi.dll', 'int', 'EnumProcessModules', 'hwnd', $aProc[0], 'ptr', DllStructGetPtr($vStruct), 'int', DllStructGetSize($vStruct), 'int_ptr', 0)
   Local $aReturn = DllCall('psapi.dll', 'int', 'GetModuleFileNameEx', 'hwnd', $aProc[0], 'int', DllStructGetData($vStruct, 1), 'str', '', 'int', 2048)
   If StringLen($aReturn[3]) = 0 Then Return SetError(2, 0, '')
   Return $aReturn[3]
EndFunc


func stop(); set $exit to 1, making every tool to exit and uninitialize tool
   $exit = 1
EndFunc

func launchrelax($notes); launch relax in a DllCall (tried to write relax in c++ to make it more precise but failed every time! relax function is called, the process stops working (i dont have experience with c++))
   for $i = 1 to $notes[0][0]
	  ;_arraydisplay($notes)
	  if $notes[$i][3] = "left" Then
		 $notes[$i][3] = 1
	  ElseIf $notes[$i][3] = "right" Then
		 $notes[$i][3] = 2
	  Else
		 $notes[$i][3] = 1
	  EndIf
   Next
   $relaxbuffer = DllStructCreate('dword')
   dllcall($rtdll,'int','relax','dword*',$notes,'int',$address[2],'int',$osumap[1],'dword',$usemouse,'word',$keycodes,'ptr',DllStructGetPtr($relaxbuffer))
   if @error then msgbox(0,"",@error)
   msgbox
   while 1
	  if dllstructgetdata($relaxbuffer,1) = 1 Then
		 ExitLoop
	  EndIf
	  if dllstructgetdata($relaxbuffer,1) > 1 then
		 msgbox(0,"",dllstructgetdata($relaxbuffer,1))
	  EndIf
   WEnd
EndFunc

func getkeycodes(); get keycodes to be used in launchrelax()
   dim $tkeycodes[3]
   local $poskeys[27]  = [26,"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
   local $eqkeys[27] = [26,0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48,0x49,0x4A,0x4B,0x4C,0x4D,0x4E,0x4F,0x50,0x51,0x52,0x53,0x54,0x55,0x56,0x57,0x58,0x59,0x5A]
   for $a = 1 to 2
      for $i = 1 to $poskeys[0]
	     if $key[$a] = $poskeys[$i] Then
		    $tkeycodes[$a] = $eqkeys[$i]
	     EndIf
      Next
   Next
   return $tkeycodes
EndFunc

func error($Nerror);semi error handler
   splashoff()
   switch $Nerror
      case 1
	     msgbox(0,"error!","couldn't read the ini!" & @CRLF & "error code: " & 1)
	     $asw = msgbox(0,"reset","do you want to delete the ini?" & @CRLF & "(if the error persists, deleting the ini is an option. it will reset all your saved information and presets.)")
	     if $asw = 1 Then
		    filedelete($config)
		    msgbox(0,"success!","ini deleted succefully, reboot the tool")
		    _exit()
	     endif
	  case 2
		 msgbox(0,"error!","can't do anything without osu! open. make sure you're running stable (fallback), too." & @CRLF & "error code: " & 2)
         _exit()
	  case 3
		 msgbox(0,"error!","error code: " & 3)
		 _exit()
	  case 4
		 msgbox(0,"error!","failed to open Kernel32.dll, relaunch and try again." & @CRLF & "error code: " & 4)
		 _exit()
	  case 5
		 msgbox(0,"error!","fail to attach to osu!.exe, please check if you're running stable (fallback)." & @CRLF & "error code: " & 5)
		 _exit()
	  case 6
		 msgbox(0,"error!","error code: " & 6)
		 _exit()
	  case 7
		 msgbox(0,"error!","error code: " & 7)
		 _exit()
	  case 8
		 msgbox(0,"error!","error code: " & 8)
		 _exit()
	  case 9
		 msgbox(0,"error!","not enough RAM available, close out some applications or get a better computer." & @CRLF & "error code: " & 9)
		 _exit()
	  case 10
		 msgbox(0,"error!","not enough RAM available, close out some applications or get a better computer." & @CRLF & "error code: " & 10)
		 _exit()
	  case 11
		 msgbox(0,"error!","osu! is being a fiesty one! cannot cling to osu!.exe" & @CRLF & "error code: " & 11)
		 _exit()
	  case 12
		 msgbox(0,"error!","something went wrong: finding address" & @CRLF & "error code: " & 12)
		 _exit()
	  case 13
		 msgbox(0,"error!","something went wrong: get points" & @CRLF & "error code: " & 13)
	  case 14
		 msgbox(0,"error!","something went wrong: color points" & @CRLF & "error code: " & 14)
	  case 15
		 msgbox(0,"error!","Somenting went wrong: calculate BPM" & @CRLF & "error code: " & 15)
	  case 16
	     msgbox(0,"error!","something went wrong : object order" & @CRLF & "error code: " & 16)
	  case 17
		 msgbox(0,"error!","something went wrong: fix timer" & @CRLF & "error code: " & 17)
	  case 18
		 msgbox(0,"error!","failed to get osu!'s handle." & @CRLF & "error code: " & 18)
		 _exit()
	  case 19
		 msgbox(0,"error!","osu! coordinates won't work with us, houston!" & @CRLF & "error code: " & 19)
		 _exit()
	  case 20
		 msgbox(0,"error!","Something went wrong: P slider" & @CRLF & "error code: " & 20)
		 mainguiloop()
	  case 21
		 msgbox(0,"error!","you've got a unsupported slider type, possibly a 2b map." & @CRLF & "error code: " & 21)
		 mainguiloop()
	  case 22
		 msgbox(0,"error!","you've got a unsupported slider type, possibly a 2b map." & @CRLF & "error code: " & 22)
		 mainguiloop()
	  case 23
		 msgbox(0,"error!","slider time broke. try again." & @CRLF & "error code: " & 23)
	  case 24
		 msgbox(0,"error!","scan precision can't be less then 4! try again." & @CRLF & "error code: " & 24)
	  case 25
		 msgbox(0,"error","slider length precision needs to be in range of 0.1! try again." & @CRLF & "error code " & 25)
   EndSwitch
EndFunc

func positive($number)
   if $number < 0 Then return ($number * -1)
   return $number
EndFunc

func fixangle($x,$y,$a)
   If $x >= 0 Then; 0 - 180
	  If $y <= 0 Then; 0 - 90
		 $angle = 90-$a
	  Else; 90 - 180
		 $angle = 90+$a
	  EndIf
   Else; 180 - 360
	  If $y >= 0 Then; 180 - 270
		 $angle = 180+(90-$a)
	  Else; 270 - 360
		 $angle = 270+$a
	  EndIf
   EndIf
   $angle -= 90
   if $angle <= 0 then $angle += 360
   return $angle
EndFunc
