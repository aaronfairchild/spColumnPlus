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

doSeperatePlots = 0;
writeExcelFile = 0;

% Load input data
[section, materials, reinforcement, analysis] = inputData();

% Calculate the plastic centroid
[xpc, ypc, section] = findCentroid(section, materials, reinforcement);
section.centroid = [xpc, ypc];

% Define Pn values for isocontours (can be customized)
Pn_values = 0:10000:60000;


fprintf('\n--- Visualizing Pn(c) Function ---\n');

% Ensure section, materials, reinforcement are loaded and centroid is calculated
% (Should already be done by this point in main.m)
if ~isfield(section, 'centroid') || isempty(section.centroid)
    [xpc_plot, ypc_plot, section] = findCentroid(section, materials, reinforcement);
    section.centroid = [xpc_plot, ypc_plot];
    fprintf('Calculated centroid for plotting: [%.3f, %.3f]\n', section.centroid(1), section.centroid(2));
end

% Define a wide range of c values to test
y_max_plot = max(section.vertices(:,2));
y_min_plot = min(section.vertices(:,2));
h_plot = y_max_plot - y_min_plot;
if h_plot < 1e-6, h_plot = 1; end % Avoid zero height if section is flat
% Extend range slightly beyond debug checks, with more points
c_plot_vals = linspace(min(-50, -1.5 * h_plot), max(250, 2.5 * h_plot), 500);
Pn_plot_vals = zeros(size(c_plot_vals));
plot_theta = 0; % Visualize for theta = 0

fprintf('Calculating Pn for c values from %.2f to %.2f for plotting...\n', c_plot_vals(1), c_plot_vals(end));
h_wait = waitbar(0, 'Calculating Pn(c) for plotting...');
compute_error_count = 0;
for i = 1:length(c_plot_vals)
    try
        % Directly call computeSectionCapacity
        [Pn_plot_vals(i), ~, ~] = computeSectionCapacity(c_plot_vals(i), section, materials, reinforcement, plot_theta);
    catch ME_plot
        if compute_error_count < 5 % Report only first few errors
            fprintf('Error calculating Pn for c=%.4f: %s\n', c_plot_vals(i), ME_plot.message);
            if ~isempty(ME_plot.stack)
                fprintf('   (Error in %s, line %d)\n', ME_plot.stack(1).name, ME_plot.stack(1).line);
            end
        elseif compute_error_count == 5
            fprintf('(...further plotting compute errors suppressed...)\n');
        end
        compute_error_count = compute_error_count + 1;
        Pn_plot_vals(i) = NaN; % Mark as invalid
    end
    if mod(i, 20) == 0 || i == length(c_plot_vals)
        waitbar(i/length(c_plot_vals), h_wait, sprintf('Calculating Pn(c)... (c=%.2f)', c_plot_vals(i)));
    end
end
close(h_wait);
if compute_error_count > 0
    fprintf('Total errors during Pn(c) calculation for plot: %d\n', compute_error_count);
end
fprintf('Pn calculation for plot complete.\n');

% Remove NaN values for cleaner plotting if errors occurred
valid_indices = ~isnan(Pn_plot_vals);
c_plot_vals_clean = c_plot_vals(valid_indices);
Pn_plot_vals_clean = Pn_plot_vals(valid_indices);

% Create the plot
figure('Name', 'Pn vs c Visualization', 'Color', 'white');
plot(c_plot_vals_clean, Pn_plot_vals_clean, 'b-', 'LineWidth', 1.5);
hold on;
grid on;
xlabel('Neutral Axis Depth, $c$ (inches from top)');
ylabel('Axial Capacity, $P_n$ (kips)');
title('Behavior of $P_n(c)$ at $\theta = 0$');

% Add horizontal lines for target Pn values that failed
target_Pn_for_plot = [0, 10000, 20000];
colors_plot = lines(length(target_Pn_for_plot));
plot_line_handles = []; % For legend
plot_line_labels = {};
for k = 1:length(target_Pn_for_plot)
    h_line = plot(get(gca, 'XLim'), [target_Pn_for_plot(k), target_Pn_for_plot(k)], '--', 'Color', colors_plot(k,:), 'LineWidth', 1);
    plot_line_handles(end+1) = h_line;
    plot_line_labels{end+1} = sprintf('Target Pn = %.0f kips', target_Pn_for_plot(k));
    % Find intersection point(s) approximately using interpolation
    try
        interp_c = interp1(Pn_plot_vals_clean, c_plot_vals_clean, target_Pn_for_plot(k), 'linear');
        if ~isnan(interp_c)
            plot(interp_c, target_Pn_for_plot(k), 'o', 'MarkerEdgeColor', colors_plot(k,:), 'MarkerFaceColor', colors_plot(k,:), 'MarkerSize', 6);
            text(interp_c, target_Pn_for_plot(k), sprintf('  c ~ %.2f', interp_c), 'Color', colors_plot(k,:), 'VerticalAlignment', 'bottom', 'FontSize', 10);
        end
    catch % Handle cases where interp1 fails (e.g., target outside range)
    end
