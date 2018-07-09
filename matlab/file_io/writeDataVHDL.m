% Writes all required data into the VHDL packages:
% Parameters, Connectivity Matrices, Lookup Tables, Seed Vectors

%% Parameters

outputFilenameParameters = '../vhdl/source/hdc_pkg.vhd';
templateFilenameParameters = '../vhdl/templates/hdc_pkg_temp.vhd';
insertDataParameters = {HV_DIMENSION,...
                        INPUT_CHANNELS,...
                        INPUT_QUANTIZATION,...
                        NGRAM_SIZE,...
                        CLASSES,...
                        BUNDLE_CHANNEL_BITS,...
                        BUNDLE_NGRAM_BITS,...
                        BUNDLE_NGRAM_CYCLES,...
                        AM_BLOCK_WIDTH,...
                        ['''' num2str(mode_train) ''''],...
                        ['''' num2str(mode_predict) '''']};
insertPositionsParameters = [53:61 72:73];

fileInsertParameters(outputFilenameParameters,templateFilenameParameters,...
                     insertDataParameters,insertPositionsParameters);


%% Baseline Architecture Constants

outputFilename_initBaseline = '../vhdl/source/hdc_baseline_pkg.vhd';
templateFilename_initBaseline = '../vhdl/templates/hdc_baseline_pkg_temp.vhd';
insertData_initBaseline = {iM,CiM};
insertPositions_initBaseline = [41,45];

fileInsertMatrix(outputFilename_initBaseline,templateFilename_initBaseline,...
                 insertData_initBaseline,insertPositions_initBaseline);


%% Improved Architecture Constants

outputFilename_initImproved = '../vhdl/source/hdc_enhanced_pkg.vhd';
templateFilename_initImproved = '../vhdl/templates/hdc_enhanced_pkg_temp.vhd';
insertData_init = {NHot_LUT,iM_seedHV,CiM_seedHV,iMMatrix,CiMMatrix,bnMatrix};
insertPositions_init = 41:4:61;

fileInsertMatrix(outputFilename_initImproved,templateFilename_initImproved,...
                 insertData_init,insertPositions_init);
