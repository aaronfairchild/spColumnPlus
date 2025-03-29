function [Pn, Mnxg, Mnyg, Pnc, Pns] = computeSectionCapacity(c, section, materials, reinforcement,theta)
% COMPUTESECTIONCAPACITY - Calculates axial capacity and moments for a given neutral axis depth
%
% Inputs:
%   c - Neutral axis depth
%   section - Structure containing concrete section geometry
%   materials - Structure containing material properties
%   reinforcement - Structure containing reinforcement details
%
% Outputs:
%   Pn - Total axial capacity (kips)
%   Mnx - Moment about x-axis (kip-in)
%   Mny - Moment about y-axis (kip-in)
%   Pnc - Concrete contribution to axial capacity (kips)
%   Pns - Steel contribution to axial capacity (kips) as an array

% Extract material properties
fc = materials.fc;
fy = materials.fy;
Es = materials.Es;
epsilon_cu = materials.epsilon_cu;
beta1 = materials.beta1;
a = c * beta1;

% Get concrete polygons in compression for current c
polys = findPolys(section, a);

% Plastic centroid
xpc = section.centroid(1);
ypc = section.centroid(2);

% Calculate concrete contribution
Pnc = 0;
Mnxc = 0;
Mnyc = 0;
if ~isempty(polys)
    for i = 1:length(polys)
        % Create a polyshape from the polygon vertices
        compPoly = polyshape(polys{i}(:,1), polys{i}(:,2));
        
        % Calculate area and centroid of the polygon
        CArea = area(compPoly);
        [Ccx, Ccy] = centroid(compPoly);
        
        % Add contribution to concrete axial capacity
        Fc = 0.85 * fc * CArea;
        Pnc = Pnc + Fc;
        
        % Add contribution to concrete moments
        Mnxc = Mnxc + Fc * (ypc - Ccy);
        Mnyc = Mnyc + Fc * (xpc - Ccx);
    end
end

% Calculate steel contribution
Pns = zeros(length(reinforcement.x), 1);
Mnxs = zeros(length(reinforcement.x), 1);
Mnys = zeros(length(reinforcement.x), 1);
y_max = max(section.vertices(:,2));
for i = 1:length(reinforcement.x)
    % Get coordinates of reinforcement bar
    x_bar = reinforcement.x(i);
    y_bar = reinforcement.y(i);
    
    % Calculate strain in steel
    strain = epsilon_cu * (c - (y_max - y_bar)) / c;
    
    % Calculate stress (limited by yield)
    stress = min(max(strain * Es, -fy), fy);
    
    % Add contribution to steel axial capacity
    if y_bar > (y_max - a)
        Pns(i) = (stress) * reinforcement.area(i);
    else
        Pns(i) = stress * reinforcement.area(i);
    end
    
    % Add contribution to steel moments
    Mnxs(i) = Pns(i) * (ypc - y_bar);
    Mnys(i) = Pns(i) * (xpc - x_bar);
end

% Total axial capacity and moments
Pn = Pnc + sum(Pns);
Mnx = Mnxc + sum(Mnxs);
Mny = Mnyc + sum(Mnys);     % -Mny

% Ensure outputs are scalar
Pn = Pn(1);

Q =[cos(theta), -sin(theta);
    sin(theta), cos(theta)];
Mn = Q*[Mnx(1); Mny(1)];
Mnxg = Mn(1);
Mnyg = -Mn(2);

end