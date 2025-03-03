clear; clc; delete(findall(0, 'Type', 'figure')); % gets rid of all open figures
% Main calling function for Column Analysis
% Original Date: 3/1/2025
% Latest Update: 3/2/2025 (Modified to measure c from top)

% Initialize arrays to store results
Mx = []; My = [];
Pn_values = [];

theta_range = deg2rad(0:45:360);
for i = 1:length(theta_range)
    theta = theta_range(i);
    [section, materials, reinforcement, analysis] = inputData();

    [xpc,ypc,section] = findCentroid(section, materials, reinforcement);
    section.centroid = [xpc,ypc];

    [section,reinforcement] = rotateSection(theta, section, reinforcement);
    
    % find correct c for given Pn
    [Pn, Pnc, Pns, c] = findPn(section, materials, reinforcement, analysis);
    Pn_values(i) = Pn;
    
    % Draw the section with neutral axis and compression zone
    polys = findPolys(section, c, materials.beta1);
    drawSection(section, reinforcement, c, polys);
    title(sprintf('Rotation: %.0f degrees, c = %.2f', rad2deg(theta), c));

    % find moments
    [Mnx,Mny] = findMoments(reinforcement, section, materials, Pns, c);

    % Store results with appropriate scaling
    Mx(i) = Mnx/12/35000;
    My(i) = Mny/12/35000;
    
    % Print results for this angle
    fprintf('Rotation: %.0f degrees\n', rad2deg(theta));
    fprintf('Neutral axis depth (c): %.2f in\n', c);
    fprintf('Axial capacity (Pn): %.2f kips\n', Pn);
    fprintf('Moment capacity (Mnx): %.3f k-ft (scaled: %.3f)\n', Mnx/12, Mnx/12/35000);
    fprintf('Moment capacity (Mny): %.3f k-ft (scaled: %.3f)\n\n', Mny/12, Mny/12/35000);
end

% Create a figure for the interaction diagram
figure; 
plot(Mx, My, 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
grid on;
hold on;
xlabel('Mx (scaled)', 'FontSize', 12);
ylabel('My (scaled)', 'FontSize', 12);
title('Interaction Diagram', 'FontSize', 14);

% Add radial lines to origin to help visualize
for i = 1:length(Mx)
    plot([0, Mx(i)], [0, My(i)], 'k:', 'LineWidth', 0.5);
end

% Label points with rotation angles
for i = 1:length(Mx)
    text(Mx(i), My(i), sprintf('  %.0f°', rad2deg(theta_range(i))), ...
        'FontSize', 8, 'HorizontalAlignment', 'left');
end