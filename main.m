clc
clear
close all

addpath(strcat(pwd,'\','subfunctions'));
addpath(strcat(pwd,'\','visualization'));
%% 计算线圈路径部分

params = InitParameters();
% 为方便调试，在本程序中添加参数微调
ax = 0.096;
ay = 0.087;
az = 0.078; % 线圈半径
Nx = 8;
Ny = Nx;
Nz = 11; % 线圈匝数
dx = 0.136;
dy = 0.138;
dz = 0.1; % 线圈截止长度，一般会超出这个值，通过截断阶数与d来控制线圈总长度
hx = 0.07;
hy = hx;
hz = 0.05; % 高斯滤波强度，控制线圈形状，最直接影响最小间距
params.n_tr = 20;  % x/y方向梯度场 阶数n 需要偶数
params.n_ln = 10;  % z方向梯度场 阶数n 需要偶数


% 绘制 x 方向的绕线路径柱面图
params.a = ax; % x线圈圆柱半径
params.num_levels = Nx; % x 线圈匝数
params.d = dx; % x线圈梯度截止长度 
params.h = hx;
surfaceCurrent = Compute_SurfaceCurrent(params);
streamFunction = Compute_StreamFunction(surfaceCurrent, params);
coilPaths_xg = Compute_CoilPaths(streamFunction, surfaceCurrent, params, 'x');

% 绘制 y 方向
params.a = ay; % y线圈圆柱半径
params.num_levels = Ny; % y线圈匝数
params.d = dy; % y线圈梯度截止长度 
params.h = hy;
surfaceCurrent = Compute_SurfaceCurrent(params);
streamFunction = Compute_StreamFunction(surfaceCurrent, params);
coilPaths_yg = Compute_CoilPaths(streamFunction, surfaceCurrent, params, 'y');

% 绘制 z 方向
params.a = az; % z线圈圆柱半径
params.num_levels = Nz; % z线圈匝数
params.d = dz; % z线圈梯度截止长度 
params.h = hz;
surfaceCurrent = Compute_SurfaceCurrent(params);
streamFunction = Compute_StreamFunction(surfaceCurrent, params);
coilPaths_zg = Compute_CoilPaths(streamFunction, surfaceCurrent, params, 'z');

% 将等值线的平面输出输出，用于包覆操作
cylinder2plane(coilPaths_xg, ax, 'x');
cylinder2plane(coilPaths_yg, ay, 'y');
cylinder2plane(coilPaths_zg, az, 'z');

visual_coilpath(coilPaths_xg, coilPaths_yg, coilPaths_zg);
%% 可实现线圈转换
params.a = ax; % x线圈圆柱半径
params.num_levels = Nx; % x y线圈匝数
params.d = dx; % x线圈梯度截止长度 
params.h = hx;
CoilPath_Achievable_xg = Achievable_CoilPath_Archimedes(coilPaths_xg, params, 'x', 0, 0);

params.a = ay; % y线圈圆柱半径
params.num_levels = Ny; % y线圈匝数
params.d = dy; % y线圈梯度截止长度 
params.h = hy;
CoilPath_Achievable_yg = Achievable_CoilPath_Archimedes(coilPaths_yg, params, 'y', 0, 0);

params.a = az; % z线圈圆柱半径
params.num_levels = Nz; % z线圈匝数
params.d = dz; % z线圈梯度截止长度 
params.h = hz;
CoilPath_Achievable_zg = Achievable_CoilPath_Archimedes(coilPaths_zg, params, 'z', 0, 0);

% 输出到TXT
datax = unique(CoilPath_Achievable_xg.Serial{1},'stable','rows'); 
datay = unique(CoilPath_Achievable_yg.Serial{1},'stable','rows');
dataz = unique(CoilPath_Achievable_zg.Serial{1},'stable','rows'); 

xfname = 'CoilPath_Achievable_xg.txt';
yfname = 'CoilPath_Achievable_yg.txt';
zfname = 'CoilPath_Achievable_zg.txt';

fid = fopen(xfname,'w');
fmt = [repmat('%.6f ',1,size(datax,2)) '\n'];   % 根据列数生成格式串
fprintf(fid, fmt, datax.');                      % 注意转置，保证逐行写
fclose(fid);
fprintf('写入 %s （%d 行 × %d 列）\n', xfname, size(datax,1), size(datax,2));

fid = fopen(yfname,'w');
fmt = [repmat('%.6f ',1,size(datay,2)) '\n'];
fprintf(fid, fmt, datay.');
fclose(fid);
fprintf('写入 %s （%d 行 × %d 列）\n', yfname, size(datay,1), size(datay,2));

fid = fopen(zfname,'w');
fmt = [repmat('%.6f ',1,size(dataz,2)) '\n'];
fprintf(fid, fmt, dataz.');
fclose(fid);
fprintf('写入 %s （%d 行 × %d 列）\n', zfname, size(dataz,1), size(dataz,2));

%% 计算线圈磁场部分
% 生成磁场计算点
obsPoints = GenerateObservationPoints(params);

% 计算理想线圈产生的磁场
% B_cal_xg = Compute_MagneticField_BiotSavart(coilPaths_xg, obsPoints, params, 'x'); % 默认1A电流
% B_cal_yg = Compute_MagneticField_BiotSavart(coilPaths_yg, obsPoints, params, 'y');
% B_cal_zg = Compute_MagneticField_BiotSavart(coilPaths_zg, obsPoints, params, 'z');
% 计算可实现线圈产生的磁场
B_cal_xg = Compute_MagneticField_BiotSavart(CoilPath_Achievable_xg, obsPoints, params, 'x'); % 默认1A电流
B_cal_yg = Compute_MagneticField_BiotSavart(CoilPath_Achievable_yg, obsPoints, params, 'y');
B_cal_zg = Compute_MagneticField_BiotSavart(CoilPath_Achievable_zg, obsPoints, params, 'z');

%% 结果可视化
% visual_J
% visual_coilpath(coilPaths_xg, coilPaths_yg, coilPaths_zg);
Visualize_B_Field_Components(B_cal_xg, obsPoints, 'x', params);
Visualize_B_Field_Components(B_cal_yg, obsPoints, 'y', params);
Visualize_B_Field_Components(B_cal_zg, obsPoints, 'z', params);




%% 计算圆柱轴线上的磁场，以此为参照计算效率
disp('效率计算:');
% X梯度线圈效率
[B_xg_max, Idx_max] = max(B_cal_xg.B_xg_eta(:,1));
[B_xg_min, Idx_min] = min(B_cal_xg.B_xg_eta(:,1));
pos_xg_max = obsPoints.xg_eta(Idx_max,:);
pos_xg_min = obsPoints.xg_eta(Idx_min,:);
xg_eta = abs((B_xg_max-B_xg_min)/(pos_xg_max(1)-pos_xg_min(1)));
fprintf("X方向可加工梯度线圈效率为：%.3f mT/m/A \n",xg_eta*1000);
[Lx, totalLenx] = computeCoilInductance(CoilPath_Achievable_xg.Serial{1}, params.rWire);
fprintf("X方向可加工梯度线圈总长度为：%.3f m, 自感为：%.3f uH \n",totalLenx, Lx*1e6);

% Y梯度线圈效率
[B_yg_max, Idx_max] = max(B_cal_yg.B_yg_eta(:,1));
[B_yg_min, Idx_min] = min(B_cal_yg.B_yg_eta(:,1));
pos_yg_max = obsPoints.yg_eta(Idx_max,:);
pos_yg_min = obsPoints.yg_eta(Idx_min,:);
yg_eta = abs((B_yg_max-B_yg_min)/(pos_yg_max(2)-pos_yg_min(2)));
fprintf("Y方向可加工梯度线圈效率为：%.3f mT/m/A \n",yg_eta*1000);
[Ly, totalLeny] = computeCoilInductance(CoilPath_Achievable_yg.Serial{1}, params.rWire);
fprintf("Y方向可加工梯度线圈总长度为：%.3f m, 自感为：%.3f uH \n",totalLeny, Ly*1e6);

% Z梯度线圈效率
[B_zg_max, Idx_max] = max(B_cal_zg.B_zg_eta(:,1));
[B_zg_min, Idx_min] = min(B_cal_zg.B_zg_eta(:,1));
pos_zg_max = obsPoints.zg_eta(Idx_max,:);
pos_zg_min = obsPoints.zg_eta(Idx_min,:);
zg_eta = abs((B_zg_max-B_zg_min)/(pos_zg_max(3)-pos_zg_min(3)));
fprintf("Z方向可加工梯度线圈效率为：%.3f mT/m/A \n",zg_eta*1000);
[Lz, totalLenz] = computeCoilInductance(CoilPath_Achievable_zg.Serial{1}, params.rWire);
fprintf("Z方向可加工梯度线圈总长度为：%.3f m, 自感为：%.3f uH \n",totalLenz, Lz*1e6);





%% 保存图片
% save_all_figures();


%% test
% fid = fopen('CoilPath_zg.txt','w');
% 
% % -------- Positive --------
% for i = 1:numel(coilPaths_zg.Positive)
%     pts = coilPaths_zg.Positive{i};
%     pts = unique(pts,'rows','stable');   % 去重
%     fmt = [repmat('%.6f ',1,size(pts,2)) '\n'];
%     fprintf(fid, fmt, pts.');
%     % 在每个 cell 结束后写一行 NaN
%     fprintf(fid, '%s\n', repmat('NaN ',1,size(pts,2)));
% end
% 
% % -------- Negative --------
% for i = 1:numel(coilPaths_zg.Negative)
%     pts = coilPaths_zg.Negative{i};
%     pts = unique(pts,'rows','stable');   % 去重
%     fmt = [repmat('%.6f ',1,size(pts,2)) '\n'];
%     fprintf(fid, fmt, pts.');
%     % 在每个 cell 结束后写一行 NaN
%     fprintf(fid, '%s\n', repmat('NaN ',1,size(pts,2)));
% end
% 
% fclose(fid);
% disp('写入完成：CoilPath_zg.txt');




