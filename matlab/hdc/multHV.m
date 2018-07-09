function HVOut = multHV(HVInArray)

HVOut = HVInArray(1,:);
for i = 2:size(HVInArray,1)
    HVOut = double(xor(logical(HVOut),logical(HVInArray(i,:))));
end

end