function save_all_figures()
% 自动将所有图窗保存为 PNG 图像，保存在 ./pic/ 文件夹内

% 创建保存文件夹（若不存在）
outputFolder = 'Pics';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

figHandles = findall(0, 'Type', 'figure');  % 获取所有图窗句柄

for i = 1:length(figHandles)
    fig = figHandles(i);

    % 获取图窗名称
    figName = get(fig, 'Name');

    % 生成文件名
    if isempty(figName)
        fileBase = sprintf('Figure_%d', i);
    else
        fileBase = regexprep(figName, '[\/:*?"<>|]', '_');  % 清洗非法字符
    end

    % 拼接完整路径
    filename = fullfile(outputFolder, [fileBase, '.png']);

    % 导出整个图窗（包括 subplot）
    exportgraphics(fig, filename, 'Resolution', 300);
end

disp('[完成] 所有 subplot 图像已导出至 ./pic 文件夹。');
