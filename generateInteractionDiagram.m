function [Mx, My, angles] = generateInteractionDiagram(Pn_target, section, materials, reinforcement, angle_increment)
% GENERATEINTERACTIONDIAGRAM - Generates an interaction diagram for a given axial load
%
% Inputs:
%   Pn_target - Target axial load (kips)
%   section - Structure containing concrete section geometry
%   materials - Structure containing material properties
%   reinforcement - Structure containing reinforcement details
%   angle_increment - Angle increment for the diagram (degrees, default: 15)
%
% Outputs:
%   Mx - Normalized moment about x-axis (ft-kips / 35000)
%   My - Normalized moment about y-axis (ft-kips / 35000)
%   angles - Angles used for the diagram (radians)

% Set default angle increment if not provided
if nargin < 5
    angle_increment = 15;
end

% Define angles for the diagram
angles = deg2rad(0:angle_increment:360);
num_angles = length(angles);

% Initialize arrays for moments
Mx = zeros(1, num_angles);
My = zeros(1, num_angles);

% Store original section and reinforcement
original_section = section;
original_reinforcement = reinforcement;

% Generate the interaction diagram
for i = 1:num_angles
    % Get a fresh copy of the section and reinforcement
    section = original_section;
    reinforcement = original_reinforcement;
    
    % Rotate the section
    theta = angles(i);
    [section, reinforcement] = rotateSection(theta, section, reinforcement);
    
    % Find the neutral axis depth for the target axial load
    [c, ~, Mnx, Mny] = findNeutralAxis(Pn_target, section, materials, reinforcement, theta);
    
    % Convert moments to ft-kips and normalize as in the original code
    Mx(i) = Mnx / 12;
    My(i) = Mny / 12;
    
    fprintf('C: %3.3f, Angle: %6.1f°, Mx: %8.5f, My: %8.5f\n', c, rad2deg(theta), Mx(i), My(i));
end
end