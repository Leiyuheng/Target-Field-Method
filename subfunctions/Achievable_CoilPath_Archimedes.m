function CoilPath_Achievable = Achievable_CoilPath_Archimedes(CoilPath, params, direction, endtail_num_inside, endtail_num_outside)
% 将线圈转变为串联导线
% 注意 在之前的计算中 会发现Positive的两组线圈是由略微差异的
% 这些差异包括数据点不均匀，数据点数量不同，形状略有差异（几乎可以忽略）
% 从MRI理论上说，原本两组线圈应当是一致的 但是由于contourc函数直接输出等值线，因此差异原因并不透明
% 因此为了拐角检测等处理的方便，在该可实现处理中对Positive与Negative中的一组（Positive1与Negative1）进行插值重建
% 另一组（Positive2与Negative2）由重建一组在phi方向上平移pi(XY梯度)或z方向对称(Z梯度)得到
% 可以通过手动微调endtail_num_inside, endtail_num_outside 来控制螺旋线起始点
% 从而略微调整连接形状 默认都是0 0
if nargin < 4 % 只传了3 个参数
    endtail_num_inside  = 0;
    endtail_num_outside = 0;
end

smooth_N = params.smooth_N;
factor = params.inter_fac; 
deltaPsi = params.deltaPsi;
method = params.method;
Nt = params.num_levels; % 用于最后飞线的插值点数确定 3*Nt 
Nb = params.Nb; % 飞线尾部翘起点数
beta = params.beta; % 阶跃函数控制 越大越陡
a = params.a; % 圆柱外半径
rWire = params.rWire; % 导线半径(m)
gap = params.gap; % 额外安全间隙(m)

%% 第一部分 将线圈分组并映射到phi-z平面 并解缠绕

Achi_CoilPath = struct( ...
    'Positive1', {{ }}, 'Positive2', {{ }}, ...
    'Negative1', {{ }}, 'Negative2', {{ }} ...
);
Achi_CoilPath_cyl = struct( ...
    'Positive1', {{ }}, 'Positive2', {{ }}, ...
    'Negative1', {{ }}, 'Negative2', {{ }} ...
); % 第一列为phi, 第二列为z
%  根据 direction 确定分类时判断依据 
switch lower(direction)
    case {'x','y'}
        % 对于 x 或 y 方向：Negative 用第二列，Positive 用第一列
        idxN = 2;
        idxP = 1;
    case 'z'
        % 对于 z 方向，两者都用第三列
        idxN = 3;
        idxP = 3;
    otherwise
        error('direction 必须是 ''x'', ''y'' 或 ''z''');
end
% 为了保证螺旋线在二维平面上，需要将其变换到柱坐标进行处理
N = numel(CoilPath.Positive);
for i = 1:N
    pathN = CoilPath.Negative{i};
    pathP = CoilPath.Positive{i};

    if pathN(1, idxN) > 0
        Achi_CoilPath.Negative1{end+1} = pathN;
    else
        Achi_CoilPath.Negative2{end+1} = pathN;
    end

    if pathP(1, idxP) > 0
        Achi_CoilPath.Positive1{end+1} = pathP;
    else
        Achi_CoilPath.Positive2{end+1} = pathP;
    end
end

N = numel(Achi_CoilPath.Positive1);
for i = 1:N
    pathN1 = Achi_CoilPath.Negative1{i};
    pathN2 = Achi_CoilPath.Negative2{i};
    pathP1 = Achi_CoilPath.Positive1{i};
    pathP2 = Achi_CoilPath.Positive2{i};

    [phi, ~] = cart2pol(pathN1(:,1), pathN1(:,2));
    z =pathN1(:,3);
    Achi_CoilPath_cyl.Negative1{end+1} = [unwrap(phi),z];

    [phi, ~] = cart2pol(pathN2(:,1), pathN2(:,2));
    z =pathN2(:,3);
    Achi_CoilPath_cyl.Negative2{end+1} = [unwrap(phi),z];

    [phi, ~] = cart2pol(pathP1(:,1), pathP1(:,2));
    z =pathP1(:,3);
    Achi_CoilPath_cyl.Positive1{end+1} = [unwrap(phi),z];

    [phi, ~] = cart2pol(pathP2(:,1), pathP2(:,2));
    z =pathP2(:,3);
    Achi_CoilPath_cyl.Positive2{end+1} = [unwrap(phi),z];
