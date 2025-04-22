% meridianPlot
clear; clc; delete(findall(0, 'Type', 'figure')); % gets rid of all open figures

baseFontSize = 22;
titleFontSizeMultiplier = 1.1;

% Set up LaTeX formatting
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');

% Set NEW Default Font Sizes
set(0, 'DefaultAxesFontSize', baseFontSize);
set(0, 'DefaultTextFontSize', baseFontSize);
set(0, 'DefaultLegendFontSize', baseFontSize); % Explicitly set legend default
set(0, 'DefaultAxesTitleFontSizeMultiplier', titleFontSizeMultiplier);

% Also set for groot (sometimes needed)
set(groot, 'DefaultAxesFontSize', baseFontSize);
set(groot, 'DefaultTextFontSize', baseFontSize);
set(groot, 'DefaultLegendFontSize', baseFontSize);
set(groot, 'DefaultAxesTitleFontSizeMultiplier', titleFontSizeMultiplier);

% Create output directories for better organization
csv_dir = 'csv_data';
svg_dir = 'svg_plots';

% Create directories if they don't exist
if ~exist(csv_dir, 'dir')
    mkdir(csv_dir);
    fprintf('Created directory: %s\n', csv_dir);
end

if ~exist(svg_dir, 'dir')
    mkdir(svg_dir);
    fprintf('Created directory: %s\n', svg_dir);
end

% Load input data
[section, materials, reinforcement, analysis] = inputData();

% Calculate the plastic centroid
[xpc, ypc, section] = findCentroid(section, materials, reinforcement);
section.centroid = [xpc, ypc];

% Define angles for meridians (in 45-degree increments)
angles_deg = 0:45:315;
angles_rad = deg2rad(angles_deg);
num_angles = length(angles_rad);

% Set up colors for angles - use a print-friendly colormap instead of jet
% Define a custom colormap that avoids bright yellow for better printing
print_friendly_colors = [
    0.0000, 0.4470, 0.7410;  % Blue
    0.8500, 0.3250, 0.0980;  % Orange/Red
    0.4940, 0.1840, 0.5560;  % Purple
    0.4660, 0.6740, 0.1880;  % Green
    0.3010, 0.7450, 0.9330;  % Cyan
    0.6350, 0.0780, 0.1840;  % Dark Red
    0.0000, 0.0000, 0.5000;  % Navy
    0.7500, 0.0000, 0.7500;  % Magenta
];

% If we need more colors than provided, interpolate
if num_angles > size(print_friendly_colors, 1)
    % Interpolate to create more colors
    colors_base = print_friendly_colors;
    interp_factor = ceil(num_angles / size(colors_base, 1));
    colors_extended = [];
    
    for i = 1:size(colors_base, 1)
        if i < size(colors_base, 1)
            r_vals = linspace(colors_base(i,1), colors_base(i+1,1), interp_factor+1);
            g_vals = linspace(colors_base(i,2), colors_base(i+1,2), interp_factor+1);
            b_vals = linspace(colors_base(i,3), colors_base(i+1,3), interp_factor+1);
            
            for j = 1:interp_factor
                colors_extended = [colors_extended; r_vals(j), g_vals(j), b_vals(j)];
            end
        else
            % Connect last to first
            r_vals = linspace(colors_base(i,1), colors_base(1,1), interp_factor+1);
            g_vals = linspace(colors_base(i,2), colors_base(1,2), interp_factor+1);
            b_vals = linspace(colors_base(i,3), colors_base(1,3), interp_factor+1);
            
            for j = 1:interp_factor
                colors_extended = [colors_extended; r_vals(j), g_vals(j), b_vals(j)];
            end
        end
    end
    
    colors = colors_extended(1:num_angles, :);
else
    colors = print_friendly_colors(1:num_angles, :);
end

% Storage for results of all angles (for combined plot)
all_results = cell(num_angles, 1);

