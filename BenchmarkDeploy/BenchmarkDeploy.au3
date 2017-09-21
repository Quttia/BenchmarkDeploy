#Region
#AccAu3Wrapper_Icon=logo.ico								 ;程序图标
#AccAu3Wrapper_UseX64=y										 ;是否编译为64位程序(y/n)注：这个地方一定要改，否则调用comspec会出错
#AccAu3Wrapper_OutFile=										 ;输出的Exe名称
#AccAu3Wrapper_OutFile_x64=									 ;64位输出的Exe名称
#AccAu3Wrapper_UseUpx=n										 ;是否使用UPX压缩(y/n) 注:开启压缩极易引起误报问题
#AccAu3Wrapper_Res_Comment=									 ;程序注释
#AccAu3Wrapper_Res_Description=								 ;程序描述
#AccAu3Wrapper_Res_Fileversion=1.0.0.2
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
	脚本功能:	部署测试环境
	更新日志:	2017.08.15---------------创建文件

#ce -----------------------------------------------------------------------

#include <FileConstants.au3>
#include <File.au3>

Global $sMac ; 物理地址
Global $sShareMapPath ;服务器映射地址
Global $sUser ;服务器用户名
Global $sPsd ;服务器密码
Global $sLogPath ;本地日志文件路径
Global $sServerLogPath ;服务器日志文件路径

_Main()

Func _Main()
	
	ConsoleWrite(@CRLF & "Benchmark Deploy Start......" & @CRLF)
	
	;初始化MAC地址，日志文件路径
	For $i = 0 To 9
		Sleep(5000)
		If _API_Get_NetworkAdapterMAC() = 1 Then
			ExitLoop
		EndIf
	Next
	
	_Read_ShareMapPath() ;获取配置文件中的服务器共享地址映射配置
	
	_CreateMap() ;在PE上建立服务器上共享的映射
	
	_DownloadTools() ;下载基准测试软件
	
	_Run_Benchmark_Test() ; 运行测试软件
	
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
		;写日志文件
		$sLogPath = @ScriptDir & "\ConfigFile\BenchmarkTest.log"
		FileDelete($sLogPath)
		_FileWriteLog($sLogPath, "-------基准测试部署开始-------")
		_FileWriteLog($sLogPath, "成功;获取本机IP地址:" & $sIP)
		_FileWriteLog($sLogPath, "成功;获取本机MAC地址:" & $sMac)
		Return 1
	EndIf
	
EndFunc   ;==>_API_Get_NetworkAdapterMAC


;==========================================================================
; 函数名：_Read_ShareMapPath
; 说明：获取配置文件中的服务器共享地址映射配置
;		成功: 初始化服务器共享地址映射；注意地址最后要加斜杠，如\\192.168.40.1\share\
;　　　 失败: 运行终止
; 参数：无
; 返回值：无
;==========================================================================
Func _Read_ShareMapPath()
	
	Local Const $sFilePath = @ScriptDir & "\ConfigFile\ShareMapConfig.ini"
	
	;服务器共享地址映射
	Local $sRead = IniRead($sFilePath, "ShareMap", "ShareMapPath", "Error")
	If $sRead = "Error" Then
		_FileWriteLog($sLogPath, "失败;获取配置文件中的服务器共享地址映射失败，程序退出")
		;Shutdown($SD_SHUTDOWN)
		Exit
	Else
		$sShareMapPath = $sRead
		_FileWriteLog($sLogPath, "成功;获取配置文件中的服务器共享地址映射配置：" & $sShareMapPath)
	EndIf
	
	;服务器登录
	$sRead = IniRead($sFilePath, "User", "User", "Error")
	If $sRead = "Error" Then
		_FileWriteLog($sLogPath, "失败;获取配置文件中的服务器用户名失败，程序退出")
		;Shutdown($SD_SHUTDOWN)
		Exit
	Else
		$sUser = $sRead
		_FileWriteLog($sLogPath, "成功;获取配置文件中的服务器用户名：" & $sUser)
	EndIf
	
	$sRead = IniRead($sFilePath, "Psd", "Psd", "Error")
	If $sRead = "Error" Then
		_FileWriteLog($sLogPath, "失败;获取配置文件中的服务器密码失败，程序退出")
		;Shutdown($SD_SHUTDOWN)
		Exit
	Else
		$sPsd = $sRead
		_FileWriteLog($sLogPath, "成功;获取配置文件中的服务器密码")
	EndIf
	
