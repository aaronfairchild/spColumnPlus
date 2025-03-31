function [c, Pn, Mnx, Mny, Pns] = findNeutralAxis(Pn_target, section, materials, reinforcement, theta)
% FINDNEUTRALAXIS - Finds the neutral axis depth for a target axial load using fzero
%                   with robust bracketing focused on the relevant domain.
%
% Inputs:
%   Pn_target - Target axial load (kips)
%   section - Structure containing concrete section geometry
%   materials - Structure containing material properties
%   reinforcement - Structure containing reinforcement details
%   theta - Angle of neutral axis rotation (radians, optional, defaults to 0)
%
% Outputs:
%   c - Neutral axis depth (in)
%   Pn - Calculated axial capacity for the found c (kips)
%   Mnx - Moment about x-axis for the found c (kip-in)
%   Mny - Moment about y-axis for the found c (kip-in)
%   Pns - Steel contribution to axial capacity (kips) as an array

% Default theta if not provided
if nargin < 5
    theta = 0;
end

% Define the objective function for fzero: the difference
objectiveFunction = @(c_val) computePnDifference(c_val, Pn_target, section, materials, reinforcement, theta);

% --- Determine Search Bounds and Initial Check ---
y_max = max(section.vertices(:,2));
y_min = min(section.vertices(:,2));
section_height = y_max - y_min;
if section_height < 1e-6, section_height = 1; end

% Define broad initial search range (mostly positive c)
c_lower_bound = 1e-6; % Start just above zero to avoid discontinuity issues
c_upper_bound = section_height * 3; % Typically large enough for max compression

% Calculate Pn at the bounds
try
    Pn_at_lower = objectiveFunction(c_lower_bound) + Pn_target;
    Pn_at_upper = objectiveFunction(c_upper_bound) + Pn_target;
catch init_calc_error
    error('Failed to calculate Pn at initial bounds [%.2e, %.2f]: %s', ...
          c_lower_bound, c_upper_bound, init_calc_error.message);
end

% --- Check if Target is within Calculable Range ---
% Estimate Max Tension (assume all steel yields) - More accurate calculation if needed
As_total = sum(reinforcement.area);
Pn_max_tension_est = -As_total * materials.fy; % Negative for tension load convention if used
% Note: Your code calculates Pn=5148 for tension, using compression positive convention.
Pn_tension_limit = As_total * materials.fy; % Approx max tension force (positive value)

if Pn_target > Pn_at_upper * 1.01 % Target likely exceeds max compression capacity (add 1% buffer)
     warning('Pn_target (%.1f) may exceed estimated max compression capacity (Pn(c=%.1f) = %.1f). Result may be inaccurate.', ...
             Pn_target, c_upper_bound, Pn_at_upper);
     % Proceed anyway, fzero might find the edge or fail.
elseif Pn_target < Pn_at_lower && abs(Pn_at_lower - Pn_tension_limit) > 0.01 * Pn_tension_limit
     % Target is below the Pn value calculated at c=epsilon, and that value isn't max tension.
     % This implies the root might be negative c, or near the discontinuity.
     % For Pn_target >= 0, based on the plot, the root should be positive c.
     % This condition might indicate an issue if Pn_at_lower isn't negative as expected for small c.
     if Pn_target >= 0
         warning('Pn(c=%.2e) = %.1f is unexpectedly high for Pn_target = %.1f. Check computeSectionCapacity near c=0.', ...
                 c_lower_bound, Pn_at_lower, Pn_target);
     else
         % Handling negative Pn_target (tension load) would require searching c < 0.
         error('Negative Pn_target (tension) requires searching c < 0, which is not robustly implemented here.');
     end
end


% --- Find a Valid Bracket [c_low, c_high] for fzero ---
c_low = c_lower_bound;
c_high = c_upper_bound;
f_low = Pn_at_lower - Pn_target;
f_high = Pn_at_upper - Pn_target;

