function CornerIdx = DetectSpiralCorners(Achi_CoilPath_uniform, CoilPsi_uniform, deltaPsi, params)
% 根据曲率检测拐点
r = params.a; % 圆柱外半径
groups = fieldnames(Achi_CoilPath_uniform);
M      = numel(Achi_CoilPath_uniform.(groups{1}));

%% 第一部分 计算曲率
% 初始化存放曲率的结构体
Kappa = struct();

% 对每一个组和每一层曲线，计算曲率
for g = 1:numel(groups)
    grp = groups{g};
    % 每一组都是 1×M 的 cell array
    Kappa.(grp) = cell(1, M);
    
    for j = 1:M
        % 提取 θ 和 z
        D     = Achi_CoilPath_uniform.(grp){j};  
        theta = D(:,1);   % newN×1
        z     = D(:,2);   % newN×1
        
        % 用 gradient 做一阶、二阶导近似
        stheta = r * theta;
        dtheta  = gradient(stheta);   
        dz      = gradient(z);
        ddtheta = gradient(dtheta);
        ddz     = gradient(dz);
        
        % 曲率公式： k = |θ'·z'' – z'·θ''| / ( (θ'^2 + z'^2)^(3/2) + eps )
        k = abs( dtheta .* ddz - dz .* ddtheta ) ...
            ./ ( (dtheta.^2 + dz.^2).^(3/2) + eps );
        
        % 存入结果
        Kappa.(grp){j} = k; % N×1
    end
end

% 初始化存放排序索引的结构体
KappaOrder = struct();

for g = 1:numel(groups)
    grp = groups{g};
    KappaOrder.(grp) = cell(1, M);
    
    for j = 1:M
        k = Kappa.(grp){j}; % N×1 曲率向量
        [~, ord] = sort(k, 'descend'); % ord 是从大到小的索引序列
        KappaOrder.(grp){j} = ord; % 存入结构体
    end
end

%% 第二部分 寻找拐点
CornerIdx = struct();
getQ = @(psi) (psi>=0 & psi<pi/2)*1 + (psi>=pi/2 & psi<pi)*2 + ...
              (psi>=-pi & psi<-pi/2)*3 + (psi>=-pi/2 & psi<0)*4;

% 对每个组，确定最外圈的 j
for g = 1:numel(groups)
    grp = groups{g};
    if startsWith(grp, 'Positive')
        j_outer = 1; % Positive 组最外圈为第 1 层
    else
        j_outer = M; % Negative 组最外圈为第 M 层
    end
    
    % 提取该层的曲率与 ψ
    k_outer   = Kappa.(grp){j_outer}; % N×1
    psi_outer = CoilPsi_uniform.(grp){j_outer}; % N×1
    
    % 准备存放这一层的四象限拐点索引
    CornerIdx.(grp) = cell(1, M);
    sel = nan(1,4);
    
    % 对每个象限 q=1..4，找该象限中曲率最大的点
    for q = 1:4
        % 找出落在象限 q 的所有点索引
        idx_q = find( getQ(psi_outer)==q );
        if isempty(idx_q)
            sel(q) = NaN;
        else
            % 在这些点里，找曲率最大的那个
            [~, in_order] = max( k_outer(idx_q) );
            sel(q) = idx_q(in_order);
        end
    end
    
    % 存储四个象限 按照1、2、3、4象限存储
    CornerIdx.(grp){j_outer} = sel;
end


for g = 1:numel(groups)
    grp = groups{g};

    % 外圈 j_outer 已处理
    if startsWith(grp, 'Positive')
        j_start = 2; j_end = M;    j_step = 1;
    else
        j_start = M-1; j_end = 1;  j_step = -1;
    end

    for j = j_start:j_step:j_end
        % 上一层（外层或更外层）拐点索引 & ψ 参考
        j_prev = j - j_step;
        sel_prev = CornerIdx.(grp){j_prev}; % 1×4，可能含 NaN
        psi_ref  = nan(1,4);
        for q = 1:4
            idx_prev = sel_prev(q);
            if ~isnan(idx_prev)
                psi_ref(q) = CoilPsi_uniform.(grp){j_prev}(idx_prev);
            end
        end

        % 当前层 ψ 和曲率
        psi_cur = CoilPsi_uniform.(grp){j}; % N×1
        k_cur   = Kappa.(grp){j}; % N×1

        sel_cur = nan(1,4);
        for q = 1:4
            % 本象限所有点
            idx_q = find( getQ(psi_cur)==q );
            if isempty(idx_q), continue; end

            % 单调性：象限 1、3 内圈 ψ 要“变大”；象限 2、4 要“变小”
            if any(q==[1,3])
                diffs = psi_cur(idx_q) - psi_ref(q);
            else
                diffs = psi_ref(q) - psi_cur(idx_q);
            end

            % 满足差值在 [0, deltaPsi] 的候选
            c1 = (diffs>=0 & diffs<=deltaPsi);
            candidates = idx_q(c1);
            
            if isempty(candidates)
                % 如果没有严格满足的，就退而求其次：所有 Δψ>=0 的点
                posIdx = find(diffs>=0);      % 在 idx_q 中的位置
                if ~isempty(posIdx)
                    % 在这些点里找 ψ 差值最小的那个
                    [~, i_min] = min(diffs(posIdx));
                    sel_cur(q) = idx_q(posIdx(i_min));
                else
                    % 连 Δψ>=0 的都没有，就退到同象限中曲率最大的
                    [~, order]   = max( k_cur(idx_q) );
                    sel_cur(q)   = idx_q(order);
                end
            else
                % 正常情况：在严格候选里取曲率最大的
                [~, imax]     = max( k_cur(candidates) );
                sel_cur(q)    = candidates(imax);
            end
        end

        % 存回
        CornerIdx.(grp){j} = sel_cur;
    end
end



%% 绘图部分
figure('Name','线圈拐点计算结果图'); hold on;
colors = lines(numel(groups));   % 分配每个组一种颜色

% 四象限标记样式（统一所有组使用相同形状）
quadMarkers = {'o','s','d','^'};

for g = 1:numel(groups)
    grp  = groups{g};
    cmap = colors(g,:);
    
    % —— 先画一条“虚拟”曲线，只为了 legend
    plot(nan, nan, '-', 'Color', cmap, 'LineWidth', 1.2, ...
         'DisplayName', grp);
    
    % 真正绘制每层的曲线和拐点
    for j = 1:M
        D      = Achi_CoilPath_uniform.(grp){j};   % newN×2 [θ,z]
        ptsIdx = CornerIdx.(grp){j};               % 1×4 含 NaN
        
        % —— 画曲线
        plot(D(:,1), D(:,2), '-', ...
             'Color', cmap, 'LineWidth', 0.8, ...
             'HandleVisibility','off');
        
        % —— 画四象限拐点
        for q = 1:4
            idx = ptsIdx(q);
            if isnan(idx), continue; end
            plot(D(idx,1), D(idx,2), quadMarkers{q}, ...
                 'MarkerEdgeColor','k', ...
                 'MarkerFaceColor',cmap, ...
                 'MarkerSize',6, ...
                 'HandleVisibility','off');
        end
    end
end

% 最后只显示四个组名
legend('show','Location','bestoutside');
xlabel('\theta (rad)');
ylabel('z');
title('线圈拐点计算结果图');
grid on; hold off;

end