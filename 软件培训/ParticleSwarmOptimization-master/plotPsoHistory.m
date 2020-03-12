function plotPsoHistory(info)
% plotPsoHistory(info)
%
% Plots the history of the optimization for particle swarm optimization,
% using the info struct returned by PSO
%

% Check if a log scale is appropriate
useLogScale = false;
isPos = [info.F_Global; info.F_Mean; info.F_Best_Mean] > 0;
if sum(~isPos)==0  %then log scale is possible
    val = sort(info.F_Global([1,end]));  %ascending order
    if (val(2)/val(1)) > 50   % Then probably on log scale  
        useLogScale = true;
    end
end

%Plot the function value over time:
subplot(2,2,1); hold on;
plot(info.iter, info.F_Best_Mean);
plot(info.iter, info.F_Mean);
plot(info.iter, info.F_Global);
xlabel('iteration')
ylabel('objective')
title('Objective value')
legend('mean(F\_best)','mean(F)','Global Best')
if useLogScale, set(gca,'YScale','log'); end

%Plot the variance in the function value over time:
subplot(2,2,3); hold on;
plot(info.iter, info.F_Best_Var);
plot(info.iter, info.F_Var);
xlabel('iteration')
ylabel('objective variance')
title('Objective value variance')
legend('var(F\_best)','var(F)')
if useLogScale, set(gca,'YScale','log'); end


%Plot the search variance along each dimension:
subplot(2,2,2); hold on;
nDim = size(info.X_Mean,1);
colorMap = lines(nDim);
legendData = cell(1,nDim);
for i=1:nDim
   plot(info.iter, info.X_Mean(i,:), 'Color',colorMap(i,:), 'LineWidth', 1);
   legendData{i} = ['x' num2str(i)];
end
if nDim < 8, legend(legendData); end
for i=1:nDim
   plot(info.iter, info.X_Best_Mean(i,:), 'Color',colorMap(i,:), 'LineWidth', 2);
   plot(info.iter, info.X_Global(i,:), 'Color',colorMap(i,:), 'LineWidth', 4); 
end
xlabel('iteration')
ylabel('state')
title('search position')

%Plot the search variance along each dimension:
subplot(2,2,4); hold on;
colorMap = lines(nDim);
for i=1:nDim
   plot(info.iter, info.X_Var(i,:), 'Color',colorMap(i,:), 'LineWidth', 1);
end
if nDim < 8, legend(legendData); end
for i=1:nDim
   plot(info.iter, info.X_Best_Var(i,:), 'Color',colorMap(i,:), 'LineWidth', 2); 
end
xlabel('iteration')
ylabel('state variance')
title('search position variance')


end