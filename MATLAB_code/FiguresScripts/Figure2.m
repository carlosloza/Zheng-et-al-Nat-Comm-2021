%% Figure 2: Predictive firing developed with learning - DONE

function Figure2
clearvars
close all
clc
FiguresDir = pwd;

%%
genFDir = '..\GeneralFunctions';
addpath(genFDir)
ind = strfind(FiguresDir,'MATLAB');
CoDatCirDir = [FiguresDir(1:ind+5) '\MainFunctions\Code & Data Circular Track'];
addpath(CoDatCirDir)
cd([FiguresDir(1:ind+5) '\MainFunctions\Code & Data Circular Track'])

%%
AnalysisDir = 'E:\ColginLab\Data Analysis\GroupData\';
FiguresDir = 'E:\ColginLab\Figures\Figure2';
doall_group_Pxn(AnalysisDir)
close all
Stats_PxnSum_CI_Fig2

%%
cd(FiguresDir)
fprintf('Done! \n')
end