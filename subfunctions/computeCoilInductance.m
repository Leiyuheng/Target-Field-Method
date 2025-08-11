function [L, totalLen] = computeCoilInductance(path, a)
% computeCoilInductance  计算闭合线圈的自感和总路径长度
% 用 Neumann 双积分离散化，i≠j 时按互感项计算
% i=j 时用直线段自感解析修正公式，引入导线半径 a

% 真空磁导率
mu0 = 4*pi*1e-7;

% 如果首尾不重合，自动闭合路径
if ~isequal(path(1,:), path(end,:))
    path = [path; path(1,:)];
end

% 线元数
N = size(path,1) - 1;

% 计算每个线元的向量 Δℓ、中心点 c、长度 li
dl = diff(path,1,1);                      % N×3
c  = (path(1:end-1,:) + path(2:end,:)) / 2; % N×3
li = sqrt(sum(dl.^2,2));                  % N×1

% 总路径长度
totalLen = sum(li);

% 构造互感/自感矩阵 M
M = zeros(N);
for i = 1:N
    for j = 1:N
        if i == j
            % 同线元自感（解析修正，Grover 公式近似）
            M(i,i) = (mu0 * li(i) / (2*pi)) * ...
                ( log(2*li(i)/a) - 1.75 );
        else
            % 互感近似
            Rij = norm( c(i,:) - c(j,:) );
            M(i,j) = (mu0/(4*pi)) * dot(dl(i,:), dl(j,:)) / Rij;
        end
    end
end

% 总自感
L = sum(M,'all');
end