% Determine P values systematically
% First, estimate pure compression capacity
try
    % Use a very large value for c (all in compression)
    y_max = max(section.vertices(:,2));
    c_max = 3*y_max;
    [P_max, ~, ~] = computeSectionCapacity(c_max, section, materials, reinforcement, 0);
    fprintf('Pure compression capacity: %.0f kips\n', P_max);
catch
    % If that fails, use a default max value
    P_max = 60000;
    fprintf('Using default maximum P: %.0f kips\n', P_max);
end

% Try to estimate pure tension capacity
try
    % Estimate based on all steel yielding
    As_total = sum(reinforcement.area);
    P_min = -As_total * materials.fy; % Negative for tension
    fprintf('Pure tension capacity (estimated): %.0f kips\n', P_min);
catch
    % If that fails, use a default min value
    P_min = -5000;
    fprintf('Using default minimum P: %.0f kips\n', P_min);
end

% Distribute points with more resolution near zero
P_values = 0:10000:60000;
num_P_points = length(P_values);

% Iterate through angles
for a = 1:num_angles
    % Current angle
    theta = angles_rad(a);
    
    % Arrays to store results for current angle
    Mx_results = zeros(1, num_P_points);
    My_results = zeros(1, num_P_points);
    P_actual = zeros(1, num_P_points);
    valid_points = true(1, num_P_points); % Track which points are valid
    
    % Create a progress bar
    h_wait = waitbar(0, sprintf('Processing angle %.0f$^\\circ$ (%d of %d)...', angles_deg(a), a, num_angles));
    
    % Special case: Calculate pure moment (P=0) using specialized function
    try
        % Find neutral axis for pure moment
        [c_pure, Pn_pure, Mnx_pure, Mny_pure] = findNeutralAxisPureMoment(section, materials, reinforcement, theta);
        
        % Find the index for P=0 in our P_values array
        zero_idx = find(P_values == 0);
        if ~isempty(zero_idx)
            Mx_results(zero_idx) = Mnx_pure / 12; % Convert to ft-kips
            My_results(zero_idx) = Mny_pure / 12; % Convert to ft-kips
            P_actual(zero_idx) = Pn_pure; % Should be very close to zero
        end
    catch ME_pure
        fprintf('Warning: Pure moment calculation failed at angle %.0f°: %s\n', angles_deg(a), ME_pure.message);
    end
    
    % Calculate for other P values
    for p = 1:num_P_points
        % Skip P=0 as we've already calculated it
        if P_values(p) == 0 && ~isempty(find(P_values == 0, 1))
            continue;
        end
        
        % Current target axial load
        P_target = P_values(p);
        
        try
            % Find the neutral axis depth and corresponding moments for this P
            [c, Pn, Mnx, Mny] = findNeutralAxis(P_target, section, materials, reinforcement, theta);
            
            % Convert moments to ft-kips
            Mx_results(p) = Mnx / 12;
            My_results(p) = Mny / 12;
            P_actual(p) = Pn;
            
        catch ME
            % If calculation fails, mark point as invalid
            fprintf('Warning: Calculation failed for P=%.0f at angle %.0f°: %s\n', P_target, angles_deg(a), ME.message);
            valid_points(p) = false;
        end
        
        % Update progress bar
        waitbar(p/num_P_points, h_wait);
    end
    
    % Close progress bar
    close(h_wait);
    
    % Filter out invalid points
    Mx_valid = Mx_results(valid_points);
    My_valid = My_results(valid_points);
    P_valid = P_actual(valid_points);
    
    % Sort by P for better connected lines
    [P_sorted, sort_idx] = sort(P_valid);
    Mx_sorted = Mx_valid(sort_idx);
    My_sorted = My_valid(sort_idx);
    
    % Store results for this angle
    all_results{a} = struct('P', P_sorted, 'Mx', Mx_sorted, 'My', My_sorted, 'angle', angles_deg(a));
    
    fprintf('Completed angle %.0f° (%d of %d)\n', angles_deg(a), a, num_angles);
    
    % Save data to CSV for this angle
    csv_filename = fullfile(csv_dir, sprintf('meridian_data_%.0fdeg.csv', angles_deg(a)));
    
    % Create header and data for CSV
    header = 'P (kips),Mx (kip-ft),My (kip-ft)';
    
    % Open file and write header
    fid = fopen(csv_filename, 'w');
    fprintf(fid, '%s\n', header);
    
    % Write data rows
    for i = 1:length(P_sorted)
        fprintf(fid, '%.6f,%.6f,%.6f\n', P_sorted(i), abs(Mx_sorted(i)), abs(My_sorted(i)));
    end
    
    fclose(fid);
    fprintf('Saved data for angle %.0f° as %s\n', angles_deg(a), csv_filename);
    
 % Create individual plot for this angle
    fig_angle = figure('Name', sprintf('Meridian Plot for %.0f°', angles_deg(a)), 'Color', 'white');
    hold on; grid on;

    % Use absolute values for moments and correct signs for positioning
    plot(abs(Mx_sorted), P_sorted, '-o', 'Color', colors(a,:), 'LineWidth', 2, 'MarkerSize', 5, 'MarkerFaceColor', colors(a,:));
    plot(-abs(My_sorted), P_sorted, '--o', 'Color', colors(a,:), 'LineWidth', 2, 'MarkerSize', 5, 'MarkerFaceColor', colors(a,:));

    % Add a horizontal line at P=0 (pure moment)
    current_xlim = xlim;
    plot(current_xlim, [0, 0], 'k:', 'LineWidth', 1.5);
    xlim(current_xlim); % Reset xlim in case plot changed them slightly

    % Add labels and title for individual plot
    xlabel('Moment (kip-ft)');
    ylabel('Axial Load, $P$ (kips)');
    title(sprintf('Meridian Plot for $\\theta = %.0f^\\circ$', angles_deg(a)));

    % Add legend for individual plot
    legendEntries = {'$M_x$', '$M_y$'};
    legend(legendEntries, 'Location', 'best');

    svg_filename = fullfile(svg_dir, sprintf('meridian_plot_%.0fdeg.svg', angles_deg(a)));
    drawnow;

    % Save the figure referenced by fig_angle (which now contains the plot)
    saveas(fig_angle, svg_filename, 'svg');
    fprintf('Saved plot for angle %.0f° as %s\n', angles_deg(a), svg_filename);

