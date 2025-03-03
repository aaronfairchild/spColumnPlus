function [Mnx, Mny] = findMoments(reinforcement, section, materials, Pns, c)
% FINDMOMENTS - Calculates moment capacity of reinforced concrete section
%
% This function calculates the moment capacity by:
% 1. Summing compression and tension forces separately
% 2. Finding centroid of each force group
% 3. Checking equilibrium between compression and tension
% 4. Calculating moment as the product of force and distance between centroids
% 5. Breaking moment into x and y components
%
% Inputs:
%   reinforcement - Structure containing reinforcement details
%   section - Structure containing concrete section geometry
%   materials - Structure containing material properties
%   Pns - Force in each reinforcement bar
%   c - Neutral axis depth from top
%
% Outputs:
%   Mnx - Moment capacity about x-axis
%   Mny - Moment capacity about y-axis

% Get section properties
y_max = max(section.vertices(:,2));
a = materials.beta1 * c;

% Find compression zone using the Whitney stress block (depth = a)
comp_polys = findPolys(section, a);

% Initialize compression and tension force sums and moment arms
C_total = 0;  % Total compression force
T_total = 0;  % Total tension force
C_x_moment = 0;  % Sum of compression force * x coordinate
C_y_moment = 0;  % Sum of compression force * y coordinate
T_x_moment = 0;  % Sum of tension force * x coordinate
T_y_moment = 0;  % Sum of tension force * y coordinate

% 1. Calculate compression force and centroid from concrete
for i = 1:length(comp_polys)
    poly = polyshape(comp_polys{i}(:,1), comp_polys{i}(:,2));
    A_comp = area(poly);
    [Cx, Cy] = centroid(poly);
    
    F_concrete = 0.85 * materials.fc * A_comp;
    
    C_total = C_total + F_concrete;
    C_x_moment = C_x_moment + (F_concrete * Cx);
    C_y_moment = C_y_moment + (F_concrete * Cy);
end

% 2. Process each reinforcement bar
for i = 1:length(reinforcement.x)
    x_bar = reinforcement.x(i);
    y_bar = reinforcement.y(i);
    
    % Determine if bar is in compression or tension zone
    if y_bar > (y_max - a)
        % Bar is in compression zone
        C_total = C_total + Pns(i);
        C_x_moment = C_x_moment + (Pns(i) * x_bar);
        C_y_moment = C_y_moment + (Pns(i) * y_bar);
    else
        % Bar is in tension zone
        T_total = T_total + abs(Pns(i));
        T_x_moment = T_x_moment + (Pns(i) * x_bar);
        T_y_moment = T_y_moment + (Pns(i) * y_bar);
    end
end

% Calculate centroids of compression and tension forces
if C_total > 0
    C_x_centroid = C_x_moment / C_total;
    C_y_centroid = C_y_moment / C_total;
else
    C_x_centroid = 0;
    C_y_centroid = 0;
end

if T_total > 0
    T_x_centroid = T_x_moment / T_total;
    T_y_centroid = T_y_moment / T_total;
else
    T_x_centroid = 0;
    T_y_centroid = 0;
end

% 3. Check equilibrium
equilibrium_error = abs(C_total - T_total);
if equilibrium_error > 1e-6
    fprintf('Force equilibrium check: C = %.2f, T = %.2f, Diff = %.2f\n', ...
        C_total, T_total, equilibrium_error);
end

% Use the minimum of the two forces for moment calculation (to ensure equilibrium)
F = min(C_total, T_total);

% 4. Calculate distance between centroids (lever arm)
dx = T_x_centroid - C_x_centroid;
dy = T_y_centroid - C_y_centroid;

% 5. Calculate moment components
Mnx = F * dy;  % Moment about x-axis (due to vertical distance)
Mny = F * dx;  % Moment about y-axis (due to horizontal distance)

end