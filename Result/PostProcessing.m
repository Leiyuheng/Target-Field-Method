% =====================================================
% 根据旭东哥要求，方便Solidworks操作，删除飞线
% 在源代码中添加RAW数据输出后在此进行连接操作
% 只需对相同direction的线圈进行组间首尾判断连接即可
%=====================================================

clc
clear
close all

rootFolder = 'RAWdata';
subFolders = {'x','y','z'};
R_map = struct('x',0.095,'y',0.086,'z',0.077);   % [m]
threshold = 0.015;                            % [m]

figure('Color','w','Position',[100 100 1200 800]);
tiledlayout(1,3,'Padding','compact','TileSpacing','compact');

for s = 1:numel(subFolders)
    folder = subFolders{s};
    folderPath = fullfile(rootFolder, folder);
    fprintf('\n=== 处理方向: %s (R = %.3f m) ===\n', folder, R_map.(folder));
    R_cylinder = R_map.(folder);

    % ===== 读取四个文件 =====
    F = struct();
    names = {'Positive1','Negative1','Positive2','Negative2'};
    for i = 1:numel(names)
        filePath = fullfile(folderPath, sprintf('%s_%s.bin', folder, names{i}));
        if ~isfile(filePath)
            error('文件不存在: %s', filePath);
        end
        fid = fopen(filePath,'rb');
        F.(names{i}) = fread(fid,[2,inf],'double')';   % [phi,z], 单位: [rad, m]
        fclose(fid);
    end

    % ===== 建立连接规则 =====
    switch folder
        case {'x','y'}
            pairList = {'Positive1','Negative2'; 'Positive2','Negative1'};
        case 'z'
            pairList = {'Positive1','Negative1'; 'Positive2','Negative2'};
    end

    mergedData = cell(size(pairList,1),1);

    % ===== 执行连接 =====
    for k = 1:size(pairList,1)
        A = F.(pairList{k,1});
        B = F.(pairList{k,2});
        d1 = calcCylDist(A(end,:), B(1,:), R_cylinder);
        d2 = calcCylDist(B(end,:), A(1,:), R_cylinder);

        if d1 <= d2
            merged = [A; B];
            d_min = d1;
        else
            merged = [B; A];
            d_min = d2;
        end

        if d_min > threshold
            warning('%s_%s 与 %s_%s 距离 %.4f 超过阈值 %.4f (m)', ...
                folder, pairList{k,1}, folder, pairList{k,2}, d_min, threshold);
        end

        mergedData{k} = merged;
        fprintf('✅ 合并: %s_%s ↔ %s_%s (%.4f m)\n', ...
            folder, pairList{k,1}, folder, pairList{k,2}, d_min);
    end

    % ===== 转换为XYZ并输出 =====
    outputFolder = fullfile(rootFolder, [folder '_merged' '_mm']);
    if ~exist(outputFolder,'dir')
        mkdir(outputFolder);
    end

    nexttile;
    hold on; grid on; axis equal;
    title(sprintf('%s 方向 (R=%.3fm)', folder, R_cylinder));
    xlabel('X [mm]'); ylabel('Y [mm]'); zlabel('Z [mm]');

    colors = lines(numel(mergedData));
    for k = 1:numel(mergedData)
        % =========================这部分是转为柱面的XYZ======================
        phi = mergedData{k}(:,1);
        z   = mergedData{k}(:,2);
        R   = R_cylinder;

        x = R * cos(phi);
        y = R * sin(phi);
        XYZ = [x, y, z]*1000;
        % ====================================================================

        % ===================这部分是转为平面的XYZ，后续WRAP==================
        % phi = unwrap(mergedData{k}(:,1));  % [rad]
        % z   = mergedData{k}(:,2);  % [m]
        % R   = R_cylinder;
        % 
        % % === 柱面展开为平面坐标 ===
        % x_flat = R * phi;     % 周向弧长方向
        % y_flat = -ones(size(phi))*R; % 保留Y列为-R
        % z_flat = z;           % 轴向方向
        % 
        % XYZ = [x_flat, y_flat, z_flat]*1000;
        % ====================================================================

        % 输出txt文件
        outFile = fullfile(outputFolder, sprintf('%s_merged_%d.txt', folder, k));
        fid = fopen(outFile,'w');
        fprintf(fid, '%.8f\t%.8f\t%.8f\n', XYZ');
        fclose(fid);

        fprintf('📄 输出文件: %s (%d 点)\n', outFile, size(XYZ,1));

        % 绘制曲线
        plot3(XYZ(:,1), XYZ(:,2), XYZ(:,3), 'LineWidth', 1.5, 'Color', colors(k,:));
    end
end

sgtitle('各方向 Coil Path 合并后 3D 可视化', 'FontWeight','bold');
fprintf('\n🎯 全部方向合并完成并绘制 3D 曲线图。\n');

% =====================================================
% 辅助函数：计算圆柱面上两点距离 (单位: m)
% =====================================================
function d = calcCylDist(p1, p2, R)
    dphi = abs(p1(1) - p2(1));
    dphi = min(dphi, 2*pi - dphi);   % 处理角度周期性
    dz = abs(p1(2) - p2(2));
    d = sqrt((R * dphi)^2 + dz^2);   % [m]
end
