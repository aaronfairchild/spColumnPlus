function drawSection(section, reinforcement, c, polys)
% DRAWSECTION - Visualizes a reinforced concrete section with neutral axis and compression zone
% 
% This function creates a visualization of a polygonal reinforced concrete
% section with reinforcement bars, neutral axis, and compression zone.
%
% Inputs:
%   section - Structure containing concrete section geometry
%             Must have field 'vertices' with [x, y] coordinates
%   reinforcement - Structure containing reinforcement details
%                   Must have fields 'x', 'y', and 'area' with bar information
%   c - The y-coordinate of the neutral axis (optional)
%   polys - Cell array of polygons representing compression zone (optional)
%
% Example usage:
%   [section, materials, reinforcement, analysis] = inputData();
%   [Pn, Pnc, Pns, c] = findPn(section, materials, reinforcement, analysis);
%   polys = findPolys(section, c);
%   drawSection(section, reinforcement, c, polys);

% Make c and polys optional parameters
if nargin < 3
    c = [];
    polys = {};
elseif nargin < 4
    polys = {};
end

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

% Draw compression zone polygons if provided
if ~isempty(polys)
    for i = 1:length(polys)
        % Extract vertices from polygon
        poly_x = polys{i}(:,1);
        poly_y = polys{i}(:,2);
        
        % Draw filled polygon with semi-transparent blue color
        fill(poly_x, poly_y, [0.3 0.5 0.8], 'FaceAlpha', 0.5, 'EdgeColor', 'b');
    end
end

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

% Draw neutral axis line if c is provided
if ~isempty(c)
    % Determine the x-range for the neutral axis line
    x_min = min(section.vertices(:,1)) - 15;
    x_max = max(section.vertices(:,1)) + 15;
    
    % Plot horizontal line at y = c
    plot([x_min, x_max], [c, c], 'r--', 'LineWidth', 2);
    
    % Add text label for the neutral axis
    text(x_max - 5, c + 5, ['c = ' num2str(c, '%.2f')], 'Color', 'r', 'FontSize', 10, ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');
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

% Plot centroid if available
if ~isempty(section.centroid)
    pc = section.centroid;
    plot(pc(1), pc(2), 'ko', 'MarkerFaceColor', 'k');
    text(pc(1) + 2, pc(2) + 2, 'PC', 'FontSize', 10);
end
end