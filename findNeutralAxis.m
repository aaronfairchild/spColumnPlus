function [c, Pn, Mnx, Mny, Pns] = findNeutralAxis(Pn_target, section, materials, reinforcement, theta)
% FINDNEUTRALAXIS - Finds the neutral axis depth for a target axial load using fzero
%
% Inputs:
%   Pn_target - Target axial load (kips)
%   section - Structure containing concrete section geometry
%   materials - Structure containing material properties
%   reinforcement - Structure containing reinforcement details
%   theta - Angle of neutral axis rotation (optional)
%
% Outputs:
%   c - Neutral axis depth (in)
%   Pn - Calculated axial capacity (kips)
%   Mnx - Moment about x-axis (kip-in)
%   Mny - Moment about y-axis (kip-in)
%   Pns - Steel contribution to axial capacity (kips) as an array

% Default theta if not provided
if nargin < 5
    theta = 0;
end

% Special case for pure moment (Pn = 0 or very small)
if abs(Pn_target) < 1e-6
    [c, Pn, Mnx, Mny, Pns] = findNeutralAxisPureMoment(section, materials, reinforcement, theta);
    return;
end

% Define the objective function
objFun = @(c) getPnDifference(c, Pn_target, section, materials, reinforcement, theta);

% Set options for fzero
options = optimset('Display', 'off', 'TolX', 1e-4);

% Initial bounds for c
y_max = max(section.vertices(:,2));
y_min = min(section.vertices(:,2));
section_height = y_max - y_min;
c_min = -2*section_height; % Allow negative c values
c_max = 2*section_height;

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
        
        % If we're still far from target, try a denser search
        if abs(f_test(idx)) > abs(Pn_target) * 0.1
            c_fine = linspace(max(c_min, c_test(idx) - section_height/10),... 
                             min(c_max, c_test(idx) + section_height/10), 100);
            f_fine = zeros(1, length(c_fine));
            
            for i = 1:length(c_fine)
                f_fine(i) = objFun(c_fine(i));
            end
            
            [~, idx_fine] = min(abs(f_fine));
            c_guess = c_fine(idx_fine);
        end
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
catch ME
    %warning('fzero failed with error: %s', ME.message);
    
    % Try with different starting points
    try
        % Try with a small positive value
        c = fzero(objFun, 0.1 * section_height, options);
    catch
        % Fallback to brute force if fzero fails
        if exist('f_test', 'var')
            [~, idx] = min(abs(f_test));
            c = c_test(idx);
        else
            % Create a test grid if we don't have one yet
            c_test = linspace(c_min, c_max, 200);
            f_test = zeros(1, length(c_test));
            
            for i = 1:length(c_test)
                f_test(i) = objFun(c_test(i));
            end
            
            [~, idx] = min(abs(f_test));
            c = c_test(idx);
        end
        warning('fzero failed to converge. Using closest approximation: c = %.4f', c);
    end
end

% Calculate the corresponding axial capacity and moments
[Pn, Mnx, Mny, ~, Pns] = computeSectionCapacity(c, section, materials, reinforcement, theta);

% Verify that the solution is reasonable
if abs(Pn - Pn_target) > abs(Pn_target) * 0.05
    warning(['Solution may not be accurate. Target Pn = %.2f, Achieved Pn = %.2f. ' ...
             'Difference = %.2f kips (%.1f%%)'], ...
             Pn_target, Pn, Pn - Pn_target, 100 * abs(Pn - Pn_target) / abs(Pn_target));
    
    % If inaccurate, try pure moment approach with Pn constraint
    if abs(Pn_target) < 0.1 * max(abs(fmin), abs(fmax))
        fprintf('Attempting pure moment approach with Pn constraint...\n');
        [c_alt, Pn_alt, Mnx_alt, Mny_alt, Pns_alt] = findNeutralAxisPureMoment(section, materials, reinforcement, theta);
        
        % If the pure moment approach gets closer to target, use that instead
        if abs(Pn_alt - Pn_target) < abs(Pn - Pn_target)
            c = c_alt;
            Pn = Pn_alt;
            Mnx = Mnx_alt;
            Mny = Mny_alt;
            Pns = Pns_alt;
            fprintf('Using pure moment approach result: c = %.3f\n', c);
        end
    end
end
end

function diff = getPnDifference(c, Pn_target, section, materials, reinforcement, theta)
% Helper function to get the difference between calculated and target axial loads
[Pn, ~, ~] = computeSectionCapacity(c, section, materials, reinforcement, theta);
diff = Pn - Pn_target;
end