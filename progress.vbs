' progress.vbs
' Arguments: URL, OutputFile, SentinelFile
Option Explicit

Dim objShell, objFSO, WshExec, stdErr
Dim sURL, sOutputFile, sSentinelFile, sProgressKey
Dim sCmd, sLine, sProgress, sBuffer
Dim re, matches, lastProgress

sURL = WScript.Arguments.Item(0)
sOutputFile = WScript.Arguments.Item(1)
sSentinelFile = WScript.Arguments.Item(2)
sProgressKey = "HKCU\Software\MuhRO\InstallProgress"
lastProgress = ""

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

objShell.RegWrite sProgressKey, "0", "REG_SZ"

Dim sProgressFile, sExitCodeFile
sProgressFile = objFSO.BuildPath(objFSO.GetSpecialFolder(2), "curl_progress.txt")
sExitCodeFile = objFSO.BuildPath(objFSO.GetSpecialFolder(2), "curl_exitcode.txt")

' Cleanup old temp files if they exist
If objFSO.FileExists(sProgressFile) Then objFSO.DeleteFile sProgressFile, True
If objFSO.FileExists(sExitCodeFile) Then objFSO.DeleteFile sExitCodeFile, True

' The command to be executed by cmd.exe
Dim sCurlCmd
sCurlCmd = "curl.exe -# -L --fail -o """ & sOutputFile & """ """ & sURL & """ 2> """ & sProgressFile & """"
sCmd = "cmd.exe /C """ & sCurlCmd & " & echo %errorlevel% > """ & sExitCodeFile & """"""

' Run the command hidden and do not wait for it to complete
objShell.Run sCmd, 0, false

sBuffer = ""
Do
    If objFSO.FileExists(sProgressFile) Then
        Dim objFile, sFileContent
        On Error Resume Next
        Set objFile = objFSO.OpenTextFile(sProgressFile, 1) ' ForReading
        If Err.Number = 0 Then
            If Not objFile.AtEndOfStream Then
                sFileContent = objFile.ReadAll()
                sBuffer = sFileContent ' Use the file content as the buffer
            End If
            objFile.Close
        End If
        On Error GoTo 0
    End If
    
    If sBuffer <> "" Then
        Dim iPos
        iPos = InStrRev(sBuffer, vbCr) ' Find the last carriage return
        If iPos > 0 Then
            Dim iPosStart
            iPosStart = InStrRev(sBuffer, vbCr, iPos - 1)
            If iPosStart = 0 Then iPosStart = 1

            sLine = Mid(sBuffer, iPosStart, iPos - iPosStart) ' Isolate the last full line
            
            Set re = new RegExp
            re.Pattern = "(\d[\d\.]*)\s*%"
            re.Global = False
            Set matches = re.Execute(sLine)

            If matches.Count > 0 Then
                sProgress = matches(0).SubMatches(0)
                If sProgress <> lastProgress Then
                    objShell.RegWrite sProgressKey, sProgress, "REG_SZ"
                    lastProgress = sProgress
                End If
            End If
        End If
    End If

    ' Check if the exit code file has been created, which means the process is done
    If objFSO.FileExists(sExitCodeFile) Then Exit Do

    WScript.Sleep 500 ' Pause briefly to prevent high CPU usage
Loop

' Read the exit code
Dim sExitCode, objExitFile
Set objExitFile = objFSO.OpenTextFile(sExitCodeFile, 1)
sExitCode = objExitFile.ReadLine()
objExitFile.Close

' Final check for exit code and create sentinel file
If Trim(sExitCode) = "0" Then
    objShell.RegWrite sProgressKey, "100", "REG_SZ"
    Dim objFileSentinel
    Set objFileSentinel = objFSO.CreateTextFile(sSentinelFile, True)
    objFileSentinel.WriteLine "done"
    objFileSentinel.Close
End If

' Cleanup
objFSO.DeleteFile sProgressFile, True
objFSO.DeleteFile sExitCodeFile, True