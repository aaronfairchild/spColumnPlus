function intersections = findLineIntersections(section, c)
% FINDLINEINTERSECTIONS - Finds the intersections of a polygonal section with a horizontal line y=c
%
% This function calculates the intersection points between a horizontal line
% at y=c and the edges of a polygonal section.
%
% Inputs:
%   section - Structure containing concrete section geometry
%             Must have field 'vertices' with [x, y] coordinates
%   c - The y-coordinate of the horizontal line
%
% Outputs:
%   intersections - Nx2 array of [x, y] coordinates of intersection points
%
% Example usage:
%   [section, ~, ~, ~] = inputData();
%   intersections = findLineIntersections(section, 100);

% Get vertices for the concrete section
vertices = section.vertices;
n = size(vertices, 1);
intersections = [];

% Loop through all edges of the polygon
for i = 1:n
    % Get the current and next vertex (wrapping around to the first vertex)
    v1 = vertices(i, :);
    v2 = vertices(mod(i, n) + 1, :);
    
    % Extract coordinates
    x1 = v1(1);
    y1 = v1(2);
    x2 = v2(1);
    y2 = v2(2);
    
    % Check if the edge crosses the horizontal line y=c
    if (y1 <= c && y2 >= c) || (y1 >= c && y2 <= c)
        % Skip if both points are on the line (handled by neighboring edges)
        if y1 == c && y2 == c
            continue;
        end
        
        % If one endpoint is exactly on the line
        if y1 == c
            intersections = [intersections; x1, c];
        elseif y2 == c
            intersections = [intersections; x2, c];
        else
            % Calculate the intersection point using linear interpolation
            t = (c - y1) / (y2 - y1);
            x = x1 + t * (x2 - x1);
            intersections = [intersections; x, c];
        end
    end
end

% If we have duplicate points (within a small tolerance), keep only unique points
if ~isempty(intersections)
    % Sort by x-coordinate
    intersections = sortrows(intersections, 1);
    
    % Remove duplicates within a small tolerance
    tolerance = 1e-6;
    keep = true(size(intersections, 1), 1);
    for i = 2:size(intersections, 1)
        if abs(intersections(i,1) - intersections(i-1,1)) < tolerance
            keep(i) = false;
        end
    end
    intersections = intersections(keep, :);
end

end