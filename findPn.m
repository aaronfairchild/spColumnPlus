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

% Get initial guess for c, target load, and tolerance
c = analysis.start_c;
c_range = -100:0.1:250;
nC = length(c_range);
Pn_target = analysis.P;
tolP = analysis.P_tolerance;

% Initialize variables for iteration
err = 1.0;  % Initial error
max_iterations = 10000;  % Prevent infinite loop
num_iterations = 0;

% Iterate to find c that gives Pn close to Pn_target
for j = 1:nC
    % Calculate current axial capacity for the current value of c
    c = c_range(j);
    c = 173.5398;
    [Pn, Pnc, Pns] = computePnFromC(section, materials, reinforcement, c);

    % Define the residual function f(c) = Pn(c) - Pn_target
    f_val = Pn - Pn_target;

    % Calculate relative error
    err = abs(f_val / Pn_target);

    % If we're close enough, exit the loop
    if err <= tolP
        break;
    end

    % Finite difference approximation for derivative
    delta = 1e-8;
    c_plus_delta = c + delta; % Ensure this is a scalar
    [Pn_delta, ~, ~] = computePnFromC(section, materials, reinforcement, c_plus_delta);
    f_prime = (Pn_delta - Pn) / delta;

    % Newton-Raphson update
    % Check if derivative is too small to avoid division by zero
    if abs(f_prime) < 1e-8
        % Fallback to simple proportional update if derivative is too small
        c_new = c * (Pn_target / max(abs(Pn), 1e-8));
    else
        c_new = c - f_val / f_prime;
    end

    % Ensure c stays within reasonable bounds
    c_new = max(c_new, -max(abs(section.vertices(:,2)))); % Lower bound
    c_new = min(c_new, 2*max(section.vertices(:,2))); % Upper bound

    % Ensure c is a scalar (take first element if somehow became an array)
    c = c_new(1);

    % Increment iteration counter
    num_iterations = num_iterations + 1;
end

% If failed to converge, display warning
if num_iterations >= max_iterations
    %warning('Failed to converge to target axial load within %d iterations.', max_iterations);
end

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

% Total axial capacity (ensure it's a scalar)
Pn = Pnc + sum(Pns);

% Ensure all outputs are scalar
Pn = Pn(1);
Pnc = Pnc(1);
end