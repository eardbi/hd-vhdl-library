% Copyright 2018 ETH Zurich
% Copyright and related rights are licensed under the Solderpad Hardware
% License, Version 0.51 (the “License”); you may not use this file except in
% compliance with the License.  You may obtain a copy of the License at
% http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
% or agreed to in writing, software, hardware and materials distributed under
% this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
% CONDITIONS OF ANY KIND, either express or implied. See the License for the
% specific language governing permissions and limitations under the License.

function bitOut = rule30(BitArrayIn)

if (size(BitArrayIn,2) ~= 3) || (size(BitArrayIn,1) ~= 1)
    disp('Not a suitable neighborhood array!');
    return;
end

switch num2str(BitArrayIn)
    case num2str([0 0 0])
        bitOut = 0;
    case num2str([0 0 1])
        bitOut = 1;
    case num2str([0 1 0])
        bitOut = 1;
    case num2str([0 1 1])
        bitOut = 1;
    case num2str([1 0 0])
        bitOut = 1;
    case num2str([1 0 1])
        bitOut = 0;
    case num2str([1 1 0])
        bitOut = 0;
    case num2str([1 1 1])
        bitOut = 0;
end


end