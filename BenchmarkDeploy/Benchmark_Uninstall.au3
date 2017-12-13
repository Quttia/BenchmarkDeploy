#Region
#AccAu3Wrapper_Icon=logo.ico								 ;程序图标
#AccAu3Wrapper_UseX64=y										 ;是否编译为64位程序(y/n)注：这个地方一定要改，否则调用comspec会出错
#AccAu3Wrapper_OutFile=										 ;输出的Exe名称
#AccAu3Wrapper_OutFile_x64=									 ;64位输出的Exe名称
#AccAu3Wrapper_UseUpx=n										 ;是否使用UPX压缩(y/n) 注:开启压缩极易引起误报问题
#AccAu3Wrapper_Res_Comment=									 ;程序注释
#AccAu3Wrapper_Res_Description=								 ;程序描述
#AccAu3Wrapper_Res_Fileversion=1.0.0.392
#AccAu3Wrapper_Res_FileVersion_AutoIncrement=y				 ;自动更新版本 y/n/p=自动/不自动/询问
#AccAu3Wrapper_Res_ProductVersion=1.0						 ;产品版本
#AccAu3Wrapper_Res_Language=2052							 ;资源语言, 英语=2057/中文=2052
#AccAu3Wrapper_Res_LegalCopyright=							 ;程序版权
#AccAu3Wrapper_Res_RequestedExecutionLevel=requireAdministrator					 ;请求权限: None/asInvoker/highestAvailable/requireAdministrator
#AccAu3Wrapper_Run_Tidy=y									 ;编译前自动整理脚本(y/n)
#Obfuscator_Parameters=/cs=1 /cn=1 /cf=1 /cv=1 /sf=1 /sv=1	 ;脚本加密参数: 0/1不加密/加密, /cs字符串 /cn数字 /cf函数名 /cv变量名 /sf精简函数 /sv精简变量
#AccAu3Wrapper_DBSupport=y									 ;使字符串加密支持双字节字符(y/n) <- 可对中文字符等实现字符串加密
#AccAu3Wrapper_AntiDecompile=y								 ;是否启用防反功能(y/n) <- 简单防反, 用于应对傻瓜式反编译工具
#NoTrayIcon
#AutoIt3Wrapper_Change2CUI=y
#EndRegion

#cs -----------------------------------------------------------------------

	Au3版本:	3.3.14.2
	脚本作者:
	脚本功能:	基准测试工具运行之后的清理工作
	更新日志:	2017.08.17---------------创建文件

#ce -----------------------------------------------------------------------

#include <File.au3>
#include <Security.au3>

Global $sMac ; 物理地址
Global $sInterfaceName ;网络接口名称

_Main()