end

% Create combined plot with all angles
figure('Name', 'Combined Meridian Plot', 'Color', 'white', 'Position', [100, 100, 1000, 800]);
hold on;
grid on;

% Storage for legend entries
legend_entries = cell(1, 2*num_angles);

% Plot all angles on the combined plot
for a = 1:num_angles
    % Get results for this angle
    results = all_results{a};
    
    % Plot using absolute values for moments
    plot(abs(results.Mx), results.P, '-o', 'Color', colors(a,:), 'LineWidth', 2, 'MarkerSize', 5, 'MarkerFaceColor', colors(a,:));
    plot(-abs(results.My), results.P, '--o', 'Color', colors(a,:), 'LineWidth', 2, 'MarkerSize', 5, 'MarkerFaceColor', colors(a,:));
    
    % Create legend entries
    legend_entries{2*a-1} = sprintf('$M_x$, $\\theta = %.0f^\\circ$', results.angle);
    legend_entries{2*a} = sprintf('$-M_y$, $\\theta = %.0f^\\circ$', results.angle);
end

% Add a horizontal line at P=0 (pure moment)
xlims = xlim;
plot(xlims, [0, 0], 'k:', 'LineWidth', 1.5);

% Add labels and title for combined plot
xlabel('Moment (kip-ft)');
ylabel('Axial Load, $P$ (kips)');

% Add legend for combined plot
legend(legend_entries, 'Location', 'eastoutside', 'NumColumns', 1);

% Save the combined plot as SVG
combined_svg_filename = fullfile(svg_dir, 'combined_meridian_plot.svg');
saveas(gcf, combined_svg_filename, 'svg');
fprintf('Saved combined plot as %s\n', combined_svg_filename);

fprintf('Meridian plot generation complete.\n');