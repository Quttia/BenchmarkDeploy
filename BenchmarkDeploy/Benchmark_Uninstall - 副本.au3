#Region
#AccAu3Wrapper_Icon=logo.ico								 ;程序图标
#AccAu3Wrapper_UseX64=y										 ;是否编译为64位程序(y/n)注：这个地方一定要改，否则调用comspec会出错
#AccAu3Wrapper_OutFile=										 ;输出的Exe名称
#AccAu3Wrapper_OutFile_x64=									 ;64位输出的Exe名称
#AccAu3Wrapper_UseUpx=n										 ;是否使用UPX压缩(y/n) 注:开启压缩极易引起误报问题
#AccAu3Wrapper_Res_Comment=									 ;程序注释
#AccAu3Wrapper_Res_Description=								 ;程序描述
#AccAu3Wrapper_Res_Fileversion=1.0.0.367
#AccAu3Wrapper_Res_FileVersion_AutoIncrement=y				 ;自动更新版本 y/n/p=自动/不自动/询问
#AccAu3Wrapper_Res_ProductVersion=1.0						 ;产品版本
#AccAu3Wrapper_Res_Language=2052							 ;资源语言, 英语=2057/中文=2052
#AccAu3Wrapper_Res_LegalCopyright=							 ;程序版权
#AccAu3Wrapper_Res_RequestedExecutionLevel=requireAdministrator					 ;请求权限: None/asInvoker/highestAvailable/requireAdministrator
#AccAu3Wrapper_Run_Tidy=y									 ;编译前自动整理脚本(y/n)
#Obfuscator_Parameters=/cs=1 /cn=1 /cf=1 /cv=1 /sf=1 /sv=1	 ;脚本加密参数: 0/1不加密/加密, /cs字符串 /cn数字 /cf函数名 /cv变量名 /sf精简函数 /sv精简变量
#AccAu3Wrapper_DBSupport=y									 ;使字符串加密支持双字节字符(y/n) <- 可对中文字符等实现字符串加密
#AccAu3Wrapper_AntiDecompile=y								 ;是否启用防反功能(y/n) <- 简单防反, 用于应对傻瓜式反编译工具
;#NoTrayIcon
#AutoIt3Wrapper_Change2CUI=y
#EndRegion

#cs -----------------------------------------------------------------------

	Au3版本:	3.3.14.2
	脚本作者:
	脚本功能:	基准测试工具运行之后的清理工作
	更新日志:	2017.08.17---------------创建文件

#ce -----------------------------------------------------------------------

#include <File.au3>
#include <ServiceControl.au3>

Global $sMac ; 物理地址

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
	
	;移除3DMark注册
	Local $sCmdStr = '"C:\Program Files\Futuremark\3DMark\3DMarkCmd.exe" --unregister'
	If FileExists("C:\Program Files\Futuremark\3DMark\3DMarkCmd.exe") = 1 Then
		RunWait(@ComSpec & " /c " & $sCmdStr, "")
		_FileWriteLog($sLogPath, "成功;移除3DMark注册成功")
		Sleep(5000)
	EndIf

	;卸载3DMark
	If FileExists("C:\ProgramData\Package Cache\{a0df0e52-2800-4963-9ba1-382620df4d05}\3dmark-setup.exe") = 1 Then
		$sCmdStr = '"C:\ProgramData\Package Cache\{a0df0e52-2800-4963-9ba1-382620df4d05}\3dmark-setup.exe" /uninstall /quiet'
		RunWait(@ComSpec & " /c " & $sCmdStr, "")
		_FileWriteLog($sLogPath, "成功;卸载3DMark成功")
	EndIf

	;卸载Futuremark SystemInfo
	If FileExists("C:\Program Files (x86)\Futuremark\SystemInfo\FMSISvc.exe") = 1 Then
		$sCmdStr = "MsiExec.exe /quiet /X{E540B871-3230-4C5B-AAD5-A30F64398275}"
		RunWait(@ComSpec & " /c " & $sCmdStr, "")
		_FileWriteLog($sLogPath, "成功;卸载Futuremark SystemInfo成功")
	EndIf

	;删除 Futuremark SystemInfo Service 服务
	_ServDelete("Futuremark SystemInfo Service")
	_FileWriteLog($sLogPath, "成功;删除 Futuremark SystemInfo Service 服务")
	Sleep(5000)
	
	;删除残余文件夹
	DirRemove(@LocalAppDataDir & "\Futuremark", 1)
	Sleep(1000)
	DirRemove(@AppDataCommonDir & "\Futuremark", 1)
	Sleep(1000)
	DirRemove(@AppDataCommonDir & "\Package Cache", 1)
	Sleep(1000)

	;卸载 BurnInTest 软件
	If FileExists("C:\Program Files\BurnInTest\unins000.exe") = 1 Then
		Run("C:\Program Files\BurnInTest\unins000.exe")
		WinWaitActive("BurnInTest Uninstall")
		Send("!y")
		WinWaitActive("BurnInTest Uninstall", "BurnInTest was successfully removed from your computer.")
		Send("{ENTER}")
		_FileWriteLog($sLogPath, "成功;卸载 BurnInTest 软件成功")
	EndIf
	
	;删除温度监控软件文件
	Local $hWnd = WinActivate("宁美温度监控软件")
	If $hWnd <> 0 Then
		WinWaitActive($hWnd)
		WinClose($hWnd)
		WinWaitClose($hWnd)
		Sleep(5000)
		DirRemove("C:\BenchSoftwares\OpenHardwareMonitor", 1)
		Sleep(5000)
		_FileWriteLog($sLogPath, "成功;删除温度监控软件文件成功")
	EndIf

	_FileWriteLog($sLogPath, "-------基准测试清理工作完成-------")
	
	;2. 上传日志到服务器，清理日志
	Local $source_3DMarkLog = @MyDocumentsDir & "\3DMark"
	Local $dest_3DMarkLog = "C:\BenchmarkTest\3Dmark"
	Local $sourceDir = "C:\BenchmarkTest"
	Local $destDir = "T:\LogFile\" & $sMac & "\BenchmarkTest"
	Local $desktop_File = @DesktopDir & "\deploy.bat"
	
	DirCopy($source_3DMarkLog, $dest_3DMarkLog, $FC_OVERWRITE)
	Sleep(3000)
	DirRemove($source_3DMarkLog, 1)
	Sleep(3000)
	
	DirCopy($sourceDir, $destDir, $FC_OVERWRITE)
	Sleep(3000)
	DirRemove($sourceDir, 1)
	Sleep(3000)
	
	FileDelete($desktop_File)
	Sleep(1000)
	
	;3. 删除服务器链接
	$sCmdStr = "net use * /del /y"
	RunWait(@ComSpec & " /c " & $sCmdStr, "")
	
	;4. 删除开机启动项
	RegDelete("HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run", "firstdeploy")
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
