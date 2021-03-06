On Error Resume Next

Const HKEY_CLASSES_ROOT  = &H80000000
Const HKEY_CURRENT_USER  = &H80000001
Const HKEY_LOCAL_MACHINE = &H80000002
Const HKEY_USERS         = &H80000003

Const ForReading         =  1  ' 只读模式
Const ForWriting         =  2  ' 只写模式
Const ForAppending       =  8  ' 文件末尾追加
Const TristateFalse      =  0  ' ASCII 格式
Const TristateTrue       = -1  ' Unicode 格式
Const TristateUseDefault = -2  ' 系统默认格式

Public strComputer
strComputer              = "." ' 本地计算机

Public OS: Set OS = GetOSInfos()

' 获取当前系统部分信息
Function GetOSInfos()
    Dim OS_: Set OS_ = CreateObject("Scripting.Dictionary")

    Dim ObjOS, O
    For Each ObjOS In GetObject("winmgmts:").InstancesOf("Win32_OperatingSystem")
        For Each O In ObjOS.Properties_
            OS_.Add O.Name, O.Value
        Next
    Next

    Dim rEx_OSv, regEx_OSv
    rEx_OSv = "(\d+)\.(\d+).*"
    Set regEx_OSv = New RegExp
    regEx_OSv.Pattern = rEx_OSv
    regEx_OSv.IgnoreCase = False
    regEx_OSv.Global = True

    OS_.Add "NT", regEx_OSv.Replace(OS_.Item("Version"), "$1$2")

    Dim rEx_OSa, regEx_OSa
    rEx_OSa = "\d+"
    Set regEx_OSa = New RegExp
    regEx_OSa.Pattern = rEx_OSa
    regEx_OSa.IgnoreCase = False
    regEx_OSa.Global = True

    Dim Matches, Match, Architecture
    Set Matches = regEx_OSa.Execute(OS_.Item("OSArchitecture"))
    For Each Match In Matches
        Architecture = Architecture & Match.Value
    Next

    If (Architecture = 32) Then Architecture = 86

    OS_.Add "Architecture", "x" & Architecture

    Set regEx_OSv = Nothing
    Set regEx_OSa = Nothing

    Set GetOSInfos = OS_
End Function

Dim fso, WshShell, WshSysEnv, SystemRoot, FolderPath, TargetFolder
Set fso       = CreateObject("Scripting.FileSystemObject")
Set WshShell  = CreateObject("WScript.Shell")
Set WshSysEnv = WshShell.Environment("Process")
SystemRoot    = WshSysEnv.Item("SystemRoot")
FolderPath    = fso.GetParentFolderName(WScript.ScriptFullName)
TargetFolder  = FolderPath

WshShell.Popup "即将开始制作文件，请耐心等待...", 3, "提示信息", 0 + 64 + 4096

Dim temp_dir, tools_dir, steam_dir, config_dir
temp_dir   = TargetFolder & "\temp"
tools_dir  = TargetFolder & "\Tools"
steam_dir  = TargetFolder & "\Steam"
config_dir = TargetFolder & "\Config"

If Not fso.FolderExists(temp_dir) Then fso.CreateFolder(temp_dir)


' ResourceHacker 配置
Dim ResourceHacker, ResourceHacker_Parameter, ResourceHacker_Script, ResourceHacker_Log
ResourceHacker           = Chr(34)& tools_dir & "\ResourceHacker\ResourceHacker.exe" &Chr(34)
ResourceHacker_Parameter = " -script "
ResourceHacker_Script    = Chr(34)& temp_dir & "\resourcehacker_script.txt" &Chr(34)
ResourceHacker_Log       = Chr(34)& temp_dir & "\ResourceHacker.log" &Chr(34)

' 7zSFX 模块
Dim SFX: Set SFX = CreateObject("Scripting.Dictionary")
SFX.Add "x86", "7zsd_LZMA2.sfx"
SFX.Add "x64", "7zsd_LZMA2.sfx" ' 为避免 "Exception code: 0x000006ba", 本应为 7zsd_LZMA2_x64.sfx

Dim SFX_File, Cfg_7zSFX, Org_7zSFX, New_7zSFX
SFX_File = "7zSFXTools\" & SFX.Item(OS.Item("Architecture"))