end
% 作图验证
% plotSpiralDotLine(Achi_CoilPath_cyl, '初始线圈组');

%% 第二部分 计算质心、极角并按照极角排序（Positive从pi到-pi，Negative从-pi到pi）
% 关于质心 原本的计算方式是对于每条等值线都计算其自己的质心，然后计算极角
% 该方法对于xy线圈都没有出现问题，但是对于z梯度线圈其外部线圈的质心明显偏移
% 由于质心直接关联到极角 而极角后续会在螺旋线中作为插值的自变量 质心偏移很可能会造成曲线重叠
% 因此对于一组曲线 质心应当一致，后改为对于z梯度线圈质心用最内侧等值线的质心为整组线圈的质心
% 而x与y梯度，由于其z方向过长，每条曲线可各自计算质心，使得极角更加准确

CoilPsi = struct(); % 存储每条曲线的质心和极角
if startsWith(direction,'z')
    groups = {'Positive1','Negative1'}; % 规定groups顺序
else
    groups = {'Positive1','Negative2'}; % 规定groups顺序
end
for k = 1:numel(groups)
    grp = groups{k};
    curves = Achi_CoilPath_cyl.(grp);
    M = numel(curves);
    
    % 先初始化：每个都是 M×1 的 cell
    CoilPsi.(grp) = cell(1,M);
    if startsWith(grp,'Positive')
        CoilCentroid = [mean(curves{end}(:,1)), mean(curves{end}(:,2))];
    else
        CoilCentroid = [mean(curves{1}(:,1)), mean(curves{1}(:,2))];
    end
    
    for j = 1:M
        % 计算极角 ψ = atan2(z−z_c, φ−φ_c)，范围 [-π, π]
        if startsWith(direction,'z')
            psi = Calculate_Psi(curves{j},CoilCentroid);
        else
            psi = Calculate_Psi(curves{j});
        end

        % 存入结果
        CoilPsi.(grp){j} = psi;           
    end
end

% 无论从作图还是质心都会发现两组Positive和Negative都有略微的区别，可能是由于数值误差导致
% 因为获取等值线是通过contourc函数获取的，因此这部分差异的原因并不透明
% 下面进行排序
Achi_CoilPath_cyl_sorted = struct();
CoilPsi_sorted = struct();
groups = fieldnames(CoilPsi);
for k = 1:numel(groups)
    grp = groups{k};
    curves = CoilPsi.(grp);
    M = numel(curves);
    
    for j = 1:M
        if startsWith(grp,'Positive')
            [psi_sorted,Idx] = sort(CoilPsi.(grp){j},'descend'); % 前两个为Positive，从pi到-pi排序
        else 
            [psi_sorted,Idx] = sort(CoilPsi.(grp){j},'ascend'); % 后面为Negative，从pi到-pi排序
        end
        CoilPsi_sorted.(grp){j} = psi_sorted;
        Achi_CoilPath_cyl_sorted.(grp){j} = Achi_CoilPath_cyl.(grp){j}(Idx,:);
    end
end

% 作图验证
% plotSpiralDotLine(Achi_CoilPath_cyl_sorted, '按极角排序后的线圈图');

%% 第三部分 进行插值，构造为均匀采样
% 初始化输出结构
Achi_CoilPath_uniform = struct();
CoilPsi_uniform       = struct();

for k = 1:numel(groups)
    grp    = groups{k};
    curves = Achi_CoilPath_cyl_sorted.(grp);
    psis   = CoilPsi_sorted.(grp);
    M      = numel(curves);
    Achi_CoilPath_uniform.(grp) = cell(1, M);
    CoilPsi_uniform.(grp)       = cell(1, M);

    for j = 1:M
        % 原始数据（已经按 ψ 排好序）
        data_old = curves{j}; % Nj×2 [θ, z]
        phi = data_old(:,1); % Nj×1
        z_old = data_old(:,2); % Nj×1
        psi_old = psis{j}; % Nj×1

        % 去重+平均：对相同 ψ 做 θ,z 平均
        [psi_u, ~, ic] = unique(psi_old, 'stable');
        phi_u = accumarray(ic, phi, [], @mean);
        z_u = accumarray(ic, z_old, [], @mean);

        newN   = round(numel(psi_u) * factor); % psi_u 为去重后的原数据
        [phi_new, z_new, psi_new] = resampleByChord(phi_u, z_u, psi_u, newN, method); % 根据弦长进行插值

        % 存回
        Achi_CoilPath_uniform.(grp){j} = [phi_new, z_new];
        CoilPsi_uniform.(grp){j}       = psi_new;
    end
