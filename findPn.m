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

% Extract material properties
fc = materials.fc;                % Concrete compressive strength (ksi)
fy = materials.fy;                % Steel yield strength (ksi)
Es = materials.Es;                % Steel elastic modulus (ksi)
epsilon_cu = materials.epsilon_cu;  % Ultimate concrete strain

% Get initial guess for c, target load, and tolerance
c = analysis.start_c;
Pn_target = analysis.P;
tolP = analysis.P_tolerance;

% Initialize variables for iteration
err = 1.0;  % Initial error
max_iterations = 100;  % Prevent infinite loop
num_iterations = 0;

% Iterate to find c that gives Pn close to Pn_target
while err > tolP && num_iterations < max_iterations
    % Calculate current axial capacity for the current value of c
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
        c_new = c + f_val / f_prime;
    end
    
    % Ensure c is a scalar (take first element if somehow became an array)
    c = c_new(1);
    
    % Increment iteration counter
    num_iterations = num_iterations + 1;
    fprintf('Pn: %6.3f\n',Pn);
    fprintf('c: %6.3f\n',c);
    fprintf('err: %6.3f\n',err);

end

% If failed to converge, display warning
if num_iterations >= max_iterations
    warning('Failed to converge to target axial load within %d iterations.', max_iterations);
end

end

function [Pn, Pnc, Pns] = computePnFromC(section, materials, reinforcement, c)
% Helper function to compute axial capacity for a given neutral axis depth c
    
    % Extract material properties
    fc = materials.fc;
    fy = materials.fy;
    Es = materials.Es;
    epsilon_cu = materials.epsilon_cu;

    y_max = max(section.vertices(:,2));
    
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
    Pns = 0;
    for i = 1:length(reinforcement.x)
        % Get coordinates of reinforcement bar
        
        y_bar = reinforcement.y(i);
        d = y_max-y_bar;
        
        % Check if bar is in compression or tension
        if d <= c
            % Bar is in compression
            strain = epsilon_cu * (d - c) / (c);
            stress = min(strain * Es, fy);
        else
            % Bar is in tension
            strain = epsilon_cu * (c - d) / d;
            stress = max(-strain * Es, -fy);
        end
        
        % Add contribution to steel axial capacity
        Pns = Pns + stress * reinforcement.area(i);
    end
    
    % Total axial capacity (ensure it's a scalar)
    Pn = Pnc + Pns;
    
    % Ensure all outputs are scalar
    Pn = Pn(1);
    Pnc = Pnc(1);
    Pns = Pns(1);
end