% Copyright 2018 ETH Zurich
% Copyright and related rights are licensed under the Solderpad Hardware
% License, Version 0.51 (the “License”); you may not use this file except in
% compliance with the License.  You may obtain a copy of the License at
% http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
% or agreed to in writing, software, hardware and materials distributed under
% this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
% CONDITIONS OF ANY KIND, either express or implied. See the License for the
% specific language governing permissions and limitations under the License.

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