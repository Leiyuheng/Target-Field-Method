function coilPaths = Compute_CoilPaths(streamFunction, surfaceCurrent, params, direction)
% 功能：将Ψ等值线转换为导线路径点，并按电流实际方向输出路径数据
% coilPaths - 结构体，包含 Positive 与 Negative 路径，均已按电流流动方向排序

%% 参数提取
phi = params.phi;
z   = params.z;
r   = params.a;
num_levels = params.num_levels;
ratio = params.dir_check_ratio;  % 默认取前10%

% 选择对应方向的数据
switch lower(direction)
    case 'x'
        Psi  = streamFunction.Psi_x;
        Jphi = surfaceCurrent.Jphi_x;
        Jz   = surfaceCurrent.Jz_x;
    case 'y'
        Psi  = streamFunction.Psi_y;
        Jphi = surfaceCurrent.Jphi_y;
        Jz   = surfaceCurrent.Jz_y;
    case 'z'
        Psi  = streamFunction.Psi_z;
        Jphi = surfaceCurrent.Jphi_z;
        Jz   = surfaceCurrent.Jz_z;
    otherwise
        error('direction 只能是 x / y / z');
end

%% 提取等值线并转换为三维路径
contourData = contourc(phi, z, Psi, num_levels*2);
rawPaths = struct('Positive',{{}}, 'Negative',{{}});
idx = 1;
while idx < size(contourData,2)
    level = contourData(1,idx);
    npts  = contourData(2,idx);
    path_phi = contourData(1, idx+1:idx+npts);
    path_z   = contourData(2, idx+1:idx+npts);
    x = r * cos(path_phi);
    y = r * sin(path_phi);
    raw = [x', y', path_z'];
    if level > 0
        rawPaths.Positive{end+1} = raw;
    else
        rawPaths.Negative{end+1} = raw;
    end
    idx = idx + npts + 1;
end

%% 闭合与互补处理
phi_step = abs(phi(2)-phi(1));
close_thr = 1e-3 * r * phi_step;
match_thr = r * phi_step;
procPaths.Positive = ProcessPaths(rawPaths.Positive, close_thr, match_thr);
procPaths.Negative = ProcessPaths(rawPaths.Negative, close_thr, match_thr);

%% 方向校正
% coilPaths = procPaths;
coilPaths = CorrectPathDirection(procPaths, direction);

disp(['Compute_CoilPaths: ', direction, ' 方向绕线路径提取与校正完成']);
end


function corrected = CorrectPathDirection(procPaths, dir)
% 功能：对闭合路径执行方向校正，使电流方向与流函数保持一致

corrected = procPaths;

% 校正路径
for i = 1:length(procPaths.Negative)
    pathN = procPaths.Negative{i};
    pathP = procPaths.Positive{i};

    % 空路径检查
    if isempty(pathN) || isempty(pathP)
        continue;
    end

    switch dir
        case 'x'
            % z梯度线圈反转条件
            if pathN(1,2) > 0
                corrected.Negative{i} = flipud(pathN);
            end
            corrected.Positive{i} = flipud(pathP);
        case 'y'
            % y梯度线圈反转条件
            if pathN(1,1) < 0
                corrected.Negative{i} = flipud(pathN);
            end
            if pathP(1,1) < 0
                corrected.Positive{i} = flipud(pathP);
            end
        case 'z'
            % z梯度线圈反转条件
            corrected.Positive{i} = flipud(pathP);

        otherwise
            error('仅支持方向：x / y / z');
    end
end



end
