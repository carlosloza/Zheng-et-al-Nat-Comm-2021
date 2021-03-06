function Figures3_4(DataDir, AnalysisDir, file_analysis_name, FiguresDir)
%FIGURE3_4 Function that plots Figure 3 and Figure 4
%   ARGUMENTS:
%       DataDir:            Raw data directory
%       AnalysisDir:        Directory to store analysis results
%       file_analysis_name: Name of file for meta-analysis
%       FiguresDir:         Directory to save figure(s). eps and fig format
%   RELEVANT FIGURES:
%       Fig3a, Fig3_bc, Fig4, Fig4_bc
%   NOTE: These scripts take a while to run
close all
clc
FuncDir = pwd;s
%%
ind = strfind(FuncDir,'MATLAB');
CodeDatCirDir = [FuncDir(1:ind+5) '\MainFunctions\Code & Data Circular Track'];
addpath(CodeDatCirDir)
BayesDecodDir = [FuncDir(1:ind+5) '\Dependencies\BayesianDecodingRipple'];
addpath(BayesDecodDir)
GenDir = [FuncDir(1:ind+5) '\GeneralFunctions'];
addpath(GenDir)
cd([FuncDir(1:ind+5) '\MainFunctions\Code & Data Circular Track'])
%%
file_analysis_name_ext = fullfile(AnalysisDir, file_analysis_name);
doall_get_gammaTFR_eachseq_EH(file_analysis_name_ext, DataDir);               
Stats_gammaTFR_eachseq_forMultiCompare(file_analysis_name_ext, FiguresDir, AnalysisDir)
BayesianDecodingExample(DataDir, FiguresDir)
%%
cd(FuncDir)
fprintf('Done! \n')
end