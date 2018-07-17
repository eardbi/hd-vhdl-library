% Copyright 2018 ETH Zurich
% Copyright and related rights are licensed under the Solderpad Hardware
% License, Version 0.51 (the “License”); you may not use this file except in
% compliance with the License.  You may obtain a copy of the License at
% http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
% or agreed to in writing, software, hardware and materials distributed under
% this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
% CONDITIONS OF ANY KIND, either express or implied. See the License for the
% specific language governing permissions and limitations under the License.

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