% Check if initial bounds already work
if sign(f_low) == sign(f_high)
    %fprintf('Initial bounds [%.2e, %.2f] do not bracket the root. Refining...\n', c_low, c_high); % Debug

    % Expand/Refine the bracket systematically
    % If both are positive, Pn(c_low) is already > Pn_target, need smaller c (closer to 0)
    % If both are negative, Pn(c_high) is < Pn_target, need larger c
    % Based on plot, for Pn_target >=0, expect f_low < 0 and f_high > 0

    if f_low > 0 && f_high > 0 % Both Pn values too high - target requires c closer to 0
        % This case is unexpected for Pn_target >= 0 based on plot. Issue warning.
         warning('Both Pn(c_low) and Pn(c_high) are above Pn_target. Root finding may fail.');
         % Try searching downwards from c_low? Risky due to discontinuity.
         c_high = c_low * 10; % Try a slightly larger value than c_low
         c_low = 1e-7; % Go extremely close to zero
         f_low = objectiveFunction(c_low) + Pn_target - Pn_target;
         f_high = objectiveFunction(c_high) + Pn_target - Pn_target;
         if sign(f_low) == sign(f_high)
             error('Could not establish bracket: Pn seems always > Pn_target for c>0.');
         end

    elseif f_low < 0 && f_high < 0 % Both Pn values too low - need larger c
        found_upper = false;
        for i = 1:10 % Try extending c_high up to 10x initial upper bound
            c_high_new = c_upper_bound * (1.5^i);
            f_high_new = objectiveFunction(c_high_new) + Pn_target - Pn_target;
            if sign(f_high_new) ~= sign(f_low)
                c_high = c_high_new;
                f_high = f_high_new;
                found_upper = true;
                %fprintf('  Found upper bracket: c_high = %.2f\n', c_high); % Debug
                break;
            end
             if abs(f_high_new - f_high) < 1e-3 % Stop if Pn is plateauing
                 warning('Pn appears to plateau below Pn_target. Target may be unreachable.');
                 break; % Exit loop, fzero will likely fail
             end
             f_high = f_high_new; % Update f_high for next plateau check
        end
        if ~found_upper && sign(f_low) == sign(f_high) % Still haven't found bracket
            error('Could not establish bracket: Pn seems always < Pn_target.');
        end
    % else: sign(f_low) ~= sign(f_high) - initial bounds worked OR one of the refinements above worked
    end
end

% --- Call fzero with the identified bracket ---
options = optimset('Display', 'off', 'TolX', 1e-5);
c = NaN; % Initialize
exitflag = -99;

if sign(f_low) ~= sign(f_high)
    try
        %fprintf('Calling fzero with bracket [%.4f, %.4f]\n', c_low, c_high); % Debug
        [c, ~, exitflag] = fzero(objectiveFunction, [c_low, c_high], options);
    catch ME_fzero
        warning('fzero failed with bracket [%.4f, %.4f]: %s', c_low, c_high, ME_fzero.message);
    end
else
     warning('Failed to establish a valid sign-change bracket for fzero. Pn(%.3f)=%.1f, Pn(%.3f)=%.1f, Target=%.1f',...
         c_low, f_low+Pn_target, c_high, f_high+Pn_target, Pn_target);
     % As a last resort, try fzero with a guess (less reliable)
     initial_guess = section_height / 2; % Or maybe (c_low + c_high) / 2
      try
          fprintf('Trying fzero with initial guess: %.4f\n', initial_guess); % Debug
          [c_temp, ~, exitflag_guess] = fzero(objectiveFunction, initial_guess, options);
          if exitflag_guess == 1
              c = c_temp;
              exitflag = exitflag_guess; % Indicate success from guess
              warning('fzero succeeded using an initial guess.');
          end
      catch ME_fzero_guess
          warning('fzero also failed with initial guess: %s', ME_fzero_guess.message);
      end
end

% --- Final Checks and Results ---
if exitflag <= 0 || isnan(c)
    error('fzero failed to converge to a solution for Pn_target = %.2f. Exitflag: %d.', Pn_target, exitflag);
end

% Calculate the final Pn, Mnx, Mny, Pns using the optimized 'c'
[Pn, Mnx, Mny, Pnc_final, Pns] = computeSectionCapacity(c, section, materials, reinforcement, theta);

% Verification and Warning
final_difference = Pn - Pn_target;
% Use a slightly looser tolerance since fzero finds where the function crosses zero,
% which might be slightly off if the function eval itself has minor numerical noise.
tolerance_kips = max(1.0, abs(Pn_target) * 0.01); % 1% or 1 kip

if abs(final_difference) > tolerance_kips
    warning(['Final Pn deviates from target.\n' ...
             'Target Pn = %.3f kips, Achieved Pn = %.3f kips (Difference = %.3f kips).\n' ...
             'Neutral axis depth c = %.4f inches. (fzero exitflag = %d)'], ...
             Pn_target, Pn, final_difference, c, exitflag);
end

end % End of findNeutralAxis function

% --- Helper Function for fzero Objective ---
function diff = computePnDifference(c_val, Pn_target, section, materials, reinforcement, theta)
    % Computes the difference Pn(c) - Pn_target
    % Add safety for c=0 if computeSectionCapacity doesn't handle it perfectly
    if abs(c_val) < 1e-9
        % Based on plot, Pn is negative infinity conceptually, or just negative.
        % To ensure sign change logic works for Pn_target=0, return a large negative diff.
        % Or, rely on computeSectionCapacity to return a sensible negative Pn.
        % Let's assume computeSectionCapacity handles tiny positive c okay.
         c_val = 1e-9; % Use tiny positive value instead of pure zero
    end

    try
        [Pn_calc, ~, ~] = computeSectionCapacity(c_val, section, materials, reinforcement, theta);
        diff = Pn_calc - Pn_target;
    catch ME_compute
        warning('Error in computeSectionCapacity for c=%.4f: %s. Returning NaN.', c_val, ME_compute.message);
        diff = NaN; % Signal error to fzero
    end
    % fprintf('  Helper: c=%.4f, Pn=%.4f, Target=%.2f, Diff=%.4f\n', c_val, Pn_calc, Pn_target, diff); % Detailed Debug
end