end

% 由于后续需要对psi进行螺旋线插值计算，在此检查psi与[phi z]是否严格对应
for k = 1:numel(groups)
    grp = groups{k};
    M = numel(Achi_CoilPath_uniform.(grp));
    for j = 1:M
        phi_z = Achi_CoilPath_uniform.(grp){j};  % newN×2
        psi_new = CoilPsi_uniform.(grp){j};   % newN×1

        % 1）维度检查
        assert(size(phi_z,1) == numel(psi_new), ...
               '组 %s，第 %d 条：行数不匹配 (%d vs %d)', ...
               grp, j, size(phi_z,1), numel(psi_new));
    end
end
disp('✔ 所有组的 ψ 已与 [θ,z] 完全一一对应。');

% 作图验证
% plotSpiralDotLine(Achi_CoilPath_uniform, '插值后的均匀线圈图');

%% 第四部分 进行拐角检测
CornerIdx = DetectSpiralCorners(Achi_CoilPath_uniform, CoilPsi_uniform, deltaPsi, params);
% CornerIdx也是一个结构体，其包括四组:Positive两组，Negative两组
% 每组中也有M个cell，每个cell是一个1*4的数组，其中顺序存放这该曲线四个象限的拐点索引

% 需要提及的是 由于z方向线圈构造时 在phi方向上平移了pi，且目前数据都是unwrap形式
% 因此画图中 z方向线圈会在phi方向上有pi的偏移 但是后续处理时会wrap 不会影响最终结果

%% 第五部分 用阿基米德螺旋思想构造串联线
% 需要注意的是 在此的处理为了后续相邻的Negative与Positive便于边缘连接
% 构造螺旋线时 Positive选择从二象限到三象限的拼接 数据顺序从pi到-pi
% Negative选择从四象限到一象限拼接 数据顺序从0到pi跨越-pi再到0
CoilPath_serial_within = struct();
Psi_segment_save = struct();
groups = fieldnames(CoilPsi_uniform);
delta_endtail = endtail_num_inside- endtail_num_outside;
for k = 1:numel(groups)
    grp = groups{k};
    curves = CoilPsi_uniform.(grp);
    M = numel(curves);
    for j = 1:M-1
        psi1 = CoilPsi_uniform.(grp){j}(:);
        pts1 = Achi_CoilPath_uniform.(grp){j}; 

        psi2 = CoilPsi_uniform.(grp){j+1}(:);
        pts2 = Achi_CoilPath_uniform.(grp){j+1}; % 得到相邻两个曲线的极角psi和phi-z数据
        
        if startsWith(grp, 'Positive')
            % Positive，从pi到-pi排序，从外圈向内走
            start1 = CornerIdx.(grp){j}(3);
            end1 = CornerIdx.(grp){j}(2) + endtail_num_outside + floor(delta_endtail*j/(M-1));
            % end1 = find( psi1 < deg2rad(170), 1, 'first' ); % 终止点为90度位置

            psi1_segment = [psi1(start1:end);psi1(1:end1)]; % 跨起始点拼接 需要检查开始象限与终止象限是否跨起始点
            pts1_segment = [pts1(start1:end,:);pts1(1:end1,:)]; 
        else
            % Negative，从-pi到pi排序，从内圈向外走
            start1 = CornerIdx.(grp){j}(4) - endtail_num_inside + floor(delta_endtail*j/(M-1));
            end1 = CornerIdx.(grp){j}(1);

            psi1_segment = psi1(start1:end1); % 从第四象限到第一象限不跨起点
            pts1_segment = pts1(start1:end1,:); 
        end

        Psi_segment_save.(grp){j} = psi1_segment;
        N = length(psi1_segment); % 以外圈数据点为基准

        tail = [];
        for m = 1:N
            target_psi = psi1_segment(m);
            % 插值找到外圈对应极角的数据
            phi_target_psi = interp1(psi2, pts2(:,1), target_psi, 'pchip');
            z_target_psi   = interp1(psi2, pts2(:,2), target_psi, 'pchip');
            t = m/N; % 线性权重
            switch smooth_N
                case 3 
                    w = 3*t^2 - 2*t^3; % 三阶平滑阶跃
                case 5
                    w = 6*t^5 - 15*t^4 + 10*t^3; % 五阶平滑阶跃
                case 7
                    w = 35*t^4 - 84*t^5 + 70*t^6 - 20*t^7; % 七阶平滑阶跃
                otherwise
                    error('阶跃只能是三/五/七阶');
            end
            target_pts = pts1_segment(m,:) * (1 - w) + w*[phi_target_psi, z_target_psi];
            tail = [tail;target_pts];
        end
        % 拼接前段数据
        if j <= 1
            if startsWith(grp,'Positive')
                CoilPath_serial_within.(grp){j} = [pts1(1:start1-1,:);tail]; 
            else
                idx1 = find( psi1 > 0, 1, 'first' ); 
                CoilPath_serial_within.(grp){j} = [pts1(idx1:end,:);pts1(1:start1-1,:);tail]; 
            end  
        else
            psi_last = Psi_segment_save.(grp){j-1}(end);
            if startsWith(grp,'Positive')
                start = find( psi1 <= psi_last, 1, 'first' );
                CoilPath_serial_within.(grp){j} = [pts1(start:start1-1,:);tail];
            else
                start = find( psi1 >= psi_last, 1, 'first' );
                CoilPath_serial_within.(grp){j} = [pts1(start:end,:);pts1(1:start1-1,:);tail];
            end
        end
    end
    
    psi_last = Psi_segment_save.(grp){M-1}(end);
    psi1 = CoilPsi_uniform.(grp){M}(:);
    if startsWith(grp,'Positive')
        start = find( psi1 <= psi_last, 1, 'first' );
        CoilPath_serial_within.(grp){M} = Achi_CoilPath_uniform.(grp){M}(start:end,:); % 最后一段
    else
        start = find( psi1 >= psi_last, 1, 'first' );
        idx4 = find( psi1 < 0, 1, 'last' );
        curve = Achi_CoilPath_uniform.(grp){M};
        CoilPath_serial_within.(grp){M} = [curve(start:end,:); curve(1:idx4,:)]; % 最后一段
    end
   
