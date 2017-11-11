#Region
#AccAu3Wrapper_Icon=logo.ico								 ;程序图标
#AccAu3Wrapper_UseX64=y										 ;是否编译为64位程序(y/n)注：这个地方一定要改，否则调用comspec会出错
#AccAu3Wrapper_OutFile=										 ;输出的Exe名称
#AccAu3Wrapper_OutFile_x64=									 ;64位输出的Exe名称
#AccAu3Wrapper_UseUpx=n										 ;是否使用UPX压缩(y/n) 注:开启压缩极易引起误报问题
#AccAu3Wrapper_Res_Comment=									 ;程序注释
#AccAu3Wrapper_Res_Description=								 ;程序描述
#AccAu3Wrapper_Res_Fileversion=1.0.0.21
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
	脚本功能:	锁定自动获取的 IP 信息，防止中途 IP 丢失
	更新日志:	2017.09.24---------------创建文件

#ce -----------------------------------------------------------------------

#include <File.au3>
#include <StringConstants.au3>

Global $sLogPath ;本地日志文件路径
Global $aIPArray[6] ;IP配置信息数组

_Main()

Func _Main()
	
	ConsoleWrite(@CRLF & "Lock IP Configuration Start......" & @CRLF)
	
	;自动获取的 IP 信息
	_Get_IP_Config()
	
	;将自动获取的 IP 信息固定为静态 IP 信息
	Local $sCmdStr = StringFormat('netsh interface ip set address "%s" static %s %s %s 1', $aIPArray[5], $aIPArray[0], $aIPArray[1], $aIPArray[2])
	RunWait(@ComSpec & " /c " & $sCmdStr, "")
	
	$sCmdStr = 'netsh interface ip set dns name="' & $aIPArray[5] & '" source=static addr=' & $aIPArray[3] & " register=primary validate=no"
	RunWait(@ComSpec & " /c " & $sCmdStr, "")
	
	;部分网络没有备用 DNS
	If StringInStr($aIPArray[4], "主要") = 0 Then
		$sCmdStr = 'netsh interface ip add dns name="' & $aIPArray[5] & '" addr=' & $aIPArray[4] & ' index=2 validate=no'
		RunWait(@ComSpec & " /c " & $sCmdStr, "")
	EndIf
	
	ConsoleWrite(@CRLF & "Lock IP Configuration End......" & @CRLF)
	
EndFunc   ;==>_Main


;==========================================================================
; 函数名：_Get_IP_Config
; 说明：获取IP配置信息
; 参数：无
; 返回值：无
;==========================================================================
Func _Get_IP_Config()
	
	;生成IP配置信息文件
	#cs
		接口 "以太网" 的配置
		DHCP 已启用:                          是
		IP 地址:                           172.16.11.28
		子网前缀:                        172.16.11.0/24 (掩码 255.255.255.0)
		默认网关:                         172.16.11.254
		网关跃点数:                       0
		InterfaceMetric:                      10
		静态配置的 DNS 服务器:            202.103.24.68
		202.103.44.150
		用哪个前缀注册:                   只是主要
		通过 DHCP 配置的 WINS 服务器:     无
	#ce
	
	Local $sIpconfig = "C:\ipconfig.txt"
	RunWait(@ComSpec & ' /c netsh interface ip show config > ' & $sIpconfig, "")
	
	If Not FileExists($sIpconfig) Then
		MsgBox(0, "错误", "失败;生成IP配置信息文件失败")
		Exit
	EndIf
	
	Local $aArray = 0
	_FileReadToArray($sIpconfig, $aArray)
	If @error = 0 Then
		FileDelete($sIpconfig)
	Else
		MsgBox(0, "错误", "失败;获取IP配置信息失败")
		Exit
	EndIf
	
	;IP配置信息数组
	$aIPArray[0] = StringSplit(StringStripWS($aArray[4], $STR_STRIPALL), ":", $STR_NOCOUNT)[1] ;						IP 地址
	$aIPArray[1] = StringTrimRight(StringSplit(StringStripWS($aArray[5], $STR_STRIPALL), "码", $STR_NOCOUNT)[1], 1) ;	掩码
	$aIPArray[2] = StringSplit(StringStripWS($aArray[6], $STR_STRIPALL), ":", $STR_NOCOUNT)[1] ;						默认网关
	$aIPArray[3] = StringSplit(StringStripWS($aArray[9], $STR_STRIPALL), ":", $STR_NOCOUNT)[1] ;						首选 DNS 服务器
	$aIPArray[4] = StringStripWS($aArray[10], $STR_STRIPALL) ;															备用 DNS 服务器
	$aIPArray[5] = StringSplit($aArray[2], '"', $STR_NOCOUNT)[1] ;														网络配置名称

EndFunc   ;==>_Get_IP_Config
