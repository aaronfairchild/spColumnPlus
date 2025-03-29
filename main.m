% Main script for Column Analysis
% Updated: March 29, 2025
clear; clc; delete(findall(0, 'Type', 'figure')); % gets rid of all open figures

% Load input data
[section, materials, reinforcement, analysis] = inputData();

% Calculate the plastic centroid
[xpc, ypc, section] = findCentroid(section, materials, reinforcement);
section.centroid = [xpc, ypc];

% Define Pn values for isocontours (can be customized)
Pn_values = 0:10000:60000;

% Generate isocontours with 15 degree increments
generateIsocontours(section, materials, reinforcement, Pn_values, 45);

% Analyze and visualize a specific section at angle 0
ihtheta = pi/4; % You can change this to any angle (in rad)
[rotated_section, rotated_reinforcement] = rotateSection(ihtheta, section, reinforcement);
[c, Pn, Mnx, Mny] = findNeutralAxis(analysis.P, rotated_section, materials, rotated_reinforcement, ihtheta);
visualizeSection(rotated_section, rotated_reinforcement, materials, c, Pn, Mnx, Mny);

% Create a single interaction diagram for the current analysis load
fprintf('\nGenerating detailed interaction diagram for Pn = %.0f kips...\n', analysis.P);
[Mx, My, angles] = generateInteractionDiagram(analysis.P, section, materials, reinforcement, 45);

% Plot the single interaction diagram
figure('Color', 'white');
plot(Mx, My, 'o-', 'LineWidth', 2, 'Color', 'b');
grid on;
title(sprintf('Interaction Diagram for P_n = %.0f kips', analysis.P), 'FontSize', 14);
xlabel('M_x (ft-kips)', 'FontSize', 12);
ylabel('M_y (ft-kips)', 'FontSize', 12);
axis equal;