function HVOut = addHV(HVInArray)
% 
% ADDHV(HVInArray) computes majority vote hypervectors, breaking ties
% according to ADD_MODE.
% 
%   INPUTS:
%       HVInArray   array of hypervectors
%   OUTPUTS:
%       HVOut       majority vote of input hypervectors
% 

global btM ADD_MODE HV_DIMENSION %#ok<NUSED>

sArr = size(HVInArray);

HVOut = zeros(1,sArr(2));

for i = 1:sArr(1)
    HVOut = HVOut + HVInArray(i,:);
end

if mod(sArr(1),2) == 1
    HVOut = HVOut/sArr(1);
    HVOut = round(HVOut);
elseif mod(sArr(1),2) == 0
    switch ADD_MODE
        case 'random'
                HVOut = HVOut/sArr(1);
%                 HVOut = (HVOut + genRandomHV(HV_DIMENSION))/(sArr(1)+1);
                for i = 1:size(HVInArray,2)
                    if HVOut(i) == 0.5
                        HVOut(i) = round(rand);
                    else
                        HVOut(i) = round(HVOut(i));
                    end
                end
        case 'vector'
            HVOut = (HVOut + btM)/(sArr(1)+1);
            HVOut = round(HVOut);
        case 'bind'
            HVOut = (HVOut + multHV(HVOut))/(sArr(1)+1);
    end
    
end

end