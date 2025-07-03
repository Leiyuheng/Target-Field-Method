function B_cal = Compute_MagneticField_BiotSavart(coilPaths, obsPoints, params, coilTag, I)
% 基于 Biot-Savart 定律，计算给定线圈路径在指定场点的磁场分量

if nargin < 5 || isempty(I)
    I = 1; % 默认电流 1 A
    disp('[提示] 未指定电流，自动使用默认电流 I = 1 A');
end

mu0 = params.mu0;

% 计算 bore_xg 场点磁场
B_cal.B_bore_xg = compute_field_at_points(coilPaths, obsPoints.bore_xg, I, mu0);

% 计算 bore_yg 场点磁场
B_cal.B_bore_yg = compute_field_at_points(coilPaths, obsPoints.bore_yg, I, mu0);

% 计算 transverse 场点磁场
B_cal.B_transverse = compute_field_at_points(coilPaths, obsPoints.transverse, I, mu0);

% 计算 sphericalVolume 场点磁场
B_cal.B_spherical = compute_field_at_points(coilPaths, obsPoints.sphericalVolume, I, mu0);

% 计算 XZ截面 场点磁场
B_cal.B_rectXZ = compute_field_at_points(coilPaths, obsPoints.rectXZ, I, mu0);

% 计算 YZ截面 场点磁场
B_cal.B_rectYZ = compute_field_at_points(coilPaths, obsPoints.rectYZ, I, mu0);

% 计算 x梯度效率计算 场点磁场
B_cal.B_xg_eta = compute_field_at_points(coilPaths, obsPoints.xg_eta, I, mu0);

% 计算 y梯度效率计算 场点磁场
B_cal.B_yg_eta = compute_field_at_points(coilPaths, obsPoints.yg_eta, I, mu0);

% 计算 z梯度效率计算 场点磁场
B_cal.B_zg_eta = compute_field_at_points(coilPaths, obsPoints.zg_eta, I, mu0);

disp([ upper(coilTag), ' 方向梯度线圈磁场计算完成']);

end

%% ======================== 内部函数1 ==============================
function B_total = compute_field_at_points(coilPaths, fieldPoints, I, mu0)
% 计算指定场点的磁场

B_total = zeros(size(fieldPoints)); % 初始化

groups = fieldnames(coilPaths);
for i = 1:numel(groups)
    grp = groups{i};
    B_total = B_total + sum_fields_from_paths(coilPaths.(grp), fieldPoints, I, mu0);
end


end


%% ======================== 内部函数2 ==============================
function B_sum = sum_fields_from_paths(paths, fieldPoints, I, mu0)
% 对多个路径累加磁场

B_sum = zeros(size(fieldPoints));

for i = 1:length(paths)
    path = paths{i};
    dl = diff(path, 1, 1);      % [N-1 x 3]
    r_prime = path(1:end-1, :); % [N-1 x 3]

    parfor j = 1:size(fieldPoints,1)
        r_obs = fieldPoints(j, :);
        r_diff = r_obs - r_prime;       % [N-1 x 3]
        r_mag = sqrt(sum(r_diff.^2, 2)); % [N-1 x 1]

        % Biot-Savart公式
        dB = mu0 * I / (4 * pi) * cross(dl, r_diff, 2) ./ (r_mag.^3);

        % 累加
        B_sum(j, :) = B_sum(j, :) + sum(dB, 1);
    end
end


end
