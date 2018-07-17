% Copyright 2018 ETH Zurich
% Copyright and related rights are licensed under the Solderpad Hardware
% License, Version 0.51 (the “License”); you may not use this file except in
% compliance with the License.  You may obtain a copy of the License at
% http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
% or agreed to in writing, software, hardware and materials distributed under
% this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
% CONDITIONS OF ANY KIND, either express or implied. See the License for the
% specific language governing permissions and limitations under the License.

function fileInsertParameters(outputFilename, templateFilename, insertData, insertLinePositions)
% 
% FILEINSERTPARAMETERS(outputFilename, outputFilename, insertData, insertLinePositions)
% inserts parameters (e.g. hypervector dimension) into VHDL package file.
% 
%   INPUTS:
%       outputFilename          output file name specified as character string
%       templateFilename        template file name specified as character string
%       insertData              parameter data (cell array of character strings)
%       insertLinePositions     positions in the file where data is inserted
% 

outputID = fopen(outputFilename,'w');
templateID = fopen(templateFilename,'r');

linePos = 1;
for i = 1:length(insertLinePositions)
    for j = linePos:insertLinePositions(i)-1
        fprintf(outputID,'%c',fgets(templateID));
    end
    tempLine = fgetl(templateID);
    for j = 1:length(tempLine)
        if tempLine(j) == '='
            fprintf(outputID,'%c',tempLine(1:j));
            fprintf(outputID,' %s;\n',num2str(insertData{i}));
            break;
        end
    end
    linePos = insertLinePositions(i)+1;
end

tLine = fgets(templateID);
while ischar(tLine)
    fprintf(outputID,'%c',tLine);
    tLine = fgets(templateID);
end

fclose('all');

end