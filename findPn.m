function [Pn, Pnc, Pns] = findPn(section, materials, reinforcement, analysis)
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
        
        % Check if bar is in compression or tension
        if y_bar >= c
            % Bar is in compression
            strain = epsilon_cu * (y_bar - c) / (max(section.vertices(:,2)) - c);
            stress = min(strain * Es, fy);
        else
            % Bar is in tension
            strain = epsilon_cu * (c - y_bar) / c;
            stress = max(-strain * Es, -fy);
        end
        
        % Add contribution to steel axial capacity
        Pns = Pns + stress * reinforcement.area(i);
    end
    
    % Total axial capacity
    Pn = Pnc + Pns;
    
    % Calculate error
    err = abs(Pn - Pn_target) / Pn_target;
    
    % Update c based on error
    c = c * (Pn_target / Pn);
    
    % Increment iteration counter
    num_iterations = num_iterations + 1;
end

% If failed to converge, display warning
if num_iterations >= max_iterations
    warning('Failed to converge to target axial load within %d iterations.', max_iterations);
end

end