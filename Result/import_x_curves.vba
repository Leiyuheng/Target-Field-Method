Option Explicit
Dim swApp As Object
Dim Part As Object
Dim boolstatus As Boolean
Dim longstatus As Long, longwarnings As Long
Dim fso As Object, folder As Object, file As Object
Dim folderPath As String

Sub main()
    On Error GoTo ErrHandler
    Set swApp = Application.SldWorks
    Set Part = swApp.ActiveDoc
    If Part Is Nothing Then
        ' Uncomment next lines to create a new part automatically if none is open
        ' Dim templatePath As String
        ' templatePath = ""'  ' <-- optional: full path to part template
        ' Set Part = swApp.NewDocument(templatePath, 0, 0, 0)
    End If
    folderPath = "E:\Learning_material\\MRI\TFM_LYH\Result\contourc_Plane_mm\x"
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set folder = fso.GetFolder(folderPath)
    For Each file In folder.Files
        If LCase(Right(file.Name, 4)) = ".txt" Then
            Call ImportCurveFromFile(file.Path, Part)
        End If
    Next
    Part.ViewZoomtofit2
    MsgBox "导入成功"
    Exit Sub
ErrHandler:
    MsgBox "Error: " & Err.Number & " - " & Err.Description
End Sub

Sub ImportCurveFromFile(filePath As String, Part As Object)
    Dim f As Integer
    Dim x As Double, y As Double, z As Double
    Dim line As String
    Dim vals() As String
    Dim s As String
    f = FreeFile
    Open filePath For Input As #f
    Part.InsertCurveFileBegin
    Do Until EOF(f)
        Line Input #f, line
        If Len(Trim(line)) = 0 Then
            GoTo ContinueLoop
        End If
        '  tab 
        If InStr(line, vbTab) > 0 Then
            vals = Split(line, vbTab)
        Else
            s = Trim(line)
            s = Replace(s, ",", ".") ' 
            vals = Split(s)
        End If
        If UBound(vals) >= 2 Then
            On Error Resume Next
            x = CDbl(Trim(vals(0))) / 1000
            y = CDbl(Trim(vals(1))) / 1000
            z = CDbl(Trim(vals(2))) / 1000
            On Error GoTo 0
            Part.InsertCurveFilePoint x, y, z
        End If
ContinueLoop:
    Loop
    Close #f
    Part.InsertCurveFileEnd
End Sub
