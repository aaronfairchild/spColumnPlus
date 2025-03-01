function [Pn, Pnc, Pns] = findPn(section, materials, reinforcement, analysis)

c = analysis.start_c;
Pn_target = analysis.P;
tolP = analysis.P_tolerance;
CPolys = findPolys(section, c);

while err > tol
    
    err = abs(Pn - Pn_target)/Pn_target;
end

end