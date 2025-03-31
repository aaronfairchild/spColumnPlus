function generateIsocontours(section, materials, reinforcement, Pn_values, angle_increment)
% GENERATEISOCONTOURS - Generates isocontours of Mx vs My for different values of Pn
%
% Inputs:
%   section - Structure containing concrete section geometry
%   materials - Structure containing material properties
%   reinforcement - Structure containing reinforcement details
%   Pn_values - Array of axial load values (kips)
%   angle_increment - Angle increment for the diagram (degrees)

% Create a figure for the isocontours
figure('Color', 'white');
hold on;
grid on;
xlabel('$M_x$ (kip-ft)', 'FontSize', 12);
ylabel('$M_y$ (kip-ft)', 'FontSize', 12);
title('Interaction Diagram ($M_x$ vs $M_y$) for Different $P_n$ Values', 'FontSize', 14);

% Generate and plot interaction diagrams for each Pn value
legend_entries = cell(1, length(Pn_values));
colors = jet(length(Pn_values)); % Generate a color map

% Display header for data
fprintf('\n%-10s %-10s %-15s %-15s\n', 'Pn (kips)', 'Angle (°)', 'Mx (norm)', 'My (norm)');
fprintf('%-10s %-10s %-15s %-15s\n', '----------', '----------', '---------------', '---------------');

for i = 1:length(Pn_values)
    Pn = Pn_values(i);
    fprintf('\nPn = %.0f kips:\n', Pn);
    
    % Generate the interaction diagram
    [Mx, My, angles] = generateInteractionDiagram(Pn, section, materials, reinforcement, angle_increment);
    
    % Plot the interaction diagram
    plot(Mx, My, '-', 'LineWidth', 1.5, 'Color', colors(i,:));
    
    % Add to legend entries
    legend_entries{i} = sprintf('$P_n = $%.0f kips', Pn);
end

% Add legend
legend(legend_entries, 'Location', 'best');
axis equal;
hold off;
end