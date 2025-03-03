function polys = findPolys(section, depth_from_top)
% FINDPOLYS - Creates polygons representing the portion of a section above a specified depth
%
% This function creates polygons representing the portions of a concrete
% section that lie above a horizontal line measured from the top of the section
%
% Inputs:
%   section - Structure containing concrete section geometry
%             Must have field 'vertices' with [x, y] coordinates
%   depth_from_top - The depth from extreme compression fiber (top)
%                   Could be c (neutral axis) or a (compression block)
%   beta1 - Whitney stress block parameter (optional, not used directly)
%           Included for compatibility with existing code
%
% Outputs:
%   polys - Cell array of polygons, each represented as an array of [x,y] vertices

% Find the extreme compression fiber (maximum y-coordinate)
y_max = max(section.vertices(:,2));

% Calculate actual y-coordinate for the cut line
cut_line = y_max - depth_from_top;

% Create a polyshape from the section vertices
sectionPoly = polyshape(section.vertices(:,1), section.vertices(:,2));

% Create a very large rectangle representing the half-plane above the cut line
% Get the bounds of the section to determine appropriate size for the rectangle
xmin = min(section.vertices(:,1)) - 100;
xmax = max(section.vertices(:,1)) + 100;
ymin = cut_line;  % This is the cut line
ymax = y_max + 100;  % Extend well above the section

% Create a rectangle representing the half-plane above the cut line
clipPoly = polyshape([xmin, xmax, xmax, xmin], [ymin, ymin, ymax, ymax]);

% Intersect the section with the half-plane to get the zone above the cut line
zoneAbove = intersect(sectionPoly, clipPoly);

% If the zone is empty, return empty cell array
if isempty(zoneAbove.Vertices)
    polys = {};
    return;
end

% Get regions (in case there are multiple disconnected regions)
try
    % Try to get regions (for MATLAB R2018b and later)
    polyRegions = regions(zoneAbove);
    numRegions = numel(polyRegions);
    
    % Convert polyshape regions to cell array of vertex arrays
    polys = cell(1, numRegions);
    for i = 1:numRegions
        polys{i} = [polyRegions(i).Vertices(:,1), polyRegions(i).Vertices(:,2)];
    end
catch
    % Fallback for older MATLAB versions or if regions fails
    % Just use the vertices of the zone
    polys = {[zoneAbove.Vertices(:,1), zoneAbove.Vertices(:,2)]};
end

end