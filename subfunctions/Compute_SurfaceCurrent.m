function surfaceCurrent = Compute_SurfaceCurrent(params)
% 功能：计算表面电流密度 Jφ(φ,z)、轴向电流密度 Jz(φ,z)（TFM谱域法）
% surfaceCurrent - 结构体，包含 Jφ_x/y/z, Jz_x/y/z, phi, z

%参数提取
phi = params.phi;
z = params.z;
k = params.k;

b = params.b;
a = params.a;
mu0 = params.mu0;
h = params.h;

%生成 Γtr(k)、Γln(k)
Gamma_tr = 1 ./ (1 + (z / params.d).^params.n_tr);
Gamma_ln = z ./ (1 + (z / params.d).^params.n_ln);

Gamma_tr_k = fftshift(fft(Gamma_tr)) / length(z);
Gamma_ln_k = fftshift(fft(Gamma_ln)) / length(z);

%频域滤波器 Apodization
T_k = exp(-2 * (k * h).^2);

%% 计算P̃[m](b,k), Q̃[m](b,k)
m_values = [1, 2];
P_tilde = struct();
Q_tilde = struct();

for m = m_values
    I_m_b = besseli(m, abs(k) * b);
    K_m_a = besselk(m, abs(k) * a);
    I_m_b_der = m ./ (abs(k) * b) .* I_m_b + besseli(m+1, abs(k) * b);
    K_m_a_der = -m ./ (abs(k) * a) .* K_m_a - besselk(m+1, abs(k) * a);

    P_tilde.(sprintf('m%d',m)) = a * mu0 .* k .* I_m_b_der .* K_m_a_der;
    Q_tilde.(sprintf('m%d',m)) =  m .* (a * mu0 ./ b) .* (abs(k) ./ k) .* I_m_b .* K_m_a_der;
end

%% 谱域电流密度 J̃φ(k)
% m=2 对应 x/y 梯度
Jphi_x_k = -1j * b * params.gx / pi * Gamma_tr_k .* T_k ./ (P_tilde.m2 + Q_tilde.m2);
Jphi_y_k = -1j * b * params.gy / pi * Gamma_tr_k .* T_k ./ (P_tilde.m2 + Q_tilde.m2);

% m=1 对应 z 梯度
Jphi_z_k = -1j * params.gz / pi * Gamma_ln_k .* T_k ./ (P_tilde.m1 + Q_tilde.m1);

%% IFFT 得到 Jφ(φ,z)
[PhiGrid, ZGrid] = meshgrid(phi, z);

Jphi_x = real(ifft(ifftshift(Jphi_x_k), 'symmetric'))' .* cos(2 * PhiGrid);
Jphi_y = real(ifft(ifftshift(Jphi_y_k), 'symmetric'))' .* sin(2 * PhiGrid);
Jphi_z = real(ifft(ifftshift(Jphi_z_k), 'symmetric'))' .* cos(PhiGrid);

%% 谱域关系计算 Jz(k)
k_safe = k;
k_safe(k_safe == 0) = 1e-12;  % 避免除0

% Jz_k = -m / (k * a) * Jphi_k
Jz_x_k = -2 ./ (k_safe * a) .* Jphi_x_k;
Jz_y_k = -2 ./ (k_safe * a) .* Jphi_y_k;
Jz_z_k = -1 ./ (k_safe * a) .* Jphi_z_k;

%% IFFT 得到 Jz(φ,z)
Jz_x = real(ifft(ifftshift(Jz_x_k), 'symmetric'))' .* cos(2 * PhiGrid);
Jz_y = real(ifft(ifftshift(Jz_y_k), 'symmetric'))' .* sin(2 * PhiGrid);
Jz_z = real(ifft(ifftshift(Jz_z_k), 'symmetric'))' .* cos(PhiGrid);

%% 汇总输出
surfaceCurrent.Jphi_x = Jphi_x;
surfaceCurrent.Jphi_y = Jphi_y;
surfaceCurrent.Jphi_z = Jphi_z;

surfaceCurrent.Jz_x = Jz_x;
surfaceCurrent.Jz_y = Jz_y;
surfaceCurrent.Jz_z = Jz_z;

surfaceCurrent.phi = phi;
surfaceCurrent.z = z;

disp('Compute_SurfaceCurrent: Jφ(φ,z) 与 Jz(φ,z) 计算完成');



% 可视化 Γtr(z) 和 Γln(z)
figure('Name','Gamma Functions','Position',[350,250,1300,600]);

subplot(1,2,1);
plot(z, Gamma_tr, 'LineWidth', 2);
xlabel('z (m)');
ylabel('\Gamma_{tr}(z)');
title(['\Gamma_{tr}(z),  d = ', num2str(params.d), 'm,  n = ', num2str(params.n_tr)]);
grid on;

subplot(1,2,2);
plot(z, Gamma_ln, 'LineWidth', 2);
xlabel('z (m)');
ylabel('\Gamma_{ln}(z)');
title(['\Gamma_{ln}(z),  d = ', num2str(params.d), 'm,  n = ', num2str(params.n_ln)]);
grid on;

end
