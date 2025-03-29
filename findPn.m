function [Pn, Pnc, Pns, c] = findPn(section, materials, reinforcement, analysis)
% FINDPN - Calculates axial capacity of reinforced concrete section
% and uses MATLAB's built-in fzero to find neutral axis depth for target axial load
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
%   c - Neutral axis depth (in)

% Get target load
Pn_target = analysis.P;

% Define the residual function: f(c) = Pn(c) - Pn_target
residual_function = @(c_val) computePnResidual(section, materials, reinforcement, c_val, Pn_target);

% Set options for fzero
options = optimset('Display', 'off', 'TolX', analysis.P_tolerance);

% Try using fzero with various approaches
try
    % First try with a bracket, which is most reliable if we have a sign change
    c = fzero(residual_function, [analysis.start_c, analysis.end_c], options);
catch ME
    % If that fails, try with an initial guess
    warning('fzero with bracket failed: %s. Trying with initial guess.', ME.message);
    try
        c = fzero(residual_function, (analysis.start_c + analysis.end_c)/2, options);
    catch ME2
        % If all else fails, use a grid search
        warning('fzero with initial guess failed: %s. Using grid search.', ME2.message);
        
        % Grid search approach
        c_values = linspace(analysis.start_c, analysis.end_c, 1000);
        residuals = zeros(size(c_values));
        
        for i = 1:length(c_values)
            residuals(i) = residual_function(c_values(i));
        end
        
        [~, idx] = min(abs(residuals));
        c = c_values(idx);
    end
end

% Calculate final Pn, Pnc, and Pns using the found c value
[Pn, Pnc, Pns] = computePnFromC(section, materials, reinforcement, c);

end

function residual = computePnResidual(section, materials, reinforcement, c, Pn_target)
% Compute the residual for fzero
[Pn, ~, ~] = computePnFromC(section, materials, reinforcement, c);
residual = Pn - Pn_target;
end

function [Pn, Pnc, Pns] = computePnFromC(section, materials, reinforcement, c)
% Helper function to compute axial capacity for a given neutral axis depth c

% Extract material properties
fc = materials.fc;
fy = materials.fy;
Es = materials.Es;
epsilon_cu = materials.epsilon_cu;
beta1 = materials.beta1;  % Extract beta1 for Whitney stress block
a = c*beta1;

% Get concrete polygons in compression for current c, using the Whitney stress block
polys = findPolys(section, a);  % Use 'a' instead of 'c' for compression zone

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
y_max = max(section.vertices(:,2));
for i = 1:length(reinforcement.x)
    % Get coordinates of reinforcement bar
    y_bar = reinforcement.y(i);

    % Calculate strain in steel
    strain = epsilon_cu * (c - (y_max - y_bar)) / c; % Proper strain calculation

    % Calculate stress (limited by yield)
    stress = min(max(strain * Es, -fy), fy);

    % Add contribution to steel axial capacity
    if y_bar > (y_max - a)
        Pns(i) = (stress - 0.85*fc)* reinforcement.area(i,1);
    else
        Pns(i) = stress * reinforcement.area(i,1);
    end
end

% Total axial capacity
Pn = Pnc + sum(Pns);

% Ensure all outputs are scalar
Pn = Pn(1);
Pnc = Pnc(1);
end