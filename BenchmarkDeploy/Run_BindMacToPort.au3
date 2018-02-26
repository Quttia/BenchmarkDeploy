#Region
#AccAu3Wrapper_Icon=logo.ico								 ;程序图标
#AccAu3Wrapper_UseX64=y										 ;是否编译为64位程序(y/n)注：这个地方一定要改，否则调用comspec会出错
#AccAu3Wrapper_OutFile=										 ;输出的Exe名称
#AccAu3Wrapper_OutFile_x64=									 ;64位输出的Exe名称
#AccAu3Wrapper_UseUpx=n										 ;是否使用UPX压缩(y/n) 注:开启压缩极易引起误报问题
#AccAu3Wrapper_Res_Comment=									 ;程序注释
#AccAu3Wrapper_Res_Description=								 ;程序描述
#AccAu3Wrapper_Res_Fileversion=1.0.0.11
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
	脚本功能:	启动 bit
	更新日志:	2017.09.18---------------创建文件

#ce -----------------------------------------------------------------------

_Main()

Func _Main()
	
	If $CmdLine[1] = "-O" Then
		If FileExists("D:\BindMacToPort\BindMacToPort.exe") Then
			Run("D:\BindMacToPort\BindMacToPort.exe -D")
		EndIf
		
		WinWait("扫描结果")
		WinActivate("扫描结果")
		WinWaitActive("扫描结果")
		Send("{ENTER}")
	ElseIf $CmdLine[1] = "-C" Then
		Local $hWnd = WinActivate("MacToPort")
		If $hWnd <> 0 Then
			WinWaitActive($hWnd)
			WinClose($hWnd)
			WinWaitClose($hWnd)
		EndIf
	EndIf
	
EndFunc   ;==>_Main
