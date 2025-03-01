function drawSection(section, reinforcement)
% DRAWSECTION - Visualizes a reinforced concrete section
% 
% This function creates a visualization of a polygonal reinforced concrete
% section with reinforcement bars.
%
% Inputs:
%   section - Structure containing concrete section geometry
%             Must have field 'vertices' with [x, y] coordinates
%   reinforcement - Structure containing reinforcement details
%                   Must have fields 'x', 'y', and 'area' with bar information
%
% Example usage:
%   [section, materials, reinforcement, analysis] = inputData();
%   drawSection(section, reinforcement);

% Create new figure with white background
figure('Color', 'white');

% Get vertices for the concrete section
x_vertices = section.vertices(:,1);
y_vertices = section.vertices(:,2);

% Create a closed polygon by repeating the first vertex
x_vertices = [x_vertices; x_vertices(1)];
y_vertices = [y_vertices; y_vertices(1)];

% Plot the concrete section outline
fill(x_vertices, y_vertices, [0.85 0.85 0.85], 'EdgeColor', 'k', 'LineWidth', 2);
hold on;

% Calculate bar diameters from areas for visualization
% A = pi*r^2, so d = 2*sqrt(A/pi)
bar_diameters = 2 * sqrt(reinforcement.area / pi);

% Plot each reinforcement bar
for i = 1:length(reinforcement.x)
    % Draw filled circle for each reinforcement bar
    x = reinforcement.x(i);
    y = reinforcement.y(i);
    d = bar_diameters(i);
    
    % Create circle with appropriate size
    theta = linspace(0, 2*pi, 50);
    x_circle = x + (d/2) * cos(theta);
    y_circle = y + (d/2) * sin(theta);
    
    % Plot filled circle for reinforcement
    fill(x_circle, y_circle, 'k', 'EdgeColor', 'k');
end

% Set equal aspect ratio to avoid distortion
axis equal;

% Add title and labels
xlabel('X (in)', 'FontSize', 12);
ylabel('Y (in)', 'FontSize', 12);

% Add grid and set axis properties
grid on;
box on;

% Determine appropriate axes limits with some margin
x_min = min(section.vertices(:,1)) - 10;
x_max = max(section.vertices(:,1)) + 10;
y_min = min(section.vertices(:,2)) - 10;
y_max = max(section.vertices(:,2)) + 10;

% Set axis limits
axis([x_min x_max y_min y_max]);
if ~isempty(section.centroid)
    pc = section.centroid;
    plot(pc(1),pc(2),'ko','MarkerFaceColor','k');
end

end