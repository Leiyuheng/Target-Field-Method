function M = computeMutualInductance(path1, path2, a1, a2, Nturns1, Nturns2)
% computeMutualInductance  计算两个闭合线圈之间的互感（H）
%   M = computeMutualInductance(path1, path2, a1, a2)
%   path1, path2: Nx3 和 Mx3 的点坐标序列（若首尾不重合，函数会自动闭合）
%   a1, a2:    导线半径（m），标量。可不提供，默认 1e-4 m。
%   Nturns1,Nturns2: 匝数（可选，默认 1）
%
% 返回：
%   M: 两绕组之间的互感（亨，H）
%
% 实现说明：
%   - 使用线元中心点与线元矢量的离散化形式（Neumann 双和）
%   - 为避免距离为0的奇点，用 sqrt(r^2 + a_eff^2) 做正则化，其中 a_eff = sqrt(a1^2 + a2^2)

if nargin < 3 || isempty(a1), a1 = 1e-4; end
if nargin < 4 || isempty(a2), a2 = 1e-4; end
if nargin < 5 || isempty(Nturns1), Nturns1 = 1; end
if nargin < 6 || isempty(Nturns2), Nturns2 = 1; end

mu0 = 4*pi*1e-7;

% 自动闭合路径（若首尾不重合）
if ~isequal(path1(1,:), path1(end,:))
    path1 = [path1; path1(1,:)];
end
if ~isequal(path2(1,:), path2(end,:))
    path2 = [path2; path2(1,:)];
end

% 线元与中心点
dl1 = diff(path1,1,1);    % n1 x 3
c1  = (path1(1:end-1,:) + path1(2:end,:)) / 2; % n1 x 3
l1  = sqrt(sum(dl1.^2,2));                    % n1 x 1

dl2 = diff(path2,1,1);    % n2 x 3
c2  = (path2(1:end-1,:) + path2(2:end,:)) / 2; % n2 x 3
l2  = sqrt(sum(dl2.^2,2));                    % n2 x 1

n1 = size(dl1,1);
n2 = size(dl2,1);

% 有效正则化半径（防止分母为0，也近似考虑导线半径）
a_eff = sqrt(a1^2 + a2^2);

% 计算 dot(dl1_i, dl2_j) 的矩阵（n1 x n2）
% dl1 * dl2' 利用矩阵乘法（每行为线元向量）
D = dl1 * dl2.';  % n1 x n2

% 计算中心点之间距离矩阵（n1 x n2）
% 利用广播构造差矢量并求范数
C1 = reshape(c1, [n1, 1, 3]);  % n1 x 1 x 3
C2 = reshape(c2, [1, n2, 3]);  % 1 x n2 x 3
diffs = C1 - C2;               % n1 x n2 x 3
dist = sqrt( sum(diffs.^2, 3) ); % n1 x n2

% 正则化距离
dist_reg = sqrt(dist.^2 + a_eff^2);

% 双和并乘上常数
M_raw = sum( D(:) ./ dist_reg(:) );   % scalar

M = mu0/(4*pi) * M_raw;

% 考虑匝数
M = M * Nturns1 * Nturns2;

end
