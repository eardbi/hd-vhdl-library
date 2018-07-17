% Copyright 2018 ETH Zurich
% Copyright and related rights are licensed under the Solderpad Hardware
% License, Version 0.51 (the “License”); you may not use this file except in
% compliance with the License.  You may obtain a copy of the License at
% http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
% or agreed to in writing, software, hardware and materials distributed under
% this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
% CONDITIONS OF ANY KIND, either express or implied. See the License for the
% specific language governing permissions and limitations under the License.

function randomHV = genRandomHV(D)

if(mod(D,2))
    disp('Dimension is odd!!');
    return;
end

randomHV = zeros(1,D);
randomIndex = randperm(D);
randomHV(randomIndex(1:round(D/2))) = 1;


end