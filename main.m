clear; clc; delete(findall(0, 'Type', 'figure')); % gets rid of all open figures
% Main calling function for Column Analysis
% Original Date: 3/1/2025
% Latest Update: 3/1/2025

[section, materials, reinforcement, analysis] = inputData();

drawSection(section, reinforcement);

[xpc,ypc] = findCentroid(section, materials, reinforcement);
section.centroid = [xpc,ypc];


theta = deg2rad(45);

[section,reinforcement] = rotateSection(theta, section, reinforcement);
drawSection(section, reinforcement);

% find correct Pn
c = 30;
Pn = findPn(section, materials, reinforcement);


maxy =

boo