Cfg_7zSFX = Chr(34)& config_dir & "\config.txt" &Chr(34)
Org_7zSFX = Chr(34)& tools_dir & "\" & SFX_File &Chr(34)
New_7zSFX = Chr(34)& temp_dir & "\7zSFX.sfx" &Chr(34)

' 设置 icon 资源
Dim SteamSetup, ICONGROUP_RC, ICON
SteamSetup   = Chr(34)& steam_dir & "\SteamSetup.exe" &Chr(34)
ICONGROUP_RC = Chr(34)& temp_dir & "\icongroup.rc" &Chr(34)
ICON         = ""


' 提取图标
' ResourceHacker Script
Dim Stream: Set Stream = CreateObject("Adodb.Stream")
Stream.Type = 2
Stream.Mode = 3
Stream.Charset = "UTF-8"
Stream.Open
Stream.WriteText "[FILENAMES]", 1
Stream.WriteText "Exe = " & SteamSetup, 1
Stream.WriteText "SaveAs = " &Chr(34)& temp_dir & "\NoOutputFile" &Chr(34), 1
Stream.WriteText "Log = " & ResourceHacker_Log, 1
Stream.WriteText "", 1
Stream.WriteText "[COMMANDS]", 1
Stream.WriteText "-extract " & ICONGROUP_RC & ", icongroup,,", 1
Stream.SaveToFile Replace(ResourceHacker_Script, Chr(34), ""), 2
Stream.Close
Set Stream = Nothing

' ResourceHacker command
WshShell.Run ResourceHacker & ResourceHacker_Parameter & ResourceHacker_Script, 0, True

Dim f, text
Set f = fso.OpenTextFile(Replace(ICONGROUP_RC, Chr(34), ""), ForReading, False, TristateTrue)
text = f.ReadAll
f.Close

Dim rEx, regEx
rEx = ".*" &Chr(34)& "(\w*\.ico)" &Chr(34)& ".*"
Set regEx = New RegExp
regEx.Pattern = rEx
regEx.IgnoreCase = True
regEx.Global = False

Dim IconFileName
IconFileName = regEx.Replace(text, "$1")
IconFileName = Replace(IconFileName, vbCr, "")
IconFileName = Replace(IconFileName, vbLf, "")

ICON = Chr(34)& temp_dir & "\" & IconFileName &Chr(34)


' 修改图标
' ResourceHacker Script
Set Stream = CreateObject("Adodb.Stream")
Stream.Type = 2
Stream.Mode = 3
Stream.Charset = "UTF-8"
Stream.Open
Stream.WriteText "[FILENAMES]", 1
Stream.WriteText "Exe = " & Org_7zSFX, 1
Stream.WriteText "SaveAs = " & New_7zSFX, 1
Stream.WriteText "Log = " & ResourceHacker_Log, 1
Stream.WriteText "", 1
Stream.WriteText "[COMMANDS]", 1
Stream.WriteText "-modify " & ICON & ", icongroup,101,1049", 1
Stream.SaveToFile Replace(ResourceHacker_Script, Chr(34), ""), 2
Stream.Close
Set Stream = Nothing

' ResourceHacker command
WshShell.Run ResourceHacker & ResourceHacker_Parameter & ResourceHacker_Script, 0, True


' 7-Zip 配置
Dim Execute_7zip, Execute_Parameter0, Execute_Parameter1, Execute_Parameter2, Execute_OutputFileName, Execute_OutputArchive, Execute_PackageFiles, TheProgram
Execute_7zip            = Chr(34)& tools_dir & "\7-Zip\" & OS.Item("Architecture") & "\7z.exe" &Chr(34)
' 参数
Execute_Parameter0      = "a -t7z"
' 文件名
Execute_OutputFileName  = "Steam_Deploy"
' 7z 文件位置
Execute_OutputArchive   = Chr(34)& TargetFolder & "\" & Execute_OutputFileName & ".7z" &Chr(34)
' 将要打包的文件
Execute_PackageFiles    = " " & Chr(34)& config_dir   & "\" &Chr(34)&_
                          " " & Chr(34)& steam_dir    & "\" &Chr(34)&_
                          " " & Chr(34)& tools_dir    & "\" &Chr(34)&_
                          " " & Chr(34)& TargetFolder & "\make.vbs"  &Chr(34)&_
                          " " & Chr(34)& TargetFolder & "\Steam.vbs" &Chr(34)&_
                          " " & Chr(34)& TargetFolder & "\Games.ini" &Chr(34)
