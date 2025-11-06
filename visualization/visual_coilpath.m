function visual_coilpath(coilPaths_x, coilPaths_y, coilPaths_z)
% 用于导线路径部分可视化

figure("Name",'导线路径示意','Position',[500,400,1300,600]);
tiledlayout(1,3,'TileSpacing','compact','Padding','compact'); 

coilPathsList = {coilPaths_x, coilPaths_y, coilPaths_z};
directionList = {'x','y','z'}; % 方向名称，用于title

for k = 1:3
    nexttile;
    hold on;

    coilPaths = coilPathsList{k}; 
    direction = directionList{k}; 

    % --- Ψ > 0 ---
    for i = 1:length(coilPaths.Positive)
        path = coilPaths.Positive{i};
        h1 = plot3(path(:,1), path(:,2), path(:,3), ...
              'Color',[0.161,0.220,0.565], 'LineWidth',1.2);
        % 起点、终点标记
        plot3(path(1,1),path(1,2),path(1,3),'go', ...
              'MarkerSize',8,'LineWidth',1.5, ...
              'HandleVisibility','off');
        plot3(path(20,1),path(20,2),path(20,3),'ks', ...
              'MarkerSize',8,'LineWidth',1.5, ...
              'HandleVisibility','off');
    end

    % --- Ψ < 0 ---
    for i = 1:length(coilPaths.Negative)
        path = coilPaths.Negative{i};
         h2 = plot3(path(:,1), path(:,2), path(:,3), ...
              'Color',[0.749,0.114,0.176], 'LineWidth',1.2);   

        % 起点、终点标记
        plot3(path(1,1),path(1,2),path(1,3),'go', ...
              'MarkerSize',8,'LineWidth',1.5, ...
              'HandleVisibility','off');
        plot3(path(20,1),path(20,2),path(20,3),'ks', ...
              'MarkerSize',8,'LineWidth',1.5, ...
              'HandleVisibility','off');
    end

    xlabel('X (m)');
    ylabel('Y (m)');
    zlabel('Z (m)');
    title([ direction, '方向梯度线圈']);
    legend([h1, h2], {'\Psi>0','\Psi<0'}, 'Location','northeast', 'Interpreter','tex');
    axis equal;
    grid on;
    view(30,30);
    hold off;
end


end