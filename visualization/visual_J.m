function visual_J()
% 可视化表面电流的矢量图

% 计算表面电流
params = InitParameters();                    % 先按你的参数结构体赋值
sc = Compute_SurfaceCurrent(params);% sc = surfaceCurrent

% 网格准备（phi 展平成横坐标, z 作为纵坐标）
[PhiGrid, ZGrid] = meshgrid(sc.phi, sc.z);   % 与 Compute_SurfaceCurrent 中一致
Jphi = sc.Jphi_z;                            % 取 x-梯度
Jz   = sc.Jz_z;

% 归一化箭头长度（可选）
Jmag = hypot(Jphi, Jz);
scaleFactor = max(Jmag(:));
U = Jphi ./ scaleFactor;   % 水平方向箭头
V = Jz   ./ scaleFactor;   % 竖直方向箭头

% 绘制矢量场
figure('Name','x-梯度表面电流矢量图','Position',[200 200 800 600]);
quiver(PhiGrid, ZGrid, U, V, 0.8, 'k', 'LineWidth', 1); hold on;
xlabel('\phi (rad)'); ylabel('z (m)');
title('Surface Current Density  \bfJ_\phi  &  J_z  (x-Gradient)');
axis tight; grid on;

% 用颜色映射电流强度
surfHandle = pcolor(PhiGrid, ZGrid, Jmag);   % 背景用强度上色
set(surfHandle, 'EdgeColor', 'none');
shading interp; colormap parula; colorbar;
uistack(surfHandle, 'bottom');               % 把着色层放到最底层