' 参数
Execute_Parameter1      = "-xr!*.zip -xr!ResourceHacker.ini"
' 参数
Execute_Parameter2      = "-mx=9 -ms -mf -mhc -mmt -m0=LZMA2:a=1:d=26:mf=bt4:fb=64"
' exe 文件位置
TheProgram              = Chr(34)& TargetFolder & "\" & Execute_OutputFileName & ".exe" &Chr(34)

If fso.FileExists( Replace(Execute_OutputArchive, Chr(34), "") ) Then fso.DeleteFile( Replace(Execute_OutputArchive, Chr(34), "") )

CheckSteamPackage()

' 打包文件
WshShell.Run Execute_7zip           & " " &_
             Execute_Parameter0     & " " &_
             Execute_OutputArchive  & " " &_
             Execute_PackageFiles   & " " &_
             Execute_Parameter1     & " " &_
             Execute_Parameter2, 0, True

' 制作 exe 文件
WshShell.Run "cmd.exe /C copy /y /b " &_
             New_7zSFX & " + " &_
             Cfg_7zSFX & " + " &_
             Execute_OutputArchive & " " &_
             TheProgram, 0, True

WshShell.Popup "Steam 部署工具制作完成，请在当前目录查看。", 7, "提示信息", 0 + 64 + 4096

fso.DeleteFile( Replace(Execute_OutputArchive, Chr(34), "") )


' ----------------------------------------------------------------------------------------------------------------------------------
' *************************************************
' * 已安装的 Steam 客户端版本比当前目录的新时，提示用户
' *************************************************
Sub CheckSteamPackage()
    Dim SubKeyPath, ValueName, SteamInstallPath
    SubKeyPath = "Software\Valve\Steam"
    ValueName = "InstallPath"
    SteamInstallPath = ""

    SteamInstallPath = GetRegStringValue(HKEY_LOCAL_MACHINE, SetRightRegNodePath(SubKeyPath, OS.Item("Architecture")), ValueName)

    If IsNull(SteamInstallPath) Then Exit Sub

    Dim steam_manifest
    steam_manifest = "steam_client_win32.manifest"

    Dim steam_package_current, steam_package_install
    steam_package_current = steam_dir        & "\package\"
    steam_package_install = SteamInstallPath & "\package\"

    Dim steam_manifest_current, steam_manifest_install
    steam_manifest_current = steam_package_current & steam_manifest
    steam_manifest_install = steam_package_install & steam_manifest

    If Not fso.FileExists(SteamInstallPath & "\Steam.exe") Or Not fso.FileExists(steam_manifest_install) Then Exit Sub

    Dim steam_package_version_current, steam_package_version_install
    steam_package_version_current = GetSteamPackageVersion(steam_manifest_current) ' 不存在时值为 0
    steam_package_version_install = GetSteamPackageVersion(steam_manifest_install) ' 不存在时值为 0

    If (steam_package_version_current - steam_package_version_install < 0) Then
        Dim choose

        If fso.FileExists(steam_manifest_current) Then
            choose = WshShell.Popup(Chr(34)& SteamInstallPath &Chr(34)& vbCrLf & _
                "在该位置找到 Steam 客户端，并且版本比当前目录的要新。" & vbCrLf & vbCrLf & _
                "是否要更新到当前目录 (默认更新) ?", 7, "提示信息", 4 + 64 + 4096)
        End If

        If (Not fso.FileExists(steam_manifest_current) Or choose = vbYes Or choose = -1) Then
            If Not fso.FolderExists(steam_package_current) Then
                fso.CreateFolder(steam_package_current)
            End If

            fso.DeleteFile(steam_package_current & "*")

            Dim objShell, target, source
            Set objShell = CreateObject("Shell.Application")
            Set target = objShell.NameSpace(steam_package_current)
            Set source = objShell.NameSpace(steam_package_install)

            If (Not target Is Nothing) Then
                target.CopyHere source.Items(), 16
            End If
        End If
    End If
