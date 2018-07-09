function HVOut = bundleHV(HVInArray,bundle_mode,bundle_bits)
% 
% BUNDLEHV(HVInArray,bundle_mode,bundle_bits) bundles hypervectors according
% to bundle_mode
% 
%   INPUTS:
%       HVInArray     array of hypervectors
%       bundle_mode   bundle mode specified as string
%       bundle_bits   number of bits when using the bundle counter
%   OUTPUTS:
%       HVOut         hypervector record
% 

global HV_DIMENSION bnMatrix

switch bundle_mode
    case 'golden'
        HVOut = addHV(HVInArray);
        
    case 'up_down_counter_random'
        maxValue = 2^(bundle_bits-1)-1;
        minValue = -2^(bundle_bits-1);
        
        Counter = zeros(1,HV_DIMENSION);
        for i = 1:size(HVInArray,1)
            for j = 1:HV_DIMENSION
                if HVInArray(i,j) == 1
                    Counter(j) = min(maxValue,Counter(j)+1);
                else
                    Counter(j) = max(minValue,Counter(j)-1);
                end
            end
        end
        
        HVOut = zeros(1,HV_DIMENSION);
        for i = 1:HV_DIMENSION
            if Counter(i) > 0
                HVOut(i) = 1;
            elseif Counter(i) < 0
                HVOut(i) = 0;
            else
                HVOut(i) = round(rand);
            end
        end
        
    case 'up_down_counter'
        maxValue = 2^(bundle_bits-1)-1;
        minValue = -2^(bundle_bits-1);
        
        Counter = zeros(1,HV_DIMENSION);
        for i = 1:HV_DIMENSION
            if HVInArray(1,i) == 1
                Counter(i) = 0;
            else
                Counter(i) = -1;
            end
        end

        for i = 2:size(HVInArray,1)
            for j = 1:HV_DIMENSION
                if HVInArray(i,j) == 1
                    Counter(j) = min(maxValue,Counter(j)+1);
                else
                    Counter(j) = max(minValue,Counter(j)-1);
                end
            end
        end
        
        HVOut = zeros(1,HV_DIMENSION);
        for i = 1:HV_DIMENSION
            if Counter(i) >= 0
                HVOut(i) = 1;
            else
                HVOut(i) = 0;
            end
        end
        
    case 'back_to_back_random'
        HVOut = HVInArray(1,:);
        for i = 2:size(HVInArray,1)
            tempSimilarHV = genSimilarHV(HVOut,round(HV_DIMENSION/i));
            HVOut = addHV([HVOut;HVInArray(i,:);tempSimilarHV]);
        end
        
    case 'back_to_back'
        HVOut = HVInArray(1,:);        
        for i = 2:size(HVInArray,1)
            tempSimilarHV = double(xor(HVOut,bnMatrix(i,:)));
            HVOut = addHV([HVOut;HVInArray(i,:);tempSimilarHV]);
        end
end
end