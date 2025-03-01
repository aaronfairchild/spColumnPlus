function [Pn, Pnc, Pns] = findPn(section, materials, reinforcement, analysis)

c = analysis.start_c
CPolys = findPolys(section, c);

end