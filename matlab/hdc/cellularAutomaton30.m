function HVOut = cellularAutomaton30(seedHV,cycles)

global HV_DIMENSION

HVOut = seedHV;

for i = 1:cycles
    tempHV = HVOut;
    HVOut(1) = rule30([tempHV(HV_DIMENSION) tempHV(1) tempHV(2)]);
    HVOut(HV_DIMENSION) = rule30([tempHV(HV_DIMENSION-1) tempHV(HV_DIMENSION) tempHV(1)]);
    for j = 2:HV_DIMENSION-1
        HVOut(j) = rule30(tempHV(j-1:j+1));
    end
end

end