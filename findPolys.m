function polys = findPolys(section, c, beta1)
% FINDPOLYS - Creates polygons representing the compression zone
%
% This function creates polygons representing the portions of a concrete
% section that lie above a horizontal line measured from the top of the section
%
% Inputs:
%   section - Structure containing concrete section geometry
%             Must have field 'vertices' with [x, y] coordinates
%   c - The depth of neutral axis from extreme compression fiber (top)
%
% Outputs:
%   polys - Cell array of polygons, each represented as an array of [x,y] vertices

% Find the extreme compression fiber (maximum y-coordinate)
y_max = max(section.vertices(:,2));

a = beta1*c;
% Calculate actual y-coordinate for neutral axis line
na_line = y_max - c;

% Create a polyshape from the section vertices
sectionPoly = polyshape(section.vertices(:,1), section.vertices(:,2));

% Create a very large rectangle representing the half-plane above the neutral axis
% Get the bounds of the section to determine appropriate size for the rectangle
xmin = min(section.vertices(:,1)) - 100;
xmax = max(section.vertices(:,1)) + 100;
ymin = y_max - a;  % This is the neutral axis line
ymax = y_max + 100;  % Extend well above the section

% Create a rectangle representing the half-plane above na_line
clipPoly = polyshape([xmin, xmax, xmax, xmin], [ymin, ymin, ymax, ymax]);

% Intersect the section with the half-plane to get the compression zone
compZone = intersect(sectionPoly, clipPoly);

% If the compression zone is empty, return empty cell array
if isempty(compZone.Vertices)
    polys = {};
    return;
end

% Get regions of the compression zone (in case there are multiple disconnected regions)
try
    % Try to get regions (for MATLAB R2018b and later)
    polyRegions = regions(compZone);
    numRegions = numel(polyRegions);
    
    % Convert polyshape regions to cell array of vertex arrays
    polys = cell(1, numRegions);
    for i = 1:numRegions
        polys{i} = [polyRegions(i).Vertices(:,1), polyRegions(i).Vertices(:,2)];
    end
catch
    % Fallback for older MATLAB versions or if regions fails
    % Just use the vertices of the compZone
    polys = {[compZone.Vertices(:,1), compZone.Vertices(:,2)]};
end

end