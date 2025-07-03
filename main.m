clc
clear
close all

addpath(strcat(pwd,'\','subfunctions'));
addpath(strcat(pwd,'\','visualization'));
%% 计算线圈路径部分
params = InitParameters();
surfaceCurrent = Compute_SurfaceCurrent(params);
streamFunction = Compute_StreamFunction(surfaceCurrent, params);
% 绘制 x 方向的绕线路径柱面图
coilPaths_xg = Compute_CoilPaths(streamFunction, surfaceCurrent, params, 'x');
% 绘制 y 方向
coilPaths_yg = Compute_CoilPaths(streamFunction, surfaceCurrent, params, 'y');
% 绘制 z 方向
coilPaths_zg = Compute_CoilPaths(streamFunction, surfaceCurrent, params, 'z');

%% 计算线圈磁场部分
% 生成磁场计算点
obsPoints = GenerateObservationPoints(params);

% 计算磁场
B_cal_xg = Compute_MagneticField_BiotSavart(coilPaths_xg, obsPoints, params, 'x'); % 默认1A电流
B_cal_yg = Compute_MagneticField_BiotSavart(coilPaths_yg, obsPoints, params, 'y');
B_cal_zg = Compute_MagneticField_BiotSavart(coilPaths_zg, obsPoints, params, 'z');

%% 结果可视化
% visual_J
visual_coilpath(coilPaths_xg, coilPaths_yg, coilPaths_zg);
Visualize_B_Field_Components(B_cal_xg, obsPoints, 'x', params);
Visualize_B_Field_Components(B_cal_yg, obsPoints, 'y', params);
Visualize_B_Field_Components(B_cal_zg, obsPoints, 'z', params);


%% 可实现线圈转换
CoilPath_Achievable_xg = Achievable_CoilPath(coilPaths_xg, params, 'x');
CoilPath_Achievable_yg = Achievable_CoilPath(coilPaths_yg, params, 'y');
CoilPath_Achievable_zg = Achievable_CoilPath(coilPaths_zg, params, 'z');

%% 计算圆柱轴线上的磁场，以此为参照计算效率
disp('效率计算:');
% X梯度线圈效率
[B_xg_max, Idx_max] = max(B_cal_xg.B_xg_eta(:,1));
[B_xg_min, Idx_min] = min(B_cal_xg.B_xg_eta(:,1));
pos_xg_max = obsPoints.xg_eta(Idx_max,:);
pos_xg_min = obsPoints.xg_eta(Idx_min,:);
xg_eta = abs((B_xg_max-B_xg_min)/(pos_xg_max(1)-pos_xg_min(1)));
fprintf("X方向梯度线圈效率为：%.3f mT/m/A \n",xg_eta*1000);

% Y梯度线圈效率
[B_yg_max, Idx_max] = max(B_cal_yg.B_yg_eta(:,1));
[B_yg_min, Idx_min] = min(B_cal_yg.B_yg_eta(:,1));
pos_yg_max = obsPoints.yg_eta(Idx_max,:);
pos_yg_min = obsPoints.yg_eta(Idx_min,:);
yg_eta = abs((B_yg_max-B_yg_min)/(pos_yg_max(2)-pos_yg_min(2)));
fprintf("Y方向梯度线圈效率为：%.3f mT/m/A \n",yg_eta*1000);

% Z梯度线圈效率
[B_zg_max, Idx_max] = max(B_cal_zg.B_zg_eta(:,1));
[B_zg_min, Idx_min] = min(B_cal_zg.B_zg_eta(:,1));
pos_zg_max = obsPoints.zg_eta(Idx_max,:);
pos_zg_min = obsPoints.zg_eta(Idx_min,:);
zg_eta = abs((B_zg_max-B_zg_min)/(pos_zg_max(3)-pos_zg_min(3)));
fprintf("Z方向梯度线圈效率为：%.3f mT/m/A \n",zg_eta*1000);







%% 保存图片
save_all_figures();



