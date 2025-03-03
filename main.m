clear; clc; delete(findall(0, 'Type', 'figure')); % gets rid of all open figures
% Main calling function for Column Analysis
% Original Date: 3/1/2025
% Latest Update: 3/1/2025



theta_range = deg2rad(0:45:360);
for i = 1:length(theta_range)
theta = theta_range(i);
[section, materials, reinforcement, analysis] = inputData();

[xpc,ypc,section] = findCentroid(section, materials, reinforcement);
section.centroid = [xpc,ypc];

[section,reinforcement] = rotateSection(theta, section, reinforcement);
drawSection(section, reinforcement);

% find correct c for given Pn
[Pn, Pnc, Pns, c] = findPn(section, materials, reinforcement, analysis);

% find moments
[Mnx,Mny] = findMoments(reinforcement, section, materials, Pns, c);

Mx(i) = Mnx/12/35000;
My(i) = Mny/12/35000;
fprintf('Pn:  %5.3f\n', Pn);
fprintf('Mnx:  %5.3f\n',Mnx/12/35000);
fprintf('Mny:  %5.3f\n',Mny/12/35000);
end

figure; grid on; hold on;
plot(Mx,My,'o')