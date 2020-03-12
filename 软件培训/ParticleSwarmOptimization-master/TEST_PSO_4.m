% TEST  --  PSO  -- Particle Swarm Optimization
%
% Test 4:  Styblinski-Tang function (2D)
%
% 

clc; clear; clear global; figure(400); clf;

%%%% Set up problem

objFun = @StyblinskiTang;   % Minimize this function

xLow = -5*ones(2,1); % lower bound on the search space
xUpp = 5*ones(2,1); % upper bound on the search space
x0 = [0;0];  % initial guess

options.alpha = 0.5;  % weight on current search direction
options.beta = 1.1;   % weight on local best search direction
options.gamma = 1.1;  % weight on global best search direction

options.nPopulation = 20;
options.maxIter = 50;

options.plotFun = @plotStyblinskiTang;  % Plots progress


%%%% Solve
[xBest, fBest, info, dataLog] = PSO(objFun, x0, xLow, xUpp, options);

%%%% Analysis
figure(401); clf;
plotPsoHistory(info);


