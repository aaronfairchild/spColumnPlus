function [xpc,ypc,section] = findCentroid(section, materials, reinforcement)

vertices = section.vertices; % for concrete
xreinf = reinforcement.x;
yreinf = reinforcement.y;
Ar = reinforcement.area;

fy = materials.fy;
fc = materials.fc;

CPoly = polyshape(vertices(:,1), vertices(:,2));
[Ccx, Ccy] = centroid(CPoly);
Ag = area(CPoly);
section.Ag = Ag;

ypc = (sum(yreinf*fy.*Ar) + Ccy*Ag*0.85*fc)/ (sum(fy*Ar)+ Ag*0.85*fc);
xpc = (sum(xreinf*fy.*Ar) + Ccx*Ag*0.85*fc)/ (sum(fy*Ar)+ Ag*0.85*fc);
end