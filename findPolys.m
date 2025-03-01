function polys = findPolys(section, c)
% FINDPOLYS - Creates polygons representing the compression zone
%
% This function creates polygons representing the portions of a concrete
% section that lie above a horizontal line y=c (compression zone)
%
% Inputs:
%   section - Structure containing concrete section geometry
%             Must have field 'vertices' with [x, y] coordinates
%   c - The y-coordinate of the horizontal line (neutral axis)
%
% Outputs:
%   polys - Cell array of polygons, each represented as an array of [x,y] vertices
%
% Example usage:
%   [section, ~, ~, ~] = inputData();
%   polys = findPolys(section, 100);

% Create a polyshape from the section vertices
sectionPoly = polyshape(section.vertices(:,1), section.vertices(:,2));

% Create a very large rectangle representing the half-plane above y=c
% Get the bounds of the section to determine appropriate size for the rectangle
xmin = min(section.vertices(:,1)) - 100;
xmax = max(section.vertices(:,1)) + 100;
ymin = c;
ymax = max(section.vertices(:,2)) + 100;

% Create a rectangle representing the half-plane above y=c
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