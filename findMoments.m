function [Mnx,Mny] = findMoments(reinforcement, section, materials, Pns, c)

% plastic centroid
xpc = section.centroid(1);
ypc = section.centroid(2);

% find moment contribution from concrete
Pnc = 0; Mnyc = 0; Mnxc = 0;
polys = findPolys(section, c);
for i=1:length(polys)
    poly = polyshape(polys{i}(:,1),polys{i}(:,2));
    CArea = area(poly);
    [Ccx, Ccy] = centroid(poly);
    Pnc = Pnc + 0.85*materials.fc*CArea; % concrete force
    Mnyc = Mnyc + Pnc * (Ccx - xpc); % Conc moment about y
    Mnxc = Mnxc + Pnc * (Ccy - ypc); % Conc moment about x
end

% find moment contribution from steel
Nbars = length(reinforcement.x);
Mnys = zeros(Nbars,1);
Mnxs = zeros(Nbars,1);
for i=1:Nbars
    Mnxs(i) = Pns(i) * (reinforcement.y(i) - ypc);
    Mnys(i) = Pns(i) * (reinforcement.x(i) - xpc);
end

% Conc + Steel
Mny = sum(Mnys) + Mnyc;
Mnx = sum(Mnxs) + Mnxc;