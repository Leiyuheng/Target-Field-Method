% 构建螺旋管验证电感计算公式
clc
clear
close all

%% 1. 参数设置
R       = 0.05;      % 螺线管半径
pitch   = 0.003;      % 每圈间距
Nturns  = 10;         % 总圈数
ptsPerTurn = 200;    % 每圈离散点数
wireDia = 2e-3;      % 导线直径 2 mm
wireRadius = wireDia/2;

%% 2. 生成螺线圈路径
theta_max = 2*pi*Nturns;
theta = linspace(0, theta_max, Nturns*ptsPerTurn+1)';  % +1 保证首尾重合
x = R*cos(theta);
y = R*sin(theta);
z = (pitch/(2*pi)) * theta;
coilPath = [x, y, z];

%% 3. 可视化路径（可选）
figure;
plot3(coilPath(:,1), coilPath(:,2), coilPath(:,3), '-b', 'LineWidth', 1);
axis equal; grid on;
xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
title('圆柱螺线圈路径示意');

%% 4. 调用自感计算函数
[L, totalLen] = computeCoilInductance(coilPath, wireRadius);

%% 5. 输出结果
fprintf('螺线圈总长度 = %.3f m\n', totalLen);
fprintf('螺线圈自感 L = %.6e H\n', L);