end

% Indicate the tension limit
h_tension = plot(get(gca, 'XLim'), [5148, 5148], ':k', 'LineWidth', 1);
text(c_plot_vals_clean(1), 5148, ' Max Tension (5148 kips)', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Color', [0.3 0.3 0.3], 'FontSize', 10);
plot_line_handles(end+1) = h_tension;
plot_line_labels{end+1} = 'Max Tension Capacity';

% Indicate approximate locations of top/bottom fibers relative to c=0 axis
y_lims = ylim; % Get current y-limits
plot([0, 0], y_lims, 'k:'); % Line at c=0 (top fiber)
text(0, y_lims(1)+0.02*(y_lims(2)-y_lims(1)),' Top Fiber (c=0)','HorizontalAlignment','left', 'Rotation', 90, 'FontSize', 10);
plot([h_plot, h_plot], y_lims, 'k:'); % Line at c=h (bottom fiber)
text(h_plot, y_lims(1)+0.02*(y_lims(2)-y_lims(1)),' Approx. Bottom Fiber (c=h)','HorizontalAlignment','left', 'Rotation', 90, 'FontSize', 10);

%xlim([-20, 20]);
hold off;
legend(plot_line_handles, plot_line_labels, 'Location', 'best');
% Set tighter y-limits if the range is huge, focusing near targets
min_target = min(target_Pn_for_plot);
max_target = max(target_Pn_for_plot);
buffer = max(2000, 0.2 * (max_target - min_target)); % Add buffer
focus_ylim = [min(min_target - buffer, min(Pn_plot_vals_clean)), max(max_target + buffer, 6000)]; % Include tension limit
% Uncomment next line to zoom y-axis, potentially cutting off high Pn values
% ylim(focus_ylim);

fprintf('Plotting complete. Examine the figure "Pn vs c Visualization".\n');
fprintf('--- End Visualization Block ---\n\n');

% Generate isocontours with 15 degree increments
generateIsocontours(section, materials, reinforcement, Pn_values, 45);

% Analyze and visualize a specific section at angle 0
ihtheta = pi/4; % You can change this to any angle (in rad)
[rotated_section, rotated_reinforcement] = rotateSection(ihtheta, section, reinforcement);
[c, Pn, Mnx, Mny] = findNeutralAxis(analysis.P, rotated_section, materials, rotated_reinforcement, ihtheta);
visualizeSection(rotated_section, rotated_reinforcement, materials, c, Pn, Mnx, Mny);

colors = lines(length(Pn_values)); % generate distinct colors for each iteration

% Create a cell array to store all data for Excel output
outputData = {};
currentRow = 1;

if doSeperatePlots == 1
    for i = 1:length(Pn_values)
        analysis.P = Pn_values(i);

        % Create a single interaction diagram for the current analysis load
        fprintf('\nGenerating detailed interaction diagram for Pn = %.0f kips...\n', analysis.P);

        % Use the modified function that returns c values
        [Mx, My, angles, c_values] = generateInteractionDiagram(analysis.P, section, materials, reinforcement, 45);

        % Convert angles from radians to degrees for output
        theta_degrees = rad2deg(angles);

        % Create a header for this Pn value
        outputData{currentRow, 1} = sprintf('Pn = %d Kips', analysis.P);
        currentRow = currentRow + 1;

        % Add column headers
        outputData{currentRow, 1} = 'No';
        outputData{currentRow, 2} = 'Mx (k-ft)';
        outputData{currentRow, 3} = 'My (k-ft)';
        outputData{currentRow, 4} = 'c (in)';
        outputData{currentRow, 5} = 'theta (degrees)';
        currentRow = currentRow + 1;

        % Add data rows
        for j = 1:length(angles)
            outputData{currentRow, 1} = j;
            outputData{currentRow, 2} = Mx(j);
            outputData{currentRow, 3} = My(j);
            outputData{currentRow, 4} = c_values(j);
            outputData{currentRow, 5} = theta_degrees(j);
            currentRow = currentRow + 1;
        end

        % Add a blank row after each Pn section
        currentRow = currentRow + 1;

        % Plot the single interaction diagram
        figure('Color', 'white');
        plot(Mx, My, 'o-', 'LineWidth', 2, 'Color', colors(i,:));
        grid on;
        title(sprintf('Interaction Diagram for $P_n =$ %.0f kips', analysis.P), 'FontSize', 14, 'Interpreter','latex');
        xlabel('$M_x$ (kip-ft)', 'FontSize', 12, 'Interpreter','latex');
        ylabel('$M_y$ (kip-ft)', 'FontSize', 12, 'Interpreter','latex');
        axis equal;
    end
end

if writeExcelFile == 1
    % Write data to Excel file
    fprintf('\nWriting results to Excel file...\n');
    writecell(outputData, 'InteractionDiagramResults.xlsx');
    fprintf('Results written to InteractionDiagramResults.xlsx\n');
end