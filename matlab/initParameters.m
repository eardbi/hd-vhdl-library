% Initalises all parameters, storages and matrices required for HDC

clear all; %#ok<*CLALL>

%% Define Parameters
global HV_DIMENSION CLASSES INPUT_CHANNELS INPUT_QUANTIZATION...
       BUNDLE_CHANNEL_BITS NGRAM_SIZE BUNDLE_NGRAM_BITS BUNDLE_NGRAM_CYCLES...
       AM_BLOCK_WIDTH mode_train mode_predict

% Adjust these parameters to your needs
HV_DIMENSION = 2^10;
CLASSES = 5;
INPUT_CHANNELS = 4;
INPUT_QUANTIZATION = 21;
BUNDLE_CHANNEL_BITS = 3;
NGRAM_SIZE = 3;
BUNDLE_NGRAM_BITS = 5;
BUNDLE_NGRAM_CYCLES = 2^5; % has to be larger than the number of training samples
AM_BLOCK_WIDTH = 2^6;

mode_train = 0;
mode_predict = 1;

%% Calculations
global LABEL_WIDTH INPUT_WIDTH DISTANCE_WIDTH

LABEL_WIDTH = ceil(log2(CLASSES));
INPUT_WIDTH = ceil(log2(INPUT_QUANTIZATION));
DISTANCE_WIDTH = ceil(log2(HV_DIMENSION));

%% Modes
global CIM_MODE IM_MODE ADD_MODE CNTR_OVERFLOW_MODE...
       SPATIAL_MODE BUNDLE_CHANNEL_MODE BUNDLE_NGRAM_MODE

% Change these to configure the HDC classifier.
CIM_MODE = 'mapped_xor';
% IM_MODE = 'random';
IM_MODE = 'cellular_automaton';
ADD_MODE = 'random';
CNTR_OVERFLOW_MODE = 'saturate';
SPATIAL_MODE = 'add_channel';
% BUNDLE_CHANNEL_MODE = 'golden';
BUNDLE_CHANNEL_MODE = 'up_down_counter';
% BUNDLE_CHANNEL_MODE = 'back_to_back';
% BUNDLE_NGRAM_MODE = 'golden';
BUNDLE_NGRAM_MODE = 'back_to_back';
% BUNDLE_NGRAM_MODE = 'up_down_counter';

%% Seeds & Connectivity Matrices
global iM_seedHV CiM_seedHV iMMatrix CiMMatrix bnMatrix

iM_seedHV = genRandomHV(HV_DIMENSION); % stored in memory and used by cellular automaton
CiM_seedHV = genRandomHV(HV_DIMENSION); % stored in memory

iMMatrix = initiM;
CiMMatrix = initCiMMatrix;
bnMatrix = initbnMatrix;

%% Memory
global NHot_LUT iM CiM btM AM

NHot_LUT = initNHot;
iM = iMMatrix;
CiM = initCiM;
btM = genRandomHV(HV_DIMENSION);
AM = zeros(CLASSES,HV_DIMENSION);

%% Subfunctions
function iM = initiM

global INPUT_CHANNELS HV_DIMENSION iM_seedHV IM_MODE

iM = zeros(INPUT_CHANNELS, HV_DIMENSION);

switch IM_MODE
    case 'cellular_automaton'
        iM(1,:) = iM_seedHV;
        for i = 2:INPUT_CHANNELS
            iM(i,:) = cellularAutomaton30(iM(i-1,:),1);
        end
    case 'random'
        for i = 1:INPUT_CHANNELS
            iM(i,:) = genRandomHV(HV_DIMENSION);
        end
end
        
end

function CiM = initCiM

global HV_DIMENSION CIM_MODE INPUT_QUANTIZATION INPUT_WIDTH CiM_seedHV CiMMatrix

CiM = zeros(INPUT_QUANTIZATION,HV_DIMENSION);
for i = 1:size(CiM,1)
    CiM(i,:) = CiM_seedHV;
end

% nFlips = INPUT_QUANTIZATION-1;
flipBits = HV_DIMENSION/2/(INPUT_QUANTIZATION-1);

switch CIM_MODE
    case 'LUT'
        Ind = randperm(HV_DIMENSION);
        for i = 2:INPUT_QUANTIZATION
            for j = Ind(1:(i-1)*flipBits)
                if CiM(i,j) == 1
                    CiM(i,j) = 0;
                elseif CiM(i,j) == 0
                    CiM(i,j) = 1;
                end
            end
        end
    case 'direct_xor'
        widthVec = round(flipBits*2.^(0:INPUT_WIDTH-1));
        for i = 2:INPUT_QUANTIZATION
            sensorBin = de2bi(i-1,INPUT_WIDTH,'right-msb');
            start = 1;
            for j = 1:INPUT_WIDTH
                if sensorBin(j) == 1
                    for k = start:start+widthVec(j)-1
                        if CiM(i,k) == 1
                            CiM(i,k) = 0;
                        elseif CiM(i,k) == 0
                            CiM(i,k) = 1;
                        end
                    end
                end
                start = start + widthVec(j);
            end
        end
    case 'mapped_xor'
        for i = 2:INPUT_QUANTIZATION
            CiM(i,:) = double(xor(CiM(i-1,:),CiMMatrix(i-1,:)));
        end
end

end

function bnMatrix = initbnMatrix

global BUNDLE_NGRAM_CYCLES HV_DIMENSION

bnMatrix = zeros(BUNDLE_NGRAM_CYCLES,HV_DIMENSION);
for i = 1:BUNDLE_NGRAM_CYCLES
%     randIndex = randperm(HV_DIMENSION);
%     bnMatrix(i,randIndex(1:round(HV_DIMENSION/i))) = 1;
    for j = 1:HV_DIMENSION
        if rand < 1/i
            bnMatrix(i,j) = 1;
        end
    end
end

end

function CiMMatrix = initCiMMatrix

global HV_DIMENSION INPUT_QUANTIZATION

flipBits = HV_DIMENSION/2/(INPUT_QUANTIZATION-1);

randIndex = randperm(HV_DIMENSION);
CiMMatrix = zeros(INPUT_QUANTIZATION-1,HV_DIMENSION);
for i = 1:INPUT_QUANTIZATION-1
    for j = randIndex(round(flipBits*(i-1))+1:round(flipBits*(i)))
        CiMMatrix(i,j) = 1;
    end
end

end

function NHot_LUT = initNHot

global INPUT_QUANTIZATION

NHot_LUT = zeros(INPUT_QUANTIZATION,INPUT_QUANTIZATION-1);

for i = 2:INPUT_QUANTIZATION
    for j = 1:i-1
        NHot_LUT(i,j) = 1;
    end
end

end