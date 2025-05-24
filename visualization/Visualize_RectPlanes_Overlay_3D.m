function Visualize_RectPlanes_Overlay_3D(B_cal, obsPoints, componentIdx, coilTag, cbarRange, params)
% 在 3D 中叠加显示 rectYZ 和 rectXZ 两个平面磁场分布，并设置 colorbar 范围
% 输入：
%   B_cal - 包含 B_rectYZ, B_rectXZ
%   obsPoints - 包含 rectYZ, rectXZ
%   componentIdx - 1(Bx), 2(By), 3(Bz)
%   coilTag - 'x','y','z'
%   cbarRange - [min max]，可选

% rectYZ
obs_YZ = obsPoints.rectYZ;
B_YZ = B_cal.B_rectYZ(:, componentIdx);

% rectXZ
obs_XZ = obsPoints.rectXZ;
B_XZ = B_cal.B_rectXZ(:, componentIdx);

% 转换为网格 (YZ)
Y_YZ = unique(obs_YZ(:,2));
Z_YZ = unique(obs_YZ(:,3));
[Y_grid_YZ, Z_grid_YZ] = meshgrid(Y_YZ, Z_YZ);
B_YZ_grid = reshape(B_YZ, length(Z_YZ), length(Y_YZ));
X_grid_YZ = zeros(size(Y_grid_YZ));

% 转换为网格 (XZ)
X_XZ = unique(obs_XZ(:,1));
Z_XZ = unique(obs_XZ(:,3));
[X_grid_XZ, Z_grid_XZ] = meshgrid(X_XZ, Z_XZ);
B_XZ_grid = reshape(B_XZ, length(Z_XZ), length(X_XZ));
Y_grid_XZ = zeros(size(X_grid_XZ));

% 绘图
figure('Color','w','Name',[upper(coilTag), ' 方向 - rectYZ & rectXZ 磁场叠加展示']);
hold on;
grid on; axis equal;
xlabel('X [m]'); ylabel('Y [m]'); zlabel('Z [m]');

% 绘制辅助圆柱
r_cyl = params.a;
z_cyl = linspace(-params.d, params.d, 50);
theta_cyl = linspace(0, 2*pi, 100);
[Theta_cyl, Z_cyl] = meshgrid(theta_cyl, z_cyl);
X_cyl = r_cyl * cos(Theta_cyl);
Y_cyl = r_cyl * sin(Theta_cyl);
surf(X_cyl, Y_cyl, Z_cyl, 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'FaceColor', [0.5 0.5 0.5]);

% rectYZ 面 (x = 0)
surf(X_grid_YZ, Y_grid_YZ, Z_grid_YZ, B_YZ_grid, 'EdgeColor', 'none', 'FaceAlpha', 0.8);

% rectXZ 面 (y = 0)
surf(X_grid_XZ, Y_grid_XZ, Z_grid_XZ, B_XZ_grid, 'EdgeColor', 'none', 'FaceAlpha', 0.8);

char_component = ['x','y','z'];
title(sprintf('B_%c 分量 - 横截面展示 (%s 梯度线圈场)', char_component(componentIdx), upper(coilTag)));

view(3);
axis tight;
col = colorbar;
ylabel(col, '磁场 [T]');

% 设置 colorbar 范围
if nargin >= 5 && ~isempty(cbarRange)
    clim(cbarRange);
else
    % 自动基于两个面数据计算范围
    combinedMin = min([B_YZ; B_XZ]);
    combinedMax = max([B_YZ; B_XZ]);
    clim([combinedMin combinedMax]);
end

end