EndFunc   ;==>_Read_ShareMapPath


;==========================================================================
; 函数名：_CreateMap
; 说明：1.在PE上建立服务器上共享的映射
;~		2.同步服务器时间到本机
; 参数：无
; 返回值：无
;==========================================================================
Func _CreateMap()
	
	Local $sCmdStr = "net use * /del /y && net use T: " & StringLeft($sShareMapPath, StringLen($sShareMapPath) - 1) & ' "' & $sPsd & '" /user:' & StringTrimRight(StringTrimLeft($sShareMapPath, 2), 6) & $sUser
	Local $bFlag = True
	$sServerLogPath = $sShareMapPath & "\LogFile\" & $sMac & "\BenchmarkTest\"
	_FileWriteLog($sLogPath, "成功;获取在PE上建立服务器上共享的映射命令行：" & $sCmdStr)
	
	For $i = 0 To 11
		RunWait(@ComSpec & " /c " & $sCmdStr, "")
		
		If FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE + $FC_CREATEPATH) And Ping("www.baidu.com") > 0 Then
			_FileWriteLog($sLogPath, "成功;在PE上建立服务器上共享的映射")
			$bFlag = False
			ExitLoop
		Else
			_FileWriteLog($sLogPath, "重试" & $i & ";在PE上建立服务器上共享的映射")
			
			;重新获取ip地址
			RunWait(@ComSpec & " /c ipconfig/release", "")
			Sleep(2000)
			RunWait(@ComSpec & " /c ipconfig/renew", "")
			Sleep(3000)
		EndIf
	Next
	
	If $bFlag Then
		_FileWriteLog($sLogPath, "失败;在PE上建立服务器上共享的映射失败")
		;Shutdown($SD_SHUTDOWN)
		Exit
	Else
		;由于WIN10PE时区的原因，需要先修改时区，才能同步
		$sCmdStr = "net time " & StringTrimRight($sShareMapPath, 7) & " /set /y"
		_FileWriteLog($sLogPath, "成功;获取同步服务器时间到本机的命令行：" & $sCmdStr)
		RunWait(@ComSpec & " /c " & $sCmdStr, "")
		_FileWriteLog($sLogPath, "成功;同步服务器时间到本机成功")
	EndIf
	
EndFunc   ;==>_CreateMap


;==========================================================================
; 函数名：	_DownloadTools
; 说明：	下载两个软件到C盘目录
; 参数：无
; 返回值：无
;==========================================================================
Func _DownloadTools()
	
	Local $sBenchmarkPath = $sShareMapPath & "\Benchmark"
	Local $sDestPath = "C:\"
	
	If DirCopy($sBenchmarkPath, $sDestPath, $FC_OVERWRITE) = 1 Then
		_FileWriteLog($sLogPath, "成功;下载基准测试软件成功")
	Else
		_FileWriteLog($sLogPath, "失败;下载基准测试软件失败")
	EndIf
	
EndFunc   ;==>_DownloadTools


;==========================================================================
; 函数名：	_Run_Benchmark_Test
; 说明：	运行测试软件
; 参数：无
; 返回值：无
;==========================================================================
Func _Run_Benchmark_Test()
	
	_FileWriteLog($sLogPath, "成功;运行测试软件成功")
	_FileWriteLog($sLogPath, "-------基准测试部署完成-------")
	FileCopy($sLogPath, "C:\BenchmarkTest\", $FC_OVERWRITE + $FC_CREATEPATH)
	FileCopy($sLogPath, $sServerLogPath, $FC_OVERWRITE + $FC_CREATEPATH)
	
	If FileExists("C:\BenchSoftwares\OpenHardwareMonitor\OpenHardwareMonitor.exe") Then
		Run("C:\BenchSoftwares\OpenHardwareMonitor\OpenHardwareMonitor.exe")
	EndIf
	
	Sleep(5000)
	
	If FileExists("C:\BenchSoftwares\BenchMarkTest\BenchMarkTest.exe") Then
		Run("C:\BenchSoftwares\BenchMarkTest\BenchMarkTest.exe -D")
	EndIf
	
EndFunc   ;==>_Run_Benchmark_Test

