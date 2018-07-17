% Copyright 2018 ETH Zurich
% Copyright and related rights are licensed under the Solderpad Hardware
% License, Version 0.51 (the “License”); you may not use this file except in
% compliance with the License.  You may obtain a copy of the License at
% http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
% or agreed to in writing, software, hardware and materials distributed under
% this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
% CONDITIONS OF ANY KIND, either express or implied. See the License for the
% specific language governing permissions and limitations under the License.

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