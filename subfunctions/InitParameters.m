function params = InitParameters()
% 功能：初始化TFM方法所需参数
% params - 结构体，包含几何、梯度、滤波与离散化配置

% 几何参数
params.a = 0.14;  % 外圆柱半径 [m]
params.b = 0.1;  % 梯度场DSV圆柱半径

% 梯度场参数
params.gx = 1;  % x方向梯度强度 [T/m]
params.gy = 1;  % y方向梯度强度 [T/m]
params.gz = 1;  % z方向梯度强度 [T/m]

% 梯度形状函数调节参数
params.d_factor = 1.1;   % d= d_factor * a （可调因子）
params.d = params.d_factor * params.a; % 梯度长度参数 [m]

params.n_tr = 30;  % x/y方向梯度场 阶数n
params.n_ln = 16;  % z方向梯度场 阶数n

% Apodization滤波参数
params.h = 0.1;  % 频域高斯滤波强度（调节高频抑制）

% 离散化参数
params.phi_num = 256;  % φ方向离散点数
params.z_num = 128;    % z方向离散点数
params.k_num = params.z_num;   % k频域离散点数，是z的fft，因此二者点数必须相同
params.r_num = 16;  % 外径网格
params.b_num = 24; % 内径网格

% φ方向离散网格
params.phi = linspace(-pi, pi, params.phi_num);

% z方向离散网格 (覆盖 -2d ~ 2d 区域)
params.z = linspace(-2*params.d, 2*params.d, params.z_num);

% k频域网格 (覆盖 -π/d ~ π/d 区间,可扩大纳入更多高频分量)
params.k = linspace(-2*pi/params.d, 2*pi/params.d, params.k_num);

% r方向网格 (覆盖 0 ~ a 区间)
params.r = linspace(0, params.a, params.r_num);

% 常数参数
params.mu0 = 4*pi*1e-7;  % 真空磁导率 [H/m]

% 单个线圈匝数
params.num_levels = 14;

% 线圈重新插值采样点倍数
params.inter_fac = 1.2;

% 线圈重新插值方法选择
params.method = 'linear';

% 线圈螺旋平滑阶跃控制
params.smooth_N = 3; % 阶数控制 可选3 5 7

% 从外向内相邻曲线拐角点的极角差值容限
params.deltaPsi = 0.2;

% 飞线平滑连接尾部指数阶跃点数 越多飞线的阶跃平滑越长
params.Nb = params.num_levels*2;

% 飞线指数阶跃参数控制 越大越陡峭 (exp(beta*s) - 1) ./ (exp(beta) - 1)
params.beta = 30;

% 最后可实现时考虑的实际导线半径与额外安全间距(飞线用）
params.rWire   = 0.002; % 导线半径(m)
params.gap     = 0.001; % 额外安全间隙(m)

%显示信息
disp('参数初始化：');
fprintf('外圆柱半径 a = %.3f m\n', params.a);
fprintf('内圆柱半径 b = %.3f m\n', params.b);
fprintf('梯度长度参数 d = %.3f m \n', params.d);
fprintf('Apodization 滤波参数 h = %.3f\n', params.h);

end
