function paths_out = ProcessPaths(paths_in, close_threshold, match_threshold)
% 后处理路径，完成闭合判定与互补曲线合并

paths_out = {};
used = false(1, length(paths_in));

for i = 1:length(paths_in)
    if used(i), continue; end

    path_i = paths_in{i};
    start_i = path_i(1, :);
    end_i = path_i(end, :);

    % 判断自身是否闭合
    if norm(start_i - end_i) > close_threshold
        % 寻找互补曲线（起点与终点都接近）
        found_match = false;
        for j = i+1:length(paths_in)
            if used(j), continue; end
            path_j = paths_in{j};
            start_j = path_j(1, :);
            end_j = path_j(end, :);

            % 互补曲线判定：起点-起点 和 终点-终点 距离均小于阈值
            if (norm(start_i - start_j) < match_threshold) && (norm(end_i - end_j) < match_threshold)
                % path_j反向后拼接在path_i尾部
                merged_path = [path_i; flipud(path_j(2:end-1,:))];
                used(j) = true;
                found_match = true;
                break;
            elseif (norm(start_i - end_j) < match_threshold) && (norm(end_i - start_j) < match_threshold)
                % path_j正向拼接在path_i尾部
                merged_path = [path_i; path_j(2:end-1,:)];
                used(j) = true;
                found_match = true;
                break;
            end
        end

        if found_match
            % 合并后检查首尾是否闭合
            if norm(merged_path(1,:) - merged_path(end,:)) < close_threshold
                merged_path(end,:) = merged_path(1,:);
            end
            paths_out{end+1} = merged_path;
        else
            % 无互补曲线，保留原始
            paths_out{end+1} = path_i;
        end
    else
        % 已闭合，直接加入
        paths_out{end+1} = path_i;
    end

    used(i) = true;
end
end