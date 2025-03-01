function [section, materials, reinforcement, analysis] = inputData()
% INPUT - Function containing data to create an interaction surface
% for biaxial bending analysis of a general polygonal reinforced concrete column
%
% INSTRUCTIONS FOR USE:
% 1. Edit the values in this file directly as needed
% 2. Run the function to generate the data structures
% 3. The function returns structures for geometry, materials, reinforcement and analysis parameters
%
% Outputs:
%   section - Structure containing concrete section geometry
%   materials - Structure containing material properties
%   reinforcement - Structure containing reinforcement details
%   analysis - Structure containing analysis parameters

%% SECTION 1: CONCRETE GEOMETRY
% Define the vertices of polygonal section as [x, y] coordinates
% Enter vertices in counterclockwise
section.vertices = [
    20.000,  240.000;
    0.000,   240.000;
    0, 0;
    150, 0;
    150, 20;
    20, 20;
];

%% SECTION 2: MATERIAL PROPERTIES
% Concrete properties
materials.fc_prime = 9;      % Concrete compressive strength (ksi)
materials.epsilon_cu = 0.003;   % Concrete ultimate strain (in/in)

% Steel properties
materials.fy = 60;           % Steel yield strength (ksi)
materials.Es = 29000;        % Steel elastic modulus (ksi)
materials.cover = 2.500;        % Concrete cover (in) to center of bars

% Beta1 coefficient for equivalent rectangular stress block
% ACI 318 values are calculated below, but can be overridden
if materials.fc_prime <= 4
    materials.beta1 = 0.85;
elseif materials.fc_prime >= 8
    materials.beta1 = 0.65;
else
    materials.beta1 = 0.85 - 0.05 * (materials.fc_prime - 4); % unsure
end

% Uncomment to override beta1 with custom value
% materials.beta1 = 0.75;

%% SECTION 3: REINFORCEMENT DEFINITION
% Define reinforcement as lines with evenly spaced bars
% Each reinforcement line needs:
%   - Start point [x, y]
%   - End point [x, y]
%   - Number of bars (including endpoints)
%   - Bar area (in²)

% Example: Define three reinforcement lines

% Left vertical face
line1.start_x = 2.5;
line1.start_y = 237.5;
line1.end_x = 2.5;
line1.end_y = 2.5;
line1.num_bars = 21;            % Number of bars along this line (evenly spaced)
line1.bar_area = 1.56;          % Area per bar (in^2) - #11

% Bottom horizontal face
line2.start_x = 2.5;
line2.start_y = 2.5;
line2.end_x = 147.5;
line2.end_y = 2.5;
line2.num_bars = 15;            % Number of bars along this line (evenly spaced)
line2.bar_area = 1.56;          % Area per bar (in^2) - #11

% Right vertical face
line3.start_x = 17.5;
line3.start_y = 17.5;
line3.end_x = 17.5;
line3.end_y = 237.5;
line3.num_bars = 20;           % Number of bars along this line (evenly spaced)
line3.bar_area = 1.56;         % Area per bar (in^2) - #11



% Combine all line definitions into array
reinforcement.lines = {line1, line2, line3};

% REFERENCE: Standard US bar sizes (for reference only)
% #3: 0.11 in²  |  #4: 0.20 in²  |  #5: 0.31 in²  |  #6: 0.44 in²
% #7: 0.60 in²  |  #8: 0.79 in²  |  #9: 1.00 in²  |  #10: 1.27 in²
% #11: 1.56 in² |  #14: 2.25 in² |  #18: 4.00 in²

% Process all reinforcement lines (MODIFIED TO REMOVE DUPLICATES)
% This generates arrays with all reinforcement coordinates and areas
all_x = [];
all_y = [];
all_area = [];

for i = 1:length(reinforcement.lines)
    line = reinforcement.lines{i};
    
    % Generate evenly spaced coordinates along the line
    if line.num_bars > 1
        x_coords = linspace(line.start_x, line.end_x, line.num_bars);
        y_coords = linspace(line.start_y, line.end_y, line.num_bars);
    else
        % Only one bar
        x_coords = line.start_x;
        y_coords = line.start_y;
    end
    
    % Calculate coordinates for each bar
    reinforcement.lines{i}.x = x_coords;
    reinforcement.lines{i}.y = y_coords;
    
    % Add to overall arrays
    all_x = [all_x, x_coords];
    all_y = [all_y, y_coords];
    all_area = [all_area, line.bar_area * ones(1, length(x_coords))];
end

% Remove duplicate reinforcement at the same coordinates
% Combine coordinates and areas into a matrix for processing
rebar_data = [all_x(:), all_y(:), all_area(:)];

% Find unique coordinates with a small tolerance
tolerance = 1e-6;  % Tolerance for coordinate equality
[~, unique_indices] = unique(round(rebar_data(:,1:2)/tolerance)*tolerance, 'rows', 'first');
unique_indices = sort(unique_indices);  % Sort to maintain original order

% Keep only the unique reinforcement bars
reinforcement.x = rebar_data(unique_indices, 1);
reinforcement.y = rebar_data(unique_indices, 2);
reinforcement.area = rebar_data(unique_indices, 3);

% Display information about removed duplicates
num_duplicates = length(all_x) - length(unique_indices);
if num_duplicates > 0
    fprintf('Removed %d duplicate reinforcement bar(s) at overlapping coordinates.\n', num_duplicates);
end

%% SECTION 4: ANALYSIS PARAMETERS
% Parameters for interaction surface generation
analysis.P = 20000;             % Axial load P (kips, compression positive)
analysis.start_angle = 0;       % Start angle for rotation (degrees)
analysis.end_angle = 360;       % End angle for rotation (degrees)
analysis.angle_increment = 45;  % Angle increment (degrees)

%% Display summary of inputs (DO NOT MODIFY THIS SECTION)
display_summary(section, materials, reinforcement, analysis);

end

function display_summary(section, materials, reinforcement, analysis)
% Display a summary of the input data

fprintf('\n=== INPUT SUMMARY ===\n');

% Section geometry summary
fprintf('Concrete Section: Polygon with %d vertices\n', size(section.vertices, 1));

% Material properties summary
fprintf('\nMaterial Properties:\n');
fprintf('  Concrete strength (f''c): %.0f psi\n', materials.fc_prime);
fprintf('  Ultimate strain: %.5f in/in\n', materials.epsilon_cu);
fprintf('  Steel yield strength (fy): %.0f psi\n', materials.fy);
fprintf('  Steel elastic modulus (Es): %.0f psi\n', materials.Es);
fprintf('  Cover: %.2f in\n', materials.cover);
fprintf('  Beta1: %.2f\n', materials.beta1);

% Reinforcement summary
fprintf('\nReinforcement:\n');
fprintf('  Number of reinforcement lines: %d\n', length(reinforcement.lines));
fprintf('  Total number of bars: %d\n', length(reinforcement.x));

% Analysis parameters summary
fprintf('\nAnalysis Parameters:\n');
fprintf('  Axial load (P): %.2f kips\n', analysis.P);
fprintf('  Moment rotation: %.0f° to %.0f° (%.0f° increments)\n', ...
    analysis.start_angle, analysis.end_angle, analysis.angle_increment);

fprintf('\nInput complete! Ready for interaction surface generation.\n');
end