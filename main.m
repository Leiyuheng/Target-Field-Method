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
% 
%% 结果可视化
% visual_J
visual_coilpath(coilPaths_xg, coilPaths_yg, coilPaths_zg);
Visualize_B_Field_Components(B_cal_xg, obsPoints, 'x', params);
Visualize_B_Field_Components(B_cal_yg, obsPoints, 'y', params);
Visualize_B_Field_Components(B_cal_zg, obsPoints, 'z', params);

% 保存图片
save_all_figures();




