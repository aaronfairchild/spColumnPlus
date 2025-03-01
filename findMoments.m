function [Mnx,Mny] = findMoments(section, materials, reinforcement, analysis, polys)

% find moment contribution from concrete
Pnc = 0; Mnyc = 0; Mnxc = 0;
for i=1:length(polys(1))
    CArea = area(polys(i,:));
    [Ccx, Ccy] = centroid(polys(i,:));
    Pnc = Pnc + 0.85*fc*CArea; % concrete force
    Mnyc = Mnyc + Pnc * Ccx; % Conc moment about y
    Mnxc = Mnxc + Pnc * Ccy; % Conc moment about x
end

% find moment contribution from steel



% Conc + Steel
Pn = sum(R.Pns) + Pnc;
Mny = sum(R.Mnys) + Mnyc;
Mnx = sum(R.Mnxs) + Mnxc;