End Sub


' ***********************************************
' * 获取 Steam Package 版本号
' ***********************************************
Function GetSteamPackageVersion(file)

    GetSteamPackageVersion = 0

    If Not fso.FileExists(file) Then Exit Function

    Dim Stream, version, rEx, regEx

    Set Stream = CreateObject("Adodb.Stream")
    Stream.Type = 2
    Stream.Mode = 3
    Stream.Charset = "UTF-8"
    Stream.Open
    Stream.LoadFromFile(file)
    version = Stream.ReadText
    Stream.Close
    Set Stream = Nothing

    rEx = Chr(34)& "version" &Chr(34)& "\s*" &Chr(34)& "(\d*)" &Chr(34)
    version = RegExpTest(rEx, version, "")

    Set regEx = New RegExp
    regEx.Pattern = rEx
    regEx.IgnoreCase = True
    regEx.Global = False

    version = regEx.Replace(version, "$1")

    If IsNumeric(version) Then GetSteamPackageVersion = version
End Function
' ----------------------------------------------------------------------------------------------------------------------------------


' 读取注册表值: string
Function GetRegStringValue(RootKey, SubKeyName, ValueName)
    Dim objReg, Value

    Set objReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")

    Return = objReg.GetStringValue(RootKey, SubKeyName, ValueName, Value)

    ' If (Return <> 0) Or (Err.Number <> 0) Then
    '     MsgBox "GetRegStringValue failed. Error = " & Err.Number
    ' End If

    GetRegStringValue = Value
End Function


' 设置 x86, x64 正确的注册表节点
Function SetRightRegNodePath(strKeyPath, OSArchitecture)
    Dim NodeName: Set NodeName = CreateObject("Scripting.Dictionary")
    NodeName.Add "x86", ""
    NodeName.Add "x64", "WOW6432Node"

    Dim StrNode: StrNode = NodeName.Item(OSArchitecture)
    IF (StrNode <> "") Then StrNode = "\" & StrNode

    Dim rEx_a, regEx_a
    rEx_a = "([A-Za-z]+)\\(\w+)(.*)"
    Set regEx_a = New RegExp
    regEx_a.Pattern = rEx_a
    regEx_a.IgnoreCase = False
    regEx_a.Global = False

    Dim rEx_b, regEx_b
    rEx_b = "WOW\d{4,}Node"
    Set regEx_b = New RegExp
    regEx_b.Pattern = rEx_b
    regEx_b.IgnoreCase = True
    regEx_b.Global = False

    Dim RetStr: RetStr = Split(regEx_a.Replace(strKeyPath, "$1◆$2◆$3"), "◆")

    Dim a, b, c
    a = RetStr(0) : b = RetStr(1) : c = RetStr(2)

    IF (regEx_b.Replace(b, "") <> "") Then
        b = StrNode & "\" & b
    Else
        b = StrNode
    End If

    RetStr = a & b & c

    SetRightRegNodePath = RetStr
End Function


' ***********************************************
' * 一个正则函数
' ***********************************************
Function RegExpTest(patrn, Str, ReStr)
    Dim regEx, Match, Matches   ' 创建变量
    Set regEx = New RegExp      ' 创建正则表达式
    regEx.Pattern = patrn       ' 设置模式
    regEx.IgnoreCase = True     ' 设置是否区分大小写
    regEx.Global = True         ' 设置全程匹配

    If (regEx.Test(Str) = True) Then
        If ReStr = "" Then
            Set Matches = regEx.Execute(Str)    ' 执行搜索
            For Each Match in Matches           ' 循环遍历 Matches 集合
                ' RetStr = RetStr & "偏移量 "
                ' RetStr = RetStr & Match.FirstIndex & "。" &vbCrLf& "字符：'"
                ' RetStr = RetStr & Match.Value & "'。" & vbCrLf
                RetStr = RetStr & Match.Value
            Next
        Else
            RetStr = regEx.Replace(Str, ReStr)
        End If
    Else
        RetStr = False
    End If

    RegExpTest = RetStr
End Function