end

% 对于z梯度线圈进行特殊处理，截断最后造成飞线负角度的部分
% 即内圈最后只落到极角为pi/2或-pi/2处
if startsWith(direction,'z')
    groups = fieldnames(CoilPath_serial_within);
    for k = 1:numel(groups)
        grp = groups{k};
        if startsWith(grp,'Positive') % 对于Positive 选-pi/2极角做判断
            curve = CoilPath_serial_within.(grp){end};
            psi_curve = Calculate_Psi(curve);
            idx_cut = find(psi_curve > -pi/2 & psi_curve < 0, 1, 'last');
            CoilPath_serial_within.(grp){end} = curve(1:idx_cut,:);
        else % 对于Negative 选pi/2极角做判断
            curve = CoilPath_serial_within.(grp){1};
            psi_curve = Calculate_Psi(curve);
            idx_cut = find(psi_curve > pi/2, 1, 'first');
            CoilPath_serial_within.(grp){1} = curve(idx_cut:end,:);
        end
    end
end



% 作图验证
plotSpiralDotLine(CoilPath_serial_within, ['串联等值线内圈点线图，使用',num2str(smooth_N),'阶平滑阶跃连接']);

%% 第六部分 串联组间曲线

% 对于x和y线圈 Positive1和Negative2外圈相邻，Positive2和Negative1外圈相邻
% 最终Positive1和Negative1、Positive2和Negative2内圈相连
% 对于z线圈 Positive1和Negative1外圈相邻，Positive2和Negative2外圈相邻
% 最终Positive1和Positive2、Negative1和Negative2内圈相连

% 首先将数据wrap回去方便后续相邻段连接处理
CoilPath_wrap = struct();
for g = 1:numel(groups)
    grp = groups{g};
    segs = CoilPath_serial_within.(grp);
    M = numel(segs);
    CoilPath_wrap.(grp) = cell(1,M);

    for j = 1:M
        data = segs{j};
        phi_wrap  = wrapToPi(data(:,1));
        CoilPath_wrap.(grp){j} = [phi_wrap, data(:,2)];
    end
end

% 首先对于外圈相连进行处理
CoilPath_serial_outside = CoilPath_wrap;
if startsWith(direction,'z')
    % 对于x和y梯度线圈进行处理
    pairs = {'Positive1','Negative1'}; % z 梯度线圈
else
    pairs = {'Positive1','Negative2'}; % x / y 梯度线圈
end

