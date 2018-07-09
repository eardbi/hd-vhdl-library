function fileInsertMatrix(outputFilename, templateFilename, insertData, insertLinePositions)
% 
% FILEINSERTMATRIX(outputFilename, templateFilename, insertData, insertLinePositions)
% writes matrix data (e.g. connectivity matrices) into a VHDL package file.
% 
%   INPUTS:
%       outputFilename          output file name specified as character string
%       templateFilename        template file name specified as character string
%       insertData              matrix data
%       insertLinePositions     positions in the file where data is inserted
% 

outputID = fopen(outputFilename,'w');
templateID = fopen(templateFilename,'r');

linePos = 1;
for i = 1:length(insertLinePositions)
    for j = linePos:insertLinePositions(i)-1
        fprintf(outputID,'%c',fgets(templateID));
    end
    for j = 1:size(insertData{i},1)
        fprintf(outputID,'\t\t"');
        fprintf(outputID,'%d',insertData{i}(j,:));
        if j ~= size(insertData{i},1)
            fprintf(outputID,'",\n');
        else
            fprintf(outputID,'"\n');
        end
    end
    fgets(templateID);
    linePos = insertLinePositions(i)+1;
end

tLine = fgets(templateID);
while ischar(tLine)
    fprintf(outputID,'%c',tLine);
    tLine = fgets(templateID);
end

fclose('all');

end