#Region
#AccAu3Wrapper_Icon=logo.ico								 ;程序图标
#AccAu3Wrapper_UseX64=y										 ;是否编译为64位程序(y/n)注：这个地方一定要改，否则调用comspec会出错
#AccAu3Wrapper_OutFile=										 ;输出的Exe名称
#AccAu3Wrapper_OutFile_x64=									 ;64位输出的Exe名称
#AccAu3Wrapper_UseUpx=n										 ;是否使用UPX压缩(y/n) 注:开启压缩极易引起误报问题
#AccAu3Wrapper_Res_Comment=									 ;程序注释
#AccAu3Wrapper_Res_Description=								 ;程序描述
#AccAu3Wrapper_Res_Fileversion=1.0.0.360
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
	
	; 1. 卸载测试软件
	
	;移除3DMark注册
	Local $sCmdStr = '"C:\Program Files\Futuremark\3DMark\3DMarkCmd.exe" --unregister'
	If FileExists("C:\Program Files\Futuremark\3DMark\3DMarkCmd.exe") = 1 Then
		RunWait(@ComSpec & " /c " & $sCmdStr, "")
		Sleep(5000)
	EndIf
	
	;卸载3DMark
	If FileExists("C:\ProgramData\Package Cache\{a0df0e52-2800-4963-9ba1-382620df4d05}\3dmark-setup.exe") = 1 Then
		$sCmdStr = '"C:\ProgramData\Package Cache\{a0df0e52-2800-4963-9ba1-382620df4d05}\3dmark-setup.exe" /uninstall /quiet'
		RunWait(@ComSpec & " /c " & $sCmdStr, "")
	EndIf
	
	;卸载Futuremark SystemInfo
	If FileExists("C:\Program Files (x86)\Futuremark\SystemInfo\FMSISvc.exe") = 1 Then
		$sCmdStr = "MsiExec.exe /quiet /X{E540B871-3230-4C5B-AAD5-A30F64398275}"
		RunWait(@ComSpec & " /c " & $sCmdStr, "")
	EndIf
	
	;删除 Futuremark SystemInfo Service 服务
	_ServDelete("Futuremark SystemInfo Service")
	Sleep(5000)
	
	;卸载 BurnInTest 软件
	If FileExists("C:\Program Files\BurnInTest\unins000.exe") = 1 Then
		Run("C:\Program Files\BurnInTest\unins000.exe")
		WinWaitActive("BurnInTest Uninstall")
		Send("!y")
		WinWaitActive("BurnInTest Uninstall", "BurnInTest was successfully removed from your computer.")
		Send("{ENTER}")
	EndIf
	
	;删除温度监控软件文件
	Local $hWnd = WinActivate("宁美温度监控软件")
	If $hWnd <> 0 Then
		WinWaitActive($hWnd)
		WinClose($hWnd)
		WinWaitClose($hWnd)
		Sleep(5000)
	EndIf
	
	Local $hWnd = WinActivate("宁美基准测试")
	If $hWnd <> 0 Then
		WinWaitActive($hWnd)
		WinClose($hWnd)
		WinWaitClose($hWnd)
		Sleep(5000)
	EndIf
	
	;2. 清理日志
	Local $softwareDir = "C:\BenchSoftwares"
	Local $deployDir = "C:\BenchmarkDeploy"
	Local $sourceDir = "C:\BenchmarkTest"
	
	DirRemove($softwareDir, 1)
	Sleep(1000)
	DirRemove($sourceDir, 1)
	Sleep(1000)
	DirRemove($deployDir, 1)
	Sleep(1000)
	
	;3. 删除服务器链接
	$sCmdStr = "net use * /del /y"
	RunWait(@ComSpec & " /c " & $sCmdStr, "")
	
EndFunc   ;==>_Main
