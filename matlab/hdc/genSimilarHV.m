function similarHV = genSimilarHV(HV,dist)
%
% DESCRIPTION   : generates a HV with specified Hamming distance from input
%                 HV
%
% INPUTS:
%   HV          : hypervector
%   dist        : Hamming distance
% OUTPUTS:
%   similarHV   : similar hypervector

    randomIndex = randperm(length(HV));
    flipVec = zeros(size(HV));
    flipVec(randomIndex(1:dist)) = 1;
    
    similarHV = double(xor(HV,flipVec));

end