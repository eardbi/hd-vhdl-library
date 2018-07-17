% Copyright 2018 ETH Zurich
% Copyright and related rights are licensed under the Solderpad Hardware
% License, Version 0.51 (the “License”); you may not use this file except in
% compliance with the License.  You may obtain a copy of the License at
% http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
% or agreed to in writing, software, hardware and materials distributed under
% this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
% CONDITIONS OF ANY KIND, either express or implied. See the License for the
% specific language governing permissions and limitations under the License.

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