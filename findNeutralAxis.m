function [c, Pn, Mnx, Mny, Pns] = findNeutralAxis(Pn_target, section, materials, reinforcement)
% FINDNEUTRALAXIS - Finds the neutral axis depth for a target axial load using fzero
%
% Inputs:
%   Pn_target - Target axial load (kips)
%   section - Structure containing concrete section geometry
%   materials - Structure containing material properties
%   reinforcement - Structure containing reinforcement details
%
% Outputs:
%   c - Neutral axis depth (in)
%   Pn - Calculated axial capacity (kips)
%   Mnx - Moment about x-axis (kip-in)
%   Mny - Moment about y-axis (kip-in)
%   Pns - Steel contribution to axial capacity (kips) as an array

% Define the objective function
objFun = @(c) getPnDifference(c, Pn_target, section, materials, reinforcement);

% Set options for fzero
options = optimset('Display', 'off');

% Initial bounds for c
c_min = -max(section.vertices(:,2));
c_max = 2*max(section.vertices(:,2));

% Check if the objective function changes sign between c_min and c_max
fmin = objFun(c_min);
fmax = objFun(c_max);

% Try to find a good interval for fzero
if sign(fmin) == sign(fmax)
    % Search for an interval where function changes sign
    c_test = linspace(c_min, c_max, 100);
    f_test = zeros(1, length(c_test));
    
    for i = 1:length(c_test)
        f_test(i) = objFun(c_test(i));
    end
    
    % Find where function changes sign
    sign_changes = find(diff(sign(f_test)));
    
    if isempty(sign_changes)
        % If no sign change, use the point closest to zero
        [~, idx] = min(abs(f_test));
        c_guess = c_test(idx);
    else
        % Use first interval where sign changes
        idx = sign_changes(1);
        c_guess = [c_test(idx), c_test(idx+1)];
    end
else
    % Use the initial bounds
    c_guess = [c_min, c_max];
end

% Use fzero to find the root
try
    c = fzero(objFun, c_guess, options);
catch
    % Fallback to brute force if fzero fails
    [~, idx] = min(abs(f_test));
    c = c_test(idx);
    warning('fzero failed to converge. Using closest approximation.');
end

% Calculate the corresponding axial capacity and moments
[Pn, Mnx, Mny, ~, Pns] = computeSectionCapacity(c, section, materials, reinforcement);
end

function diff = getPnDifference(c, Pn_target, section, materials, reinforcement)
% Helper function to get the difference between calculated and target axial loads
[Pn, ~, ~] = computeSectionCapacity(c, section, materials, reinforcement);
diff = Pn - Pn_target;
end