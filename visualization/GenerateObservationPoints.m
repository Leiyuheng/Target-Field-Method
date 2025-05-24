function obsPoints = GenerateObservationPoints(params)
% 功能：生成需要计算磁场的点，选择根据可视化图来选取一部分点，而不是整体计算，提高效率
% 输入：
%   params - 结构体，用户自定义参数，建议参考 InitParameters.m 结构
%   obsPoints - 结构体，包含所有生成的观测点（列向量形式）

obsPoints = struct();
r = params.b; % 控制绘图平面大小

% bore_xg 在phi=0，x=b处
z_vec = params.z;
x_vec = r * ones(size(z_vec));
y_vec = zeros(size(z_vec));
obsPoints.bore_xg = [x_vec; y_vec; z_vec]';% [N x 3]

% bore_yg 在phi=90，y=b处
z_vec = params.z;
x_vec = zeros(size(z_vec));
y_vec = r * ones(size(z_vec));
obsPoints.bore_yg = [x_vec; y_vec; z_vec]';% [N x 3]

% 圆柱横截面误差观察点
[R, Phi] = meshgrid(params.r, params.phi);
X = R .* cos(Phi);
Y = R .* sin(Phi);
Z = zeros(size(X));
obsPoints.transverse = [X(:), Y(:), Z(:)];% [N x 3]

% 球体误差观察
% 创建立方体网格，覆盖 [-b, b] 立方体区域
b = params.b;
N = params.b_num;
x = linspace(-b, b, N);
y = linspace(-b, b, N);
z = linspace(-b, b, N);
[X, Y, Z] = meshgrid(x, y, z);

% 生成掩码：筛选满足球体方程的点
mask = (X.^2 + Y.^2 + Z.^2) <= b^2;

% 提取球体内部点
X_valid = X(mask);
Y_valid = Y(mask);
Z_valid = Z(mask);
obsPoints.sphericalVolume = [X_valid(:), Y_valid(:), Z_valid(:)]; % N x 3


% 圆柱纵截面误差观察
% 生成 rectangularYZ 面 (x=0, YZ平面)
y_vec = linspace(-r, r, params.z_num);
z_vec = linspace(-params.d, params.d, params.z_num);
[Y_grid, Z_grid] = meshgrid(y_vec, z_vec);
X_grid = zeros(size(Y_grid));

obsPoints.rectYZ = [X_grid(:), Y_grid(:), Z_grid(:)];

% 生成 rectangularXZ 面 (y=0, XZ平面)
x_vec = linspace(-r, r, params.z_num);
z_vec = linspace(-params.d, params.d, params.z_num);
[X_grid, Z_grid] = meshgrid(x_vec, z_vec);
Y_grid = zeros(size(X_grid));

obsPoints.rectXZ = [X_grid(:), Y_grid(:), Z_grid(:)];



%% 可视化

figure('Color', 'w','Position',[500,500,600,600]);
hold on;
axis equal;
grid on;
xlabel('X [m]');
ylabel('Y [m]');
zlabel('Z [m]');
title('观测点分布与辅助圆柱');

% 绘制辅助圆柱
r_cyl = params.a;
z_cyl = linspace(-params.d*2, params.d*2, 50);
theta_cyl = linspace(0, 2*pi, 100);
[Theta_cyl, Z_cyl] = meshgrid(theta_cyl, z_cyl);
X_cyl = r_cyl * cos(Theta_cyl);
Y_cyl = r_cyl * sin(Theta_cyl);
surf(X_cyl, Y_cyl, Z_cyl, 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'FaceColor', [0.5 0.5 0.5]);

% bore_xg
scatter3(obsPoints.bore_xg(:,1), obsPoints.bore_xg(:,2), obsPoints.bore_xg(:,3), 20, 'r', 'filled');

% bore_yg
scatter3(obsPoints.bore_yg(:,1), obsPoints.bore_yg(:,2), obsPoints.bore_yg(:,3), 20, 'k', 'filled');

% transverse
scatter3(obsPoints.transverse(:,1), obsPoints.transverse(:,2), obsPoints.transverse(:,3), ...
    10, 'b', 'filled');

% sphericalVolume
scatter3(obsPoints.sphericalVolume(:,1), obsPoints.sphericalVolume(:,2), obsPoints.sphericalVolume(:,3), ...
    8, 'g', 'filled');

% rectYZ
scatter3(obsPoints.rectYZ(:,1), obsPoints.rectYZ(:,2), obsPoints.rectYZ(:,3), 10, 'm', 'filled');

% rectXZ
scatter3(obsPoints.rectXZ(:,1), obsPoints.rectXZ(:,2), obsPoints.rectXZ(:,3), 10, 'c', 'filled');


% 图例与视图设置
legend({'辅助圆柱', 'bore\_xg 线', 'bore\_yg 线', ...
        'transverse 圆盘点', 'sphericalVolume 球体内部点', ...
        'rectYZ (x=0)', 'rectXZ (y=0)'}, ...
       'Location', 'northeast');
view(3); % 3D视角
rotate3d on;

hold off;


end
