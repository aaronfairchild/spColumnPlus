function visualizeSection(section, reinforcement, materials, c, Pn, Mnx, Mny)
% VISUALIZESECTION - Visualizes a reinforced concrete section and its moment capacity
%
% Inputs:
%   section - Structure containing concrete section geometry
%   reinforcement - Structure containing reinforcement details
%   materials - Structure containing material properties
%   c - Neutral axis depth (in)
%   Pn - Axial capacity (kips)
%   Mnx - Moment about x-axis (kip-in)
%   Mny - Moment about y-axis (kip-in)

% Calculate a (depth of compression block)
a = materials.beta1 * c;

% Find compression zone polygons
polys = findPolys(section, a);

% Visualize the section
drawSection(section, reinforcement, c, polys);

% Calculate normalized moments
Mx_norm = Mnx / 12 / 35000;
My_norm = Mny / 12 / 35000;

% Add additional information to the plot
title(sprintf('Section Analysis: P_n = %.0f kips, M_x = %.5f, M_y = %.5f (normalized)', ...
    Pn, Mx_norm, My_norm), 'FontSize', 12);
end