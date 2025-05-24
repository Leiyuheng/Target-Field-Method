function Visualize_B_Field_Components(B_cal, obsPoints, coilTag, params)
% DEMO 可视化 B_cal 中所有区域的 Bx/By/Bz 分量（含 rectYZ & rectXZ 联合展示）
%
% 输入：
%   B_cal - 结构体，包含 B_bore, B_transverse, B_spherical, B_rectYZ, B_rectXZ
%   obsPoints - 结构体，包含 bore, transverse, sphericalVolume, rectYZ, rectXZ
%   coilTag - 字符串 'x','y','z'

fields = {'bore_xg', 'bore_yg', 'transverse', 'sphericalVolume'};
B_fields = {'B_bore_xg', 'B_bore_yg', 'B_transverse', 'B_spherical'};

for i = 1:length(fields)
    obs = obsPoints.(fields{i});
    B = B_cal.(B_fields{i});
    if (coilTag == 'y' && strcmp(fields{i}, 'bore_xg')) ...
     || ((coilTag == 'x' || coilTag == 'z') && strcmp(fields{i}, 'bore_yg'))
        continue;
    end
    figure('Color','w','Name',[upper(coilTag), ' 方向 - ', fields{i}, ' 区域磁场分量 DEMO'],'Position',[100,100,1200,400]);

    switch fields{i}
        case 'bore_xg'
            [z_sorted, idx] = sort(obs(:,3));
            B_sorted = B(idx, :);

            subplot(1,3,1);
            plot(z_sorted, B_sorted(:,1), 'r.-');
            xlabel('Z [m]'); ylabel('B_x [T]');
            title('B_x along bore'); grid on;

            subplot(1,3,2);
            plot(z_sorted, B_sorted(:,2), 'g.-');
            xlabel('Z [m]'); ylabel('B_y [T]');
            title('B_y along bore'); grid on;

            subplot(1,3,3);
            plot(z_sorted, B_sorted(:,3), 'b.-');
            xlabel('Z [m]'); ylabel('B_z [T]');
            title('B_z along bore'); grid on;

        case 'bore_yg'
            if coilTag == 'x'
                continue;
            end
            [z_sorted, idx] = sort(obs(:,3));
            B_sorted = B(idx, :);

            subplot(1,3,1);
            plot(z_sorted, B_sorted(:,1), 'r.-');
            xlabel('Z [m]'); ylabel('B_x [T]');
            title('B_x along bore'); grid on;

            subplot(1,3,2);
            plot(z_sorted, B_sorted(:,2), 'g.-');
            xlabel('Z [m]'); ylabel('B_y [T]');
            title('B_y along bore'); grid on;

            subplot(1,3,3);
            plot(z_sorted, B_sorted(:,3), 'b.-');
            xlabel('Z [m]'); ylabel('B_z [T]');
            title('B_z along bore'); grid on;

        case 'transverse'
            subplot(1,3,1);
            scatter(obs(:,1), obs(:,2), 20, B(:,1), 'filled');
            xlabel('X [m]'); ylabel('Y [m]'); title('B_x in transverse');
            colorbar; axis equal; grid on;

            subplot(1,3,2);
            scatter(obs(:,1), obs(:,2), 20, B(:,2), 'filled');
            xlabel('X [m]'); ylabel('Y [m]'); title('B_y in transverse');
            colorbar; axis equal; grid on;

            subplot(1,3,3);
            scatter(obs(:,1), obs(:,2), 20, B(:,3), 'filled');
            xlabel('X [m]'); ylabel('Y [m]'); title('B_z in transverse');
            colorbar; axis equal; grid on;

        case 'sphericalVolume'
            subplot(1,3,1);
            scatter3(obs(:,1), obs(:,2), obs(:,3), 20, B(:,1), 'filled');
            xlabel('X [m]'); ylabel('Y [m]'); zlabel('Z [m]');
            title('B_x in spherical'); colorbar; axis equal; grid on;

            subplot(1,3,2);
            scatter3(obs(:,1), obs(:,2), obs(:,3), 20, B(:,2), 'filled');
            xlabel('X [m]'); ylabel('Y [m]'); zlabel('Z [m]');
            title('B_y in spherical'); colorbar; axis equal; grid on;

            subplot(1,3,3);
            scatter3(obs(:,1), obs(:,2), obs(:,3), 20, B(:,3), 'filled');
            xlabel('X [m]'); ylabel('Y [m]'); zlabel('Z [m]');
            title('B_z in spherical'); colorbar; axis equal; grid on;
    end
end

%%  叠加展示 rectYZ & rectXZ (在同一 3D 图)
if isfield(obsPoints, 'rectYZ') && isfield(obsPoints, 'rectXZ') && ...
   isfield(B_cal, 'B_rectYZ') && isfield(B_cal, 'B_rectXZ')

    Visualize_RectPlanes_Overlay_3D(B_cal, obsPoints, 1, coilTag, [], params); % x分量
    % Visualize_RectPlanes_Overlay_3D(B_cal, obsPoints, 2, coilTag, [], params); % y分量
    % Visualize_RectPlanes_Overlay_3D(B_cal, obsPoints, 3, coilTag, [], params); % z分量

    disp(['[完成] ', upper(coilTag), ' 方向 DEMO 磁场分量 rectYZ & rectXZ 3D叠加展示完成']);
end

disp(['[完成] ', upper(coilTag), ' 方向 DEMO 磁场分量检查绘图全部完成 (自动适应所有区域)']);
end
