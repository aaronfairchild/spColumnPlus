function [section,reinforcement] = rotateSection(theta, section, reinforcement)

vertices = section.vertices; % for concrete
reinf = [reinforcement.x, reinforcement.y];
pc = section.centroid;

Q =[cos(theta), -sin(theta);
    sin(theta), cos(theta)];

for i = 1:size(vertices,1)
    vertices(i,:) = Q*vertices(i,:)';
end

for i = 1:size(reinf,1)
    reinf(i,:) = Q*reinf(i,:)';
end

section.centroid = Q*pc';

reinforcement.x = reinf(:,1);
reinforcement.y = reinf(:,2);
section.vertices = vertices;

end