Func _Main()
	
	;初始化MAC地址
	For $i = 0 To 9
		Sleep(5000)
		If _API_Get_NetworkAdapterMAC() = 1 Then
			ExitLoop
		EndIf
	Next
	
	Local $sLogPath = "C:\BenchmarkTest\BenchmarkTest.log"
	
	; 1. 卸载测试软件
	_FileWriteLog($sLogPath, "-------基准测试清理工作开始-------")
	
	;进程残留导致无法卸载完全 BUG
	ProcessClose("Battery_Capacity_Plugin.exe")
	ProcessClose("bit.exe")
	ProcessClose("bit32.exe")
	ProcessClose("Endpoint.exe")
	ProcessClose("MemTest32.exe")
	ProcessClose("MemTest64.exe")
	ProcessClose("Microphone_Plugin.exe")
	ProcessClose("rebooter.exe")
	ProcessClose("Sound_Plugin.exe")
	ProcessClose("Webcam_Plugin.exe")

	;卸载 BurnInTest 软件
	If FileExists("C:\Program Files\BurnInTest\unins000.exe") = 1 Then
		Run("C:\Program Files\BurnInTest\unins000.exe")
		WinWaitActive("BurnInTest Uninstall")
		Send("!y")
		WinWaitActive("BurnInTest Uninstall", "BurnInTest was successfully removed from your computer.", 15)
		Send("{ENTER}")
		
		;修复无法卸载完全的BUG
		For $i = 0 To 3
			If FileExists("C:\Program Files\BurnInTest") = 0 Then
				ExitLoop
			Else
				DirRemove("C:\Program Files\BurnInTest", 1)
				_FileWriteLog($sLogPath, "成功;尝试卸载 BurnInTest 软件" & ($i + 1) & "次...")
				ConsoleWrite("成功;尝试卸载 BurnInTest 软件" & ($i + 1) & "次..." & @CRLF)
				Sleep(30000)
			EndIf
		Next
		
		_FileWriteLog($sLogPath, "成功;卸载 BurnInTest 软件成功")
		ConsoleWrite("成功;卸载 BurnInTest 软件成功..." & @CRLF)
	EndIf
	
	;删除温度监控软件文件
	Local $hWnd = WinActivate("宁美温度监控软件")
	If $hWnd <> 0 Then
		WinWaitActive($hWnd)
		WinClose($hWnd)
		WinWaitClose($hWnd)
		Sleep(3000)
		DirRemove("C:\BenchSoftwares\OpenHardwareMonitor", 1)
		Sleep(3000)
		_FileWriteLog($sLogPath, "成功;删除温度监控软件文件成功")
		ConsoleWrite("成功;删除温度监控软件文件成功..." & @CRLF)
	EndIf
	
	;2. 删除开机启动项
	RegDelete("HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run", "BenchmarkDeploy")
	_FileWriteLog($sLogPath, "成功;删除开机启动项BenchmarkDeploy成功")
	ConsoleWrite("成功;删除开机启动项BenchmarkDeploy成功..." & @CRLF)
	Sleep(2000)
	
	;3. 添加开机启动项
	Local $sSID = _Security__LookupAccountName(@UserName)[0] ;获取用户 SID
	RegWrite("HKEY_USERS\" & $sSID & "\Software\Microsoft\Windows\CurrentVersion\Run", "UPUPOO", "REG_SZ", "C:\UPUPOO\Launch.exe")
	_FileWriteLog($sLogPath, "成功;添加开机启动项UPUPOO成功：" & $sSID)
	ConsoleWrite("成功;添加开机启动项UPUPOO成功..." & @CRLF)
	Sleep(2000)
	
	;4. 改回自动获取 IP，释放静态 IP 和 DNS
	;_Get_IP_Config()
	
	;RunWait(@ComSpec & ' /c netsh interface ip set address name="' & $sInterfaceName & '" source=dhcp', "C:\Windows\System32")
	;RunWait(@ComSpec & ' /c netsh interface ip set dns name="' & $sInterfaceName & '" source=dhcp', "C:\Windows\System32")
	
	;_FileWriteLog($sLogPath, "成功;改回自动获取 IP，释放静态 IP 和 DNS成功")
	_FileWriteLog($sLogPath, "-------基准测试清理工作完成-------")
	
	;5. 上传日志到服务器，清理日志
	Local $sourceDir = "C:\BenchmarkTest"
	Local $destDir = "T:\LogFile\" & $sMac & "\BenchmarkTest"
	
	DirCopy($sourceDir, $destDir, $FC_OVERWRITE)
	Sleep(3000)
	DirRemove($sourceDir, 1)
	ConsoleWrite("成功;清理日志..." & @CRLF)
	Sleep(3000)
	
EndFunc   ;==>_Main


;==========================================================================
; 函数名：_API_Get_NetworkAdapterMAC
; 说明：获取本机MAC地址
;		成功：初始化MAC地址，如 “30-85-A9-40-EB-B1”;
;			  初始化日志文件路径
;　　　 失败: @error=1
; 参数：无
; 返回值：1：成功；0：失败
;==========================================================================
Func _API_Get_NetworkAdapterMAC()
	Local $sIP = @IPAddress1
	Local $MAC, $MACSize
	Local $i, $s, $r, $iIP

	$MAC = DllStructCreate("byte[6]")
	$MACSize = DllStructCreate("int")

	DllStructSetData($MACSize, 1, 6)
	$r = DllCall("Ws2_32.dll", "int", "inet_addr", "str", $sIP)
	$iIP = $r[0]
	$r = DllCall("iphlpapi.dll", "int", "SendARP", "int", $iIP, "int", 0, "ptr", DllStructGetPtr($MAC), "ptr", DllStructGetPtr($MACSize))
	$s = ""
	For $i = 0 To 5
		If $i Then $s &= "-"
		$s &= Hex(DllStructGetData($MAC, 1, $i + 1), 2)
	Next
	$sMac = $s
	
	;PE启动时有可能初始化未完成无法获取Mac地址
	If $sMac = "00-00-00-00-00-00" Then
		Return 0
	Else
		Return 1
	EndIf
	
EndFunc   ;==>_API_Get_NetworkAdapterMAC


;==========================================================================
; 函数名：_Get_IP_Config
; 说明：获取IP配置信息
; 参数：无
; 返回值：无
;==========================================================================
Func _Get_IP_Config()
	
	;生成IP配置信息文件
	Local $sIpconfig = "C:\ipconfig.txt"
	Local $aArray = 0
	
	_FileReadToArray($sIpconfig, $aArray)
	$sInterfaceName = StringSplit($aArray[2], '"', $STR_NOCOUNT)[1] ;网络配置名称
	
	;删除IP配置信息文件
	FileDelete($sIpconfig)

EndFunc   ;==>_Get_IP_Config
