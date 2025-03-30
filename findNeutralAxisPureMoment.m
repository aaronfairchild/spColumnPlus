function [c, Pn, Mnx, Mny, Pns] = findNeutralAxisPureMoment(section, materials, reinforcement, theta)
% FINDNEUTRALAXISPUREMOMENT - Specialized function for finding neutral axis for pure moment (Pn = 0)
%
% Inputs:
%   section - Structure containing concrete section geometry
%   materials - Structure containing material properties
%   reinforcement - Structure containing reinforcement details
%   theta - Angle of the neutral axis rotation (optional, defaults to 0)
%
% Outputs:
%   c - Neutral axis depth (in)
%   Pn - Calculated axial capacity (should be approximately 0)
%   Mnx - Moment about x-axis (kip-in)
%   Mny - Moment about y-axis (kip-in)
%   Pns - Steel contribution to axial capacity (kips) as an array

% Default theta if not provided
if nargin < 4
    theta = 0;
end

% Get section dimensions
y_max = max(section.vertices(:,2));
y_min = min(section.vertices(:,2));
section_height = y_max - y_min;

% Define a range of c values to test
% For pure moment, c is typically around section height/2
c_values = linspace(0.005*section_height, 0.99*section_height, 5000);

% Initialize arrays for results
Pn_values = zeros(size(c_values));
Mnx_values = zeros(size(c_values));
Mny_values = zeros(size(c_values));
Pns_values = cell(size(c_values));

% Calculate P and M for each c value
for i = 1:length(c_values)
    c_test = c_values(i);
    [Pn_values(i), Mnx_values(i), Mny_values(i), ~, Pns_values{i}] = computeSectionCapacity(c_test, section, materials, reinforcement, theta);
end

% Identify c values that give Pn close to zero
Pn_abs = abs(Pn_values);
zero_indices = find(Pn_abs < max(0.001*max(abs(Pn_values)), 0.001)); % Threshold for "close to zero"

% If no values are close enough to zero, find the minimum
if isempty(zero_indices)
    [~, min_idx] = min(Pn_abs);
    zero_indices = min_idx;
end

% Among the c values that give Pn ≈ 0, find the one that maximizes the resultant moment
M_resultant = sqrt(Mnx_values.^2 + Mny_values.^2);
M_subset = M_resultant(zero_indices);
[max_moment, max_idx] = max(M_subset);

% Get the best c value
c_idx = zero_indices(max_idx);
c = c_values(c_idx);

% Calculate the final values using the selected c
[Pn, Mnx, Mny, ~, Pns] = computeSectionCapacity(c, section, materials, reinforcement, theta);

% If the moment is very small, try c values closer to zero
if max_moment < 1e-6 && c > 0.1*section_height
    % Try smaller c values
    c_small = linspace(0.001*section_height, 0.1*section_height, 200);
    for i = 1:length(c_small)
        [Pn_test, Mnx_test, Mny_test, ~, Pns_test] = computeSectionCapacity(c_small(i), section, materials, reinforcement, theta);
        M_test = sqrt(Mnx_test^2 + Mny_test^2);
        if M_test > max_moment && abs(Pn_test) < 0.1
            c = c_small(i);
            Pn = Pn_test;
            Mnx = Mnx_test;
            Mny = Mny_test;
            Pns = Pns_test;
            max_moment = M_test;
        end
    end
end
end