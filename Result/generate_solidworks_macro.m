%% generate_import_macro.m
% 生成可在 SolidWorks 中运行的 .vba 宏，批量导入 folderPath 下所有 .txt (X Y Z mm, tab delimited)
% 保存为 ANSI 编码 (windows-1252)
% 使用方法：修改 direction 或 folderPath，然后运行此脚本，得到 import_x_curves.vba

direction = 'x';  % 修改为你的方向标识
folderPath = fullfile(pwd, 'contourc_Plane_mm', direction);  % 要读取的 txt 文件夹
outputFile = fullfile(pwd, 'contourc_Plane_mm', sprintf('import_%s_curves.vba', direction));  % 输出的 vba 文件

if ~isfolder(folderPath)
    error('指定的文件夹不存在：%s', folderPath);
end

fprintf('目标文件夹: %s\n', folderPath);
fprintf('生成宏: %s\n', outputFile);

% ===== VBA lines =====
lines = {
'Option Explicit'
'Dim swApp As Object'
'Dim Part As Object'
'Dim boolstatus As Boolean'
'Dim longstatus As Long, longwarnings As Long'
'Dim fso As Object, folder As Object, file As Object'
'Dim folderPath As String'
''
'Sub main()'
'    On Error GoTo ErrHandler'
'    Set swApp = Application.SldWorks'
'    Set Part = swApp.ActiveDoc'
'    If Part Is Nothing Then'
'        '' Uncomment next lines to create a new part automatically if none is open'
'        '' Dim templatePath As String'
'        '' templatePath = ""''  '' <-- optional: full path to part template'
'        '' Set Part = swApp.NewDocument(templatePath, 0, 0, 0)'
'    End If'
'    folderPath = "<FOLDER_PATH>"'
'    Set fso = CreateObject("Scripting.FileSystemObject")'
'    Set folder = fso.GetFolder(folderPath)'
'    For Each file In folder.Files'
'        If LCase(Right(file.Name, 4)) = ".txt" Then'
'            Call ImportCurveFromFile(file.Path, Part)'
'        End If'
'    Next'
'    Part.ViewZoomtofit2'
'    MsgBox "✅ 所有曲线已成功导入！"'
'    Exit Sub'
'ErrHandler:'
'    MsgBox "Error: " & Err.Number & " - " & Err.Description'
'End Sub'
''
'Sub ImportCurveFromFile(filePath As String, Part As Object)'
'    Dim f As Integer'
'    Dim x As Double, y As Double, z As Double'
'    Dim line As String'
'    Dim vals() As String'
'    Dim s As String'
'    f = FreeFile'
'    Open filePath For Input As #f'
'    Part.InsertCurveFileBegin'
'    Do Until EOF(f)'
'        Line Input #f, line'
'        If Len(Trim(line)) = 0 Then'
'            GoTo ContinueLoop'
'        End If'
'        '' 支持 tab 或多个空白分隔'
'        If InStr(line, vbTab) > 0 Then'
'            vals = Split(line, vbTab)'
'        Else'
'            s = Trim(line)'
'            s = Replace(s, ",", ".") '' 如果小数用逗号，先替换为点'
'            vals = Split(s)'
'        End If'
'        If UBound(vals) >= 2 Then'
'            On Error Resume Next'
'            x = CDbl(Trim(vals(0))) / 1000'
'            y = CDbl(Trim(vals(1))) / 1000'
'            z = CDbl(Trim(vals(2))) / 1000'
'            On Error GoTo 0'
'            Part.InsertCurveFilePoint x, y, z'
'        End If'
'ContinueLoop:'
'    Loop'
'    Close #f'
'    Part.InsertCurveFileEnd'
'End Sub'
};

% replace placeholder
for i = 1:numel(lines)
    lines{i} = strrep(lines{i}, '<FOLDER_PATH>', folderPath);
end

% write file using ANSI (windows-1252)
fid = fopen(outputFile, 'w', 'n', 'windows-1252');
if fid == -1
    error('无法创建输出文件：%s', outputFile);
end
for i = 1:numel(lines)
    fprintf(fid, '%s\r\n', lines{i});
end
fclose(fid);

fprintf('已生成 vba 宏：%s\n请在 SolidWorks 中运行：Tools → Macro → Run → 选择该 .vba 文件\n', outputFile);
