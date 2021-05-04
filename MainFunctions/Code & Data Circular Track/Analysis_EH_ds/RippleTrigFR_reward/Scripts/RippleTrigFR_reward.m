function RippleTrigFR_reward(DataFD,AnalysisFD,spktime_fd)

if exist(strcat(AnalysisFD,'\LapFRcorr\LapFRcorr.mat'),'file') ~= 2
    error('Please run RunPlaceCellPropertiesAcrossLap_v4.m first')
else
    load(strcat(AnalysisFD,'\LapFRcorr\LapFRcorr.mat'))
end

if exist(strcat(AnalysisFD,'\BayesianDecoding_ripple\BayesianDecodingResult.mat'),'file') ~= 2
    error('Please run RunBayesianDecoder_ripple.m first')
else
    load(strcat(AnalysisFD,'\BayesianDecoding_ripple\BayesianDecodingResult.mat'))
end

outdir = strcat(AnalysisFD,'\RippleTrigFR_reward');
if ~isdir(outdir)
    mkdir(outdir)
end

Output = [];
ratID = fieldnames(LapFRcorr);
for rr = 1:length(ratID)
    dateID = fieldnames(LapFRcorr.(ratID{rr}));
    DateFd = translateDateID(dateID);
    for dd = 1:length(DateFd)
        % Load reward position
        if DateFd{dd}(end) == 'T'
            trackfile = strcat(DataFD,'\',ratID{rr},'\',DateFd{dd},'\',dateID{dd}(2:9),'_CT_tracking.mat');
        else
            trackfile = strcat(DataFD,'\',ratID{rr},'\',DateFd{dd},'\',dateID{dd}(2:9),'_CT_tracking_',dateID{dd}(end),'.mat');
        end
        trackdata = load(trackfile);
        trackdata.sign_correct_sample(isnan(trackdata.sign_correct_sample)) = false;
        rewardPos = mode(trackdata.ang_sample_reward_ontrack(logical(trackdata.sign_correct_sample)));
        ind = match(rewardPos,trackdata.Ang_RewardLoc_ontrack);
        if ind == 1
            rewardPos_range = [rewardPos-(trackdata.Ang_RewardLoc_ontrack(ind+1)-rewardPos)/2 (trackdata.Ang_RewardLoc_ontrack(ind+1)+rewardPos)/2];
        elseif ind == length(trackdata.Ang_RewardLoc_ontrack)
            rewardPos_range = [(trackdata.Ang_RewardLoc_ontrack(ind-1)+rewardPos)/2 rewardPos+(rewardPos-trackdata.Ang_RewardLoc_ontrack(ind-1))/2];
        else
            rewardPos_range = [(trackdata.Ang_RewardLoc_ontrack(ind-1)+rewardPos)/2 (trackdata.Ang_RewardLoc_ontrack(ind+1)+rewardPos)/2];
        end
        % Obtain correct trials
        CorrectTest = find(trackdata.sign_correct_test==1);
        CorrectPostTest = find(trackdata.sign_correct_posttest==1);
        % Obtain position tunning
        FR_SampleTestRun = nanmean(cat(3,LapFRcorr.(ratID{rr}).(dateID{dd}).Sample.lapFR,...
                                         LapFRcorr.(ratID{rr}).(dateID{dd}).Test.lapFR,...
                                         LapFRcorr.(ratID{rr}).(dateID{dd}).Postrunning.lapFR),3);
        %FR_SampleTestRun = nanmean(LapFRcorr.(ratID{rr}).(dateID{dd}).Prerunning.lapFR,3);
        posaxis = LapFRcorr.(ratID{rr}).(dateID{dd}).Sample.posbinaxis;
        cellID = LapFRcorr.(ratID{rr}).(dateID{dd}).Sample.cellID;
        if ~isfield(BayesianDecodingResult.(ratID{rr}),dateID{dd})
            continue
        end
        [cellID,ind1,ind2] = intersect(BayesianDecodingResult.(ratID{rr}).(dateID{dd}).cellID,cellID);
        % Select cells with place fields near reward position
        ind = match(rewardPos_range,posaxis/360*2*pi);
        ActiveNearReward = max(FR_SampleTestRun(ind2,ind(1):ind(2)),[],2) >= 1;
        ActiveOnTrack = max(FR_SampleTestRun(ind2,:),[],2) >= 1;
        % Select cells with place fields near rest box
        restPos_range = [trackdata.Ang_StartZone_depart_ontrack trackdata.Ang_StartZone_arrive_ontrack];
        ind = match(restPos_range,posaxis/360*2*pi);
        logical_ind = false(size(posaxis));
        logical_ind(1:ind(1)) = true; logical_ind(ind(2):end) = true; % rest box located near 0 on circular track
        ActiveNearRest= max(FR_SampleTestRun(ind2,logical_ind),[],2) >= 1;
        % Obtain ripple triggerred spike raster
        spikeIndfile = strcat(DataFD,'\',ratID{rr},'\',DateFd{dd},'\',spktime_fd,'\spike_index.mat');
        load(spikeIndfile);
        sampfreq = 2000; % in Hz
        timebin = 1/sampfreq; % in sec
        timeVec = -.5:timebin:.5;
        inrange = match([-.4 .4],timeVec);
        smoothTimebin = .02; % in sec

        RippleMeanFR = BayesianDecodingResult.(ratID{rr}).(dateID{dd}).RippleFR(ind1,:);        
        RippleOnsetIndex = BayesianDecodingResult.(ratID{rr}).(dateID{dd}).RippleOnsetIndex;
        sessionType = BayesianDecodingResult.(ratID{rr}).(dateID{dd}).sessionType;
        sType = unique(sessionType);
        for ss = 1:length(sType)
            in = strcmp(sessionType,sType{ss});
            if ~isfield(Output,sType{ss});
                Output.(sType{ss}).RippleTrigFR = [];
                Output.(sType{ss}).RippleTrigFRdiff = [];
                Output.(sType{ss}).RippleMeanFR = [];
                Output.(sType{ss}).CellID = [];
                Output.(sType{ss}).ActiveNearReward = [];
                Output.(sType{ss}).ActiveOnTrack = [];
                Output.(sType{ss}).ActiveNearRest = [];
                Output.(sType{ss}).timeVec = timeVec(inrange(1):inrange(2));
            end
            if strcmp(sType{ss},'PostTest')
                correct = ismember(BayesianDecodingResult.(ratID{rr}).(dateID{dd}).NTrial_post(in),CorrectPostTest);
            elseif strcmp(sType{ss},'PreRun')
                correct = false(size(RippleOnsetIndex(in)));
            else
                correct = ismember(BayesianDecodingResult.(ratID{rr}).(dateID{dd}).NTrial(in),CorrectTest);
            end
            for cc = 1:length(cellID)
                spkind = spike_ind.(cellID{cc});
                dt = repmat(spkind,1,length(RippleOnsetIndex(in)))-repmat(RippleOnsetIndex(in)',length(spkind),1);
                [~,rippleN] = find(abs(dt)<=max(timeVec)*sampfreq);
                dt_inrange = dt(abs(dt)<=max(timeVec)*sampfreq);
                tInd = match(dt_inrange,timeVec*sampfreq);
                ripple_tri_spkraster = false(length(RippleOnsetIndex(in)),length(timeVec));
                for jj = 1:length(rippleN)
                    ripple_tri_spkraster(rippleN(jj),tInd(jj)) = true;
                end
                FR = mean(ripple_tri_spkraster)*sampfreq;
                kernel = gausskernel(size(ripple_tri_spkraster,2)/2,sampfreq*smoothTimebin);
                sFR = conv(FR,kernel,'same');
                if ~strcmp(sType{ss},'PreRun')
                    FRdiff = mean(ripple_tri_spkraster(correct,:))-mean(ripple_tri_spkraster(~correct,:));
                else
                    FRdiff = zeros(size(timeVec));
                end
                sFRdiff = conv(FRdiff,kernel,'same');

                Output.(sType{ss}).RippleTrigFR = cat(1,Output.(sType{ss}).RippleTrigFR,sFR(inrange(1):inrange(2)));
                Output.(sType{ss}).RippleTrigFRdiff = cat(1,Output.(sType{ss}).RippleTrigFRdiff,sFRdiff(inrange(1):inrange(2)));                
            end
            ind = strcmp(BayesianDecodingResult.(ratID{rr}).(dateID{dd}).RippleFR_xlabel,sType{ss});
            Output.(sType{ss}).RippleMeanFR = cat(1,Output.(sType{ss}).RippleMeanFR,RippleMeanFR(:,ind));
            Output.(sType{ss}).CellID = cat(1,Output.(sType{ss}).CellID,cellID);
            Output.(sType{ss}).ActiveNearReward = cat(1,Output.(sType{ss}).ActiveNearReward,ActiveNearReward);
            Output.(sType{ss}).ActiveNearRest = cat(1,Output.(sType{ss}).ActiveNearRest,ActiveNearRest);
            Output.(sType{ss}).ActiveOnTrack = cat(1,Output.(sType{ss}).ActiveOnTrack,ActiveOnTrack);
        end
    end
end

%% Make plots
h = figure;
set(h,'OuterPosition',[-9,137,1779,910])
sType = fieldnames(Output);
sType = sType([4 2 1 3]);
ha = zeros(2,length(sType));
for ss = 1:length(sType)
    timeVec = Output.(sType{ss}).timeVec;
    RippleTrigFR = Output.(sType{ss}).RippleTrigFR;
    ActiveNearReward = Output.(sType{ss}).ActiveNearReward;
    ActiveNearRest = Output.(sType{ss}).ActiveNearRest;
    ActiveOnTrack = Output.(sType{ss}).ActiveOnTrack;
    t_range = match(-.4,timeVec):match(-.1,timeVec);
    baseline = repmat(median(RippleTrigFR(:,t_range),2),1,size(RippleTrigFR,2));
    RippleTrigFR_norm = RippleTrigFR./baseline*100;   
    
    cellType = [(ActiveNearReward==1 & ActiveNearRest==0 & ActiveOnTrack==1)...
        ,(ActiveNearReward==0 & ActiveNearRest==0 & ActiveOnTrack==1)...
        ,(ActiveNearReward==0 & ActiveNearRest==1 & ActiveOnTrack==1)];
    cellType_label = {'Reward','NonReward','Rest'};
    clabel = {'-r','-b','-k'};
    ha(1,ss) = subplot(2,length(sType),ss); hold on
    for cc = 1:size(cellType,2)
        in = cellType(:,cc);
        FR = RippleTrigFR(in,:);
        CI = bootci(1000,@median,FR);
        shadedErrorBar(timeVec,median(FR),[CI(2,:)-median(FR); median(FR)-CI(1,:)],clabel{cc});
    end
    axis tight square
    title(sType{ss})
    if ss == 1
        ylabel('Firing rate (Hz)')
    end
    
    ha(2,ss) = subplot(2,length(sType),ss+length(sType)); hold on
    ha2 = zeros(size(cellType,2),1);
    cellType_label2 = cell(size(cellType_label));
    for cc = 1:size(cellType,2)
        in = cellType(:,cc);
        FRnorm = RippleTrigFR_norm(in,:);
        CI = bootci(1000,@nanmedian,FRnorm);
        temp = shadedErrorBar(timeVec,nanmedian(FRnorm),[CI(2,:)-nanmedian(FRnorm); nanmedian(FRnorm)-CI(1,:)],clabel{cc});
        ha2(cc) = temp.mainLine;
        cellType_label2{cc} = [cellType_label{cc},' n=(',num2str(sum(in)),')'];
    end
    axis tight square
    if ss == length(sType)
        legend(ha2,cellType_label2)
    elseif ss == 1
        ylabel('Normalized firing rate')
    end
    xlabel('Time since ripple onset (sec)')   
end
linkaxes(ha(1,:),'y')
linkaxes(ha(2,:),'y')
saveas(h,strcat(outdir,'\RippleTrigFR_allCondition'),'epsc')
saveas(h,strcat(outdir,'\RippleTrigFR_allCondition'),'png')
close(h)

sType = fieldnames(Output);
sType = sType([4 2 1 3]);
RippleMeanFR = zeros(length(Output.PostTest.CellID),length(sType));
for ss = 1:length(sType)
    RippleMeanFR(:,ss) = Output.(sType{ss}).RippleMeanFR;
end

h = figure; hold on
set(h,'OuterPosition',[-9,137,1779,910])
ActiveNearReward = Output.PostTest.ActiveNearReward;
ActiveNearRest = Output.PostTest.ActiveNearRest;
ActiveOnTrack = Output.PostTest.ActiveOnTrack;
cellType = [(ActiveNearReward==1 & ActiveNearRest==0 & ActiveOnTrack==1)...
        ,(ActiveNearReward==0 & ActiveNearRest==0 & ActiveOnTrack==1)];...
        %,(ActiveNearReward==0 & ActiveNearRest==1 & ActiveOnTrack==1)];
    cellType_label = {'Reward','NonReward'};
clabel = {'-r','-b','-k'};
legstr = cell(length(cellType_label),1);
for cc = 1:length(cellType_label)
    ha1 = subplot(1,2,1); hold on
    in = cellType(:,cc) & RippleMeanFR(:,1)>0;
    rippleFR = RippleMeanFR(in,:);
    CI = bootci(5000,@mean,rippleFR);
    errorValue = [mean(rippleFR)-CI(1,:); CI(2,:)-mean(rippleFR)];
    errorbar(1:length(sType),mean(rippleFR),errorValue(1,:),errorValue(2,:),clabel{cc})
    legstr{cc} = strcat(cellType_label{cc},'(n=',num2str(sum(in)),')');
    
    ha2 = subplot(1,2,2); hold on
    rippleFR = RippleMeanFR(in,:)./repmat(RippleMeanFR(in,1),1,length(sType))*100;
    CI = bootci(5000,@mean,rippleFR);
    errorValue = [mean(rippleFR)-CI(1,:); CI(2,:)-mean(rippleFR)];
    errorbar(1:length(sType),mean(rippleFR),errorValue(1,:),errorValue(2,:),clabel{cc})
end
set([ha1 ha2],'XTick',1:length(sType),'XTickLabel',sType)
legend(ha1,legstr)
axis([ha1 ha2],'square')
ylabel(ha1,'Ripple firing rate (Hz)')
ylabel(ha2,'Normalized ripple firing rate (%)')

saveas(h,strcat(outdir,'\RippleMeanFR'),'epsc')
saveas(h,strcat(outdir,'\RippleMeanFR'),'png')
close(h)
%% Repeated-measured ANOVA
celltype = cell(size(cellType,1),1);
for ii = 1:size(cellType,2)
    celltype(cellType(:,ii)) = repmat(cellType_label(ii),sum(cellType(:,ii)),1);
end
rmv = cellfun(@isempty,celltype);
celltype(rmv) = [];
TimePoint = RippleMeanFR(~rmv,:);
t=[cell2table(celltype) array2table(TimePoint)];
TimePoint = table((1:size(TimePoint,2))','VariableNames',{'TimePoint'});
rm = fitrm(t,['TimePoint1-TimePoint',num2str(size(TimePoint,1)),'~celltype'],'WithinDesign',TimePoint);
Stats.raw.ANOVA = ranova(rm);
Stats.raw.posthoc = multcompare(rm,'TimePoint','By','celltype');
Stats.raw.posthoc2 = multcompare(rm,'celltype');

TimePoint = RippleMeanFR(~rmv,:)./repmat(RippleMeanFR(~rmv,1),1,length(sType))*100;
t=[cell2table(celltype) array2table(TimePoint)];
TimePoint = table((1:size(TimePoint,2))','VariableNames',{'TimePoint'});
rm = fitrm(t,['TimePoint1-TimePoint',num2str(size(TimePoint,1)),'~celltype'],'WithinDesign',TimePoint);
Stats.norm.ANOVA = ranova(rm);
Stats.norm.posthoc = multcompare(rm,'TimePoint');

%% Export analysis results and all the necessary scripts
FunctionPath = mfilename('fullpath');
FunctionName = mfilename;
OutScript_dir = strcat(outdir,'\Scripts');
if isdir(OutScript_dir)
    rmdir(OutScript_dir,'s')
end
mkdir(OutScript_dir)
[fList] = matlab.codetools.requiredFilesAndProducts(FunctionPath);
for ff = 1:length(fList)
    [~,fname,ext] = fileparts(fList{ff});
    copyfile(fList{ff},strcat(OutScript_dir,'\',fname,ext));
end
save(strcat(outdir,'\RippleTrigFRdata.mat'),'Output','FunctionName')
save(strcat(outdir,'\Stats.mat'),'Stats')

function DateFd = translateDateID(dateID)
DateFd = cell(size(dateID));
for dd = 1:length(dateID)
    str = dateID{dd};
    str2 = strcat(str(2:5),'-',str(6:7),'-',str(8:9),'-',str(10:11));
    if length(str) > 11
        str2 = strcat(str2,'-',str(end));
    end
    DateFd{dd} = str2;
end
    