g1 = pairs{1}; % 头段所在组
g2 = pairs{2}; % 尾段所在组

% 取曲线 & 拐点
curve1 = CoilPath_wrap.(g1){1}; % Positive最外圈
curve2 = CoilPath_wrap.(g2){end}; % Negative最外圈
idx2   = CornerIdx.(g1){1}(2); % Positive拐点
idx4   = CornerIdx.(g2){end}(4); % Negative拐点
% 这里需要注意的是 由于在构建inside_Serial时 N会导致曲线数据点数量的变化
% 因此在这里直接使用Idx会出错，解决方法是寻找极角
% 因为极角数据CoilPsi_uniform并未发生改变
psi1 = CoilPsi_uniform.(g1){1}(idx2);
psi2 = CoilPsi_uniform.(g2){end}(idx4);

% 因此需要计算新曲线的极角 由于数据顺序是排过序的 因此不必再排序
psi_curve1 = Calculate_Psi(curve1); % Positive的极角
psi_curve2 = Calculate_Psi(curve2); % Negative的极角

idx_curve1 = find(psi_curve1 < psi1 & psi_curve1 > 0, 1, 'first'); % Positive 选择最外圈离拐点最近的 第一象限
idx_curve2 = find(psi_curve2 < psi2 & psi_curve2 < 0, 1, 'last'); % Negative

% [~, idx_curve1] = min( abs( angle( exp(1i*(psi_curve1 - psi1)) ) ) ); 
% [~, idx_curve2] = min( abs( angle( exp(1i*(psi_curve2 - psi2)) ) ) );
Minpts = 10;
idx_curve1 = max(Minpts,idx_curve1);
idx_curve2 = min(length(curve2)-Minpts,idx_curve2);
seg1 = curve1(1:idx_curve1 ,:);
seg2 = curve2(idx_curve2:end ,:);


% 线性平移phi
N1 = length(seg1);
N2 = length(seg2);
cen_phi = (seg1(1,1)*N2 + seg2(end,1)*N1)/(N1+N2);% 由于两段过渡线点数可能悬殊 因此让点数参与决策

diff_phi1 = (cen_phi - seg1(1,1));
diff_phi2 = (cen_phi - seg2(end,1));
seg1(:,1) = seg1(:,1) + linspace(diff_phi1,0,size(seg1,1)).';
seg2(:,1) = seg2(:,1) + linspace(0, diff_phi2,size(seg2,1)).';

% 写回
tmp1 = CoilPath_serial_outside.(g1){1};
tmp1(1:idx_curve1 ,:) = seg1;
CoilPath_serial_outside.(g1){1} = tmp1;

tmp2 = CoilPath_serial_outside.(g2){end};
tmp2(idx_curve2:end ,:) = seg2;
CoilPath_serial_outside.(g2){end} = tmp2;

% 作图验证
% plotSpiralDotLine(CoilPath_serial_within, [direction,'串联等值线外圈点线图']);

%% 第七部分 根据现有组间曲线对称构造剩余组
% 对于XY梯度 现有Positive1和Negative2 需要在Phi方向上平移2pi得到
% 对于Z梯度 现有Positive1与Negative1 需要在Z方向上对称得到
for idx = 1:2
    base = groups{idx}; % 'Positive1' 或 'Negative1'
    if strcmp(base,'Positive1')
        if startsWith(direction,'z')
            twin = 'Negative2'; % Z梯度
        else
            twin = 'Positive2'; % XY梯度
        end
    else
        if startsWith(direction,'z')
            twin = 'Positive2'; % Z梯度
        else
            twin = 'Negative1'; % XY梯度
        end
    end

    M = numel(CoilPath_serial_outside.(base));
    CoilPath_serial_outside.(twin) = cell(1,M);
    CoilPsi_uniform.(twin) = CoilPsi_uniform.(base);

    for j = 1:M
        data = CoilPath_serial_outside.(base){j}; % [θ, z]
        if startsWith(direction,'z')
            % 对于z方向梯度线圈是z方向对称 phi方向横移pi
            phi_orig = -wrapToPi(data(:,1)); 
            z_shift = -data(:,2); % 对称
            CoilPath_serial_outside.(twin){j} = [phi_orig, z_shift];
        else
            % 对于x和y方向梯度线圈是平移pi
            phi_shifted = wrapToPi(data(:,1) + pi); % 平移 π
            z_orig = data(:,2);
            CoilPath_serial_outside.(twin){j} = [phi_shifted, z_orig];
        end
    end
end

% 现在将组内曲线串联
groups = fieldnames(CoilPath_serial_outside);
for k = 1:numel(groups)
    grp = groups{k};
    curves = CoilPath_serial_outside.(grp);
    CoilPath_serial_outside.(grp) = vertcat(curves{:});  % M 段竖向拼接
end
% z梯度由于是对称过去的 需要将存储顺序反转
if startsWith(direction,'z')
    CoilPath_serial_outside.Positive2 = flipud(CoilPath_serial_outside.Positive2);
    CoilPath_serial_outside.Negative2 = flipud(CoilPath_serial_outside.Negative2);
end

% 作图验证
% plotSpiralDotLine(CoilPath_serial_outside, [direction,'对称构造——四组线圈串联图']);

%% 第八部分 飞线
% 对于XY梯度线圈 取Positive1与Negative1最内层端点做飞线
% 对于Z梯度线圈 取Positive1与Negative2最内层端点做飞线
% 最后将飞线平移Pi即可得到另一条
% 为什么不是处理完飞线再直接平移得到最终线圈组呢
% 是因为线圈不是组内飞线，必须平移/对称后才能得到需要飞线的组

R = struct(); % R矩阵 用于后续柱坐标变换 以及存储飞线的r
CoilPath_serial_all = CoilPath_serial_outside; % 备份 后续汇总
if startsWith(direction,'z')
    pairList = { {'Positive1','Negative2'} ...  % pair-A
               , {'Positive2','Negative1'} }; % pair-B
else
    pairList = { {'Positive1','Negative1'} ...  % pair-A
               , {'Positive2','Negative2'} }; % pair-B
end

% Positive和Negative的尾端平滑翘起数据
dR = 2 * rWire; % 总抬高距离
s = linspace(0,1,Nb).';
g = (exp(beta*s) - 1) ./ (exp(beta) - 1); % 阶跃函数
liftPos = dR * g;
liftNeg = flipud(liftPos);

% 连接线首尾段平滑下降数据
dR_bridge = -gap; % 总降低距离
g = (exp((beta+4)*s) - 1) ./ (exp(beta+4) - 1); % 阶跃函数
liftTail = dR_bridge * g;
liftHead = flipud(liftTail); 

% 首先将待处理线圈组的R都统一为a(圆柱外半径)
for g = 1:numel(pairList)
    for side = 1:2
        grp = pairList{g}{side};
        if ~isfield(R,grp)
            Npts = size(CoilPath_serial_all.(grp),1);
            R.(grp) = a*ones(Npts,1);
        end
    end
end

 for g = 1:numel(pairList)
    posGrp = pairList{g}{1}; % Positive末端
    negGrp = pairList{g}{2}; % Negative首端

    Npos = numel(R.(posGrp));
    idxPos = Npos-Nb+1 : Npos; %  Positive末加liftPos
    R.(posGrp)(idxPos) = R.(posGrp)(idxPos) + liftPos;
    
    idxNeg = 1:Nb; % Negative首加liftNeg
    R.(negGrp)(idxNeg) = R.(negGrp)(idxNeg) + liftNeg;

    % 下面插值生成连接线
    P1 = CoilPath_serial_all.(posGrp)(end,:);
    P2 = CoilPath_serial_all.(negGrp)(1,:);
    
    dphi = angle( exp(1i * (P2(1) - P1(1))) ); % 最短差值
    phiB = linspace(P1(1), P1(1) + dphi, 20*Nt).'; % 插值点数为20倍的匝数
    
    zB   = linspace(P1(2), P2(2), 20*Nt).';
    
    bridge = [wrapToPi(phiB) , zB]; % 拼成插值线

    % 生成插值线的高度
    R_bridge = ones(length(bridge),1) * (2 * rWire + gap + a); % 插值线的高度
    Nb_t = min(Nb, floor(length(R_bridge)/2)); % 确保Nb不会比桥段一半还长，避免首尾区间重叠

    R_bridge(1:Nb_t) = R_bridge(1:Nb_t) + liftHead(1:Nb_t); % 把首/尾Nb个采样点高度降低
    R_bridge(end-Nb_t+1:end) = R_bridge(end-Nb_t+1:end) + liftTail(1:Nb_t);

    % 最后将其拼接在Positive的尾部 并复制至所有线圈组
    R.(posGrp) = [R.(posGrp);R_bridge];
    CoilPath_serial_all.(posGrp) = [CoilPath_serial_all.(posGrp);bridge];
 end

% 作图验证
plotSpiralDotLine(CoilPath_serial_all, [direction,'飞线串联示意图']);

%% 第九部分 串联所有数据点并转为三维坐标
% 这里的拼接顺序与第八部分的PairList顺序一样
% 按照PairA.1 PairA.2 PairB.1 PairB.2来连接
CoilPath_Achievable = struct();
serialPath = []; % 最终 φ-z 串联
serialR    = []; % 最终 R 串联
for p = 1:numel(pairList)
    grp1 = pairList{p}{1};
    grp2 = pairList{p}{2};
    
    for side = 1:2
        if side == 1, grp = grp1; else, grp = grp2; end
        
        pathSeg = CoilPath_serial_all.(grp);
        Rseg = R.(grp);

        serialPath = [serialPath ; pathSeg];
        serialR = [serialR ; Rseg];
    end
end

R   = serialR;
phi = serialPath(:,1);
z   = serialPath(:,2);

x = R .* cos(phi);
y = R .* sin(phi);

Serial = [x , y , z];
% 假设 Serial 是 N×3 double 无首尾闭合 现在删除重复点
SerialClean = removeAndCheckDuplicates(Serial);
SerialLoop = [SerialClean; SerialClean(1,:)];
% 将输出封装为与之前的数据相同的struct-cell结构，方便后续磁场计算
CoilPath_Achievable.Serial = { SerialLoop };


% 作图验证
figure('Name',[direction,'梯度可实现线圈示意图'], ...
       'Position',[550,450,600,600]);

hold on; grid on; axis equal
view(30,30);

% 绘制半透明的线
hLine = plot3( ...
    CoilPath_Achievable.Serial{1}(:,1), ...
    CoilPath_Achievable.Serial{1}(:,2), ...
    CoilPath_Achievable.Serial{1}(:,3), ...
    '-o', ...
    'LineWidth',1.2, ...
    'MarkerSize',3, ...
    'MarkerFaceColor',[0.2 0.5 0.8], ...
    'MarkerEdgeColor','k' ...
);

% 设置透明度（第四个分量就是 alpha）
hLine.Color = [0.2 0.5 0.8 0.5];   

% 起点 / 终点强调
plot3(CoilPath_Achievable.Serial{1}(1,1),  CoilPath_Achievable.Serial{1}(1,2),  CoilPath_Achievable.Serial{1}(1,3), ...
      'go','MarkerSize',9,'LineWidth',1.5,'HandleVisibility','off');
plot3(CoilPath_Achievable.Serial{1}(end,1),CoilPath_Achievable.Serial{1}(end,2),CoilPath_Achievable.Serial{1}(end,3), ...
      'ks','MarkerSize',9,'LineWidth',1.5,'HandleVisibility','off');

xlabel('X (m)');  ylabel('Y (m)');  zlabel('Z (m)');
title([direction,'梯度可实现线圈示意图']);

legend({'串联后的线圈'},'Location','best');
hold off;








end


%% =========================内部函数============================

function Psi = Calculate_Psi(curve, CoilCentroid)
% curve是单曲线
phi = unwrap(curve(:,1));
z   = curve(:,2);

% -------- 质心处理 --------
if nargin >= 2
    phi_c = CoilCentroid(1);
    z_c   = CoilCentroid(2);
else
    phi_c = mean(phi);
    z_c   = mean(z);
end

% -------- 计算 ψ --------
Psi = atan2(z - z_c, phi - phi_c);     % [-π, π]

end


function [phiNew, zNew, psiNew] = resampleByChord(phi,z,psi,N,method)
% 纯弦长等距重采样（适配 ψ 升序或降序）
% 若原 ψ 为降序，函数会自动翻转数据，计算后再翻转回来，
% 保证返回的 psiN 与原 ψ **方向一致**（降序 → 降序，升序 → 升序）

if nargin<5 || isempty(method),  method = 'pchip'; end         % 默认

phi = phi(:);  z = z(:);  psi = psi(:);
assert(N>=2 && mod(N,1)==0,'N 必须为正整数且 ≥2');
dpsi = diff(psi);
isAsc = all(dpsi>0);  isDes = all(dpsi<0);
assert(isAsc||isDes,'ψ 必须严格单调 (升或降)');

flipped = false; % 若 ψ 递减则翻转
if isDes
    phi = flipud(phi);  z = flipud(z);  psi = flipud(psi);
    flipped = true;
end

% 高分辨率样条插值
denseN     = max(1000,2*N);
psiDense   = linspace(psi(1),psi(end),denseN).';
phiDense   = interp1(psi,phi,psiDense,method);
zDense     = interp1(psi,z  ,psiDense,method);

% 弦长累积
dphi = diff(phiDense);   dz = diff(zDense);
ds   = hypot(dphi,dz);               % φ、z 同量纲
s    = [0; cumsum(ds)];              % cumulative chord length

% 弧长等距取点并反求 ψ
sNew   = linspace(0,s(end),N).';
psiNew = interp1(s,psiDense,sNew,'linear');  % 这里保持线性足够

% 样条求 φ、z
phiNew = interp1(psiDense,phiDense,psiNew,method);
zNew   = interp1(psiDense,zDense  ,psiNew,method);

% 若最初 ψ 降序，再翻回
if flipped
    psiNew = flipud(psiNew);  phiNew = flipud(phiNew);  zNew = flipud(zNew);
end


end



% 绘图函数
function plotSpiralDotLine(dataStruct, figTitle)
groups = fieldnames(dataStruct);
colors = lines(numel(groups));

% 新建图窗
figure('Name', figTitle, 'NumberTitle', 'off');
hold on; grid on;

% 注册图例句柄（不绘实际数据，只用于 legend）
for k = 1:numel(groups)
    plot(nan, nan, '-o', ...
         'Color', colors(k,:), ...
         'LineWidth', 1.2, ...
         'MarkerSize', 4, ...
         'DisplayName', groups{k});
end

% 绘制每组数据
for k = 1:numel(groups)
    grpName = groups{k};
    cmap    = colors(k,:);
    parts   = dataStruct.(grpName);
    if ~iscell(parts)
        parts = {parts};
    end

    for j = 1:numel(parts)
        D = parts{j};  % N×2 矩阵：[phi, z]
        phi  = D(:,1);
        zval = D(:,2);

        % 主线＋小实心点（不重复进图例）
        plot(phi, zval, '-o', ...
             'Color',          cmap, ...
             'LineWidth',      0.8, ...
             'MarkerSize',     3, ...
             'MarkerFaceColor',cmap, ...
             'MarkerEdgeColor','none', ...
             'HandleVisibility','off');

        % 起点：绿色实心圆
        plot(phi(1), zval(1), 'o', ...
             'MarkerSize',     8, ...
             'MarkerFaceColor','g', ...
             'MarkerEdgeColor','k', ...
             'HandleVisibility','off');

        % 终点：红色实心方块
        plot(phi(end), zval(end), 's', ...
             'MarkerSize',     8, ...
             'MarkerFaceColor','r', ...
             'MarkerEdgeColor','k', ...
             'HandleVisibility','off');
    end
end

% 坐标标签、标题、图例
xlabel('\phi (rad)');
ylabel('z');
title(figTitle, 'Interpreter', 'none');
legend('show', 'Location', 'bestoutside');
hold off;

end

function SerialClean = removeAndCheckDuplicates(SerialLoop)
% removeAndCheckDuplicates  删除相邻重复点并检测非相邻重复
%
%   SerialClean = removeAndCheckDuplicates(SerialLoop)
%
%   输入：
%     SerialLoop — N×3 double 矩阵（保证无首尾闭合）
%   输出：
%     SerialClean — 去掉所有相邻重复点后的矩阵
%
%   步骤：
%     1) 用 diff 检测并删除相邻重复行
%     2) 用 sortrows＋diff 检测剩余的非相邻重复行，若有则报错

    tol = 1e-8;  % 数值容忍度

    % —— 第一步：删除任意相邻重复点 —— 
    D = abs(diff(SerialLoop,1,1));       % (N-1)×3
    adjDup = all(D < tol, 2);            % 哪些行与下一行“相同”
    keep = [true; ~adjDup];              % 保留第一行，其它行视前一 diff
    SerialClean = SerialLoop(keep, :);

    % —— 第二步：检测非相邻重复 —— 
    % 排序后再 diff，相同的行就会挨在一起
    S2 = sortrows(SerialClean);
    D2 = abs(diff(S2,1,1));
    if any(all(D2 < tol, 2))
        error('检测到非相邻重复点，请检查输入数据！');
    else
        disp('已删除重复点，并未检测到非相邻重复点');
    end
end
