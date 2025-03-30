% Main script for Column Analysis
% Updated: March 29, 2025
clear; clc; delete(findall(0, 'Type', 'figure')); % gets rid of all open figures

set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');
set(0, 'DefaultAxesFontSize', 14);
set(0, 'DefaultTextFontSize', 14);
set(0, 'DefaultAxesTitleFontSizeMultiplier', 1.2);
set(groot, 'DefaultAxesFontSize', 14);
set(groot, 'DefaultTextFontSize', 14);

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

colors = lines(length(Pn_values)); % generate distinct colors for each iteration

for i = 1:length(Pn_values)
    analysis.P = Pn_values(i);

    % Create a single interaction diagram for the current analysis load
    fprintf('\nGenerating detailed interaction diagram for Pn = %.0f kips...\n', analysis.P);
    [Mx, My, angles] = generateInteractionDiagram(analysis.P, section, materials, reinforcement, 45);

    % Plot the single interaction diagram
    figure('Color', 'white');
    plot(Mx, My, 'o-', 'LineWidth', 2, 'Color', colors(i,:));
    grid on;
    title(sprintf('Interaction Diagram for $P_n =$ %.0f kips', analysis.P), 'FontSize', 14, 'Interpreter','latex');
    xlabel('$M_x$ (kip-ft)', 'FontSize', 12, 'Interpreter','latex');
    ylabel('$M_y$ (kip-ft)', 'FontSize', 12, 'Interpreter','latex');
    axis equal;
end