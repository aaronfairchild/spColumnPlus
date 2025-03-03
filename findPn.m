function [Pn, Pnc, Pns, c] = findPn(section, materials, reinforcement, analysis)
% FINDPN - Calculates axial capacity of reinforced concrete section
% and iterates to find neutral axis depth for target axial load
%
% Inputs:
%   section - Structure containing concrete section geometry
%   materials - Structure containing material properties
%   reinforcement - Structure containing reinforcement details
%   analysis - Structure containing analysis parameters
%
% Outputs:
%   Pn - Total axial capacity (kips)
%   Pnc - Concrete contribution to axial capacity (kips)
%   Pns - Steel contribution to axial capacity (kips)

% Find the extreme compression fiber (maximum y-coordinate)
y_max = max(section.vertices(:,2));

% Get initial guess for c, target load, and tolerance
c = analysis.start_c;
% Use a reasonable range for c measured from the top
c_range = 0:0.1:500;  % c is now measured from top down, so it's normally positive
nC = length(c_range);
Pn_target = analysis.P;
tolP = analysis.P_tolerance;

% Initialize variables for iteration
err = 1.0;  % Initial error
best_err = Inf;
best_c = c;
best_Pn = 0;
best_Pnc = 0;
best_Pns = [];

% Iterate to find c that gives Pn close to Pn_target
for j = 1:nC
    % Calculate current axial capacity for the current value of c
    c = c_range(j);
    c = 30;
    [Pn, Pnc, Pns] = computePnFromC(section, materials, reinforcement, c);

    % Define the residual function f(c) = Pn(c) - Pn_target
    f_val = Pn - Pn_target;

    % Calculate relative error
    err = abs(f_val / Pn_target);

    % Keep track of best solution so far
    if err < best_err
        best_err = err;
        best_c = c;
        best_Pn = Pn;
        best_Pnc = Pnc;
        best_Pns = Pns;
    end
    
    % If we're close enough, exit the loop
    if err <= tolP
        break;
    end
end

% If we didn't find a solution within tolerance, use the best one
if err > tolP
    c = best_c;
    Pn = best_Pn;
    Pnc = best_Pnc;
    Pns = best_Pns;
    fprintf('Warning: Best solution has error of %.4f%% (c = %.2f)\n', best_err*100, best_c);
end

end

function [Pn, Pnc, Pns] = computePnFromC(section, materials, reinforcement, c)
% Helper function to compute axial capacity for a given neutral axis depth c

% Extract material properties
fc = materials.fc;
fy = materials.fy;
Es = materials.Es;
epsilon_cu = materials.epsilon_cu;

% Find the extreme compression fiber (maximum y-coordinate)
y_max = max(section.vertices(:,2));

% Calculate neutral axis position in y-coordinate
na_line = y_max - c;

% Get concrete polygons in compression for current c
polys = findPolys(section, c);

% Calculate concrete contribution to axial capacity
Pnc = 0;
if ~isempty(polys)
    for i = 1:length(polys)
        % Create a polyshape from the polygon vertices
        compPoly = polyshape(polys{i}(:,1), polys{i}(:,2));

        % Calculate area of the polygon
        CArea = area(compPoly);

        % Add contribution to concrete axial capacity
        Pnc = Pnc + 0.85 * fc * CArea;
    end
end

% Calculate steel contribution to axial capacity
Pns = zeros(length(reinforcement.x),1);
for i = 1:length(reinforcement.x)
    % Get coordinates of reinforcement bar
    y_bar = reinforcement.y(i);

    % Calculate distance from neutral axis
    distance = na_line - y_bar;
    
    % Calculate strain in steel
    if c < 1e-6  % Prevent division by zero when c is very small
        strain = -epsilon_cu;  % Assume all in tension for very small c
    else
        strain = epsilon_cu * (distance / c);
    end

    % Calculate stress (limited by yield)
    stress = min(max(strain * Es, -fy), fy);

    % Add contribution to steel axial capacity
    if y_bar > na_line
        Pns(i) = (stress - 0.85*fc) * reinforcement.area(i,1);
    else
        Pns(i) = stress * reinforcement.area(i,1);
    end
end

% Total axial capacity (ensure it's a scalar)
Pn = Pnc + sum(Pns);

% Ensure all outputs are scalar
Pn = Pn(1);
Pnc = Pnc(1);
end