function cylinder2plane(CoilPath, R, direction)
% cylinder2plane 将柱面坐标展开并输出为txt文件
% -------------------------------------------------
% 输入:
%   CoilPath : 结构体，包含 Positive / Negative 两个字段，每个字段内为 Cell 数组
%   R        : 柱面半径 (m)
%
% 输出:
%   每一组等值线（一个 Cell）生成一个 txt 文件，命名格式：
%       Positive_001.txt, Negative_002.txt, ...

outputFolder = fullfile('Result', 'contourc_Plane_mm', direction);
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% === 获取正负组别 ===
groups = fieldnames(CoilPath);

for g = 1:numel(groups)
    grp = groups{g}; % 'Positive' 或 'Negative'
    curves = CoilPath.(grp);
    M = numel(curves);

    for j = 1:M
        data = curves{j};
        if isempty(data)
            continue;
        end

        % === 提取 XYZ 并展开 ===
        X = data(:,1);
        Y = data(:,2);
        Z = data(:,3);

        phi = atan2(Y, X);   % [-π, π]
        phi = unwrap(phi);    % 避免角度跳变
        U = R .* phi;         % 弧长展开,mm
        Y = R * ones(size(U));
        V = Z;

        outdata = [U, Y, V] * 1000;

        % === 输出文件 ===
        fname = sprintf('%s_%03d.txt', grp, j);
        fpath = fullfile(outputFolder, fname);

        fid = fopen(fpath, 'w');
        % fprintf(fid, '%% %s 等值线 %d\n', grp, j);
        % fprintf(fid, '%% Columns: U(m)\tV(m)\n');
        fprintf(fid, '%12.8f\t%12.8f\t%12.8f\n', outdata');
        fclose(fid);

        fprintf('已输出: %s\n', fpath);
    end
end

fprintf('✅ 所有等值线已展开至文件夹: %s\n', outputFolder);
end
