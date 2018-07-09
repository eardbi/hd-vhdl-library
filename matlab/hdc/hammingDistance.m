function dist = hammingDistance(HV1,HV2,normalize)

    if(size(HV1) ~= size(HV2))
        disp('Hypervector dimension do not match!');
    end
    
    distVec = double(xor(logical(HV1),logical(HV2)));
    dist = sum(distVec);
    
    if exist('normalize','var')
        if normalize
            dist = dist/length(HV1);
        end
    end
    
end