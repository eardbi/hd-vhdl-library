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