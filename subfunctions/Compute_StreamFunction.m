function streamFunction = Compute_StreamFunction(surfaceCurrent, params)
% 计算各方向流函数与绕线路径数据

%提取参数
phi = surfaceCurrent.phi;
z = surfaceCurrent.z;

[PhiGrid, ZGrid] = meshgrid(phi, z);

%计算各方向 J_total
Jphi_x = surfaceCurrent.Jphi_x;
Jphi_y = surfaceCurrent.Jphi_y;
Jphi_z = surfaceCurrent.Jphi_z;

Jz_x = surfaceCurrent.Jz_x;
Jz_y = surfaceCurrent.Jz_y;
Jz_z = surfaceCurrent.Jz_z;

Jtotal_x = sqrt(Jphi_x.^2 + Jz_x.^2);
Jtotal_y = sqrt(Jphi_y.^2 + Jz_y.^2);
Jtotal_z = sqrt(Jphi_z.^2 + Jz_z.^2);

%分别计算x/y/z方向流函数 Ψ 
Psi_x = cumtrapz(z, Jphi_x, 1); % 沿z积分计算Phi分量
Psi_y = cumtrapz(z, Jphi_y, 1);
Psi_z = cumtrapz(z, Jphi_z, 1);

% Psi_x_1 = cumtrapz(phi, Jphi_x, 1)/params.a; % 沿z积分计算Phi分量
% Psi_y_1 = cumtrapz(phi, Jphi_y, 1)/params.a;
% Psi_z_1 = cumtrapz(phi, Jphi_z, 1)/params.a; 
% 只需计算一种即可，由于数值方法，二者计算出来会相差一个倍数，不过不影响导线生成

%输出结果
streamFunction.Psi_x = Psi_x;
streamFunction.Psi_y = Psi_y;
streamFunction.Psi_z = Psi_z;

streamFunction.Jtotal_x = Jtotal_x;
streamFunction.Jtotal_y = Jtotal_y;
streamFunction.Jtotal_z = Jtotal_z;

% 绘制展开视图 (φ-z平面) 2D
figure('Name','流函数Ψ展开图','Position',[400,300,1300,600]);

subplot(1,3,1);
contourf(PhiGrid, ZGrid, Psi_x, 20, 'LineColor','none');
title('x梯度Ψ');
xlabel('\phi (rad)');
ylabel('z (m)');
colorbar;

subplot(1,3,2);
contourf(PhiGrid, ZGrid, Psi_y, 20, 'LineColor','none');
title('y梯度Ψ');
xlabel('\phi (rad)');
ylabel('z (m)');
colorbar;

subplot(1,3,3);
contourf(PhiGrid, ZGrid, Psi_z, 20, 'LineColor','none');
title('y梯度Ψ');
xlabel('\phi (rad)');
ylabel('z (m)');
colorbar;



% % 绘制展开视图 (φ-z平面) 3D
% % 数据结构体定义
% PsiData(1).Value = Psi_x; PsiData(1).Title = 'x梯度Ψ';
% PsiData(2).Value = Psi_y; PsiData(2).Title = 'y梯度Ψ';
% PsiData(3).Value = Psi_z; PsiData(3).Title = 'z梯度Ψ';
% 
% % 假设 PhiGrid、ZGrid、PsiData 如前
% 
% % 抽稀步长
% step = 16;
% 
% % 取子集索引
% indsPhi = 1:step:size(PhiGrid,1);
% indsZ   = 1:step:size(PhiGrid,2);
% 
% figure('Name','稀疏彩色丝网效果','Position',[400,300,1300,600]);
% colormap(jet);
% 
% for i = 1:3
%     subplot(1,3,i);
% 
%     % 子采样网格
%     Xs = PhiGrid(indsPhi, indsZ);
%     Ys = ZGrid  (indsPhi, indsZ);
%     Zs = PsiData(i).Value(indsPhi, indsZ);
% 
%     h = mesh(Xs, Ys, Zs);
%     h.EdgeColor = 'interp';
%     h.LineWidth = 1.2;
% 
%     title(PsiData(i).Title,'Interpreter','none');
%     xlabel('\phi (rad)'); ylabel('z (m)'); zlabel('\Psi 强度');
%     axis tight; view(45,30); grid on;
% end
% 



%绘制展开视图 (φ-z平面)
figure('Name','电流密度展开图','Position',[450,350,1300,600]);

subplot(1,3,1);
contourf(PhiGrid, ZGrid, Jtotal_x, 20, 'LineColor','none');
title('x梯度电流密度幅度');
xlabel('\phi (rad)');
ylabel('z (m)');
colorbar;

subplot(1,3,2);
contourf(PhiGrid, ZGrid, Jtotal_y, 20, 'LineColor','none');
title('y梯度电流密度幅度');
xlabel('\phi (rad)');
ylabel('z (m)');
colorbar;

subplot(1,3,3);
contourf(PhiGrid, ZGrid, Jtotal_z, 20, 'LineColor','none');
title('z梯度电流密度幅度');
xlabel('\phi (rad)');
ylabel('z (m)');
colorbar;

disp('Compute_StreamFunction: 三梯度方向流函数Ψ与Jtotal计算完成');
end
