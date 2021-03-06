function Stats_gammaTFR_eachseq_forMultiCompare(file_out_name, FiguresDir, AnalysisDir)
%data_folder = 'E:\ColginLab\Data Analysis\GroupData\';
%fig_out = [parentfd,'\GroupData Figures'];

% FiguresDir = 'E:\ColginLab\Figures\Figures3_4';
% if ~isdir(FiguresDir)
%     mkdir(FiguresDir)
% end

%%file_input1 = 'group_gammaTFR_eachseq_20190529.mat'; % 4 rats % remove jumping-out points, ind_approach = 3;

% file_input1 = 'group_gammaTFR_eachseq_lowfirEEG_20190519.mat'; % 4 rats % remove jumping-out points, ind_approach = 3; use EEG with low firing
% file_input1 = 'group_gammaTFR_eachseq_ds_stable_20190525.mat'; % 4 rats % remove jumping-out points, ind_approach = 3;
% file_input1 = 'group_gammaTFR_eachseq_ds_unstable_20190525.mat'; % 4 rats % remove jumping-out points, ind_approach = 3;

%%file_input1 = strcat(data_folder,file_input1);

load(file_out_name)

numbins = 90; % Number of bins
bin_ang = 2*pi/numbins;
ang_bins = bin_ang/2:bin_ang:(2*pi-bin_ang/2);

pos_prdc = nan(Nseq,2);
pos_real = nan(Nseq,2);
dist_prdc_real = nan(Nseq,1);
vel = nan(Nseq,1);
for nseq = 1:Nseq
    min0 = min(Pxn_all{nseq,4});
    max0 = max(Pxn_all{nseq,4});
    pos_prdc(nseq,:) = [min0,max0];
    
    min0 = min(Pxn_all{nseq,6});
    max0 = max(Pxn_all{nseq,6});
    pos_real(nseq,:) = [min0,max0];
    
    dist_prdc_real(nseq) = min(abs(angle(exp((Pxn_all{nseq,4}'-Pxn_all{nseq,6})*1i))));
    vel(nseq,1) = mean(Pxn_all{nseq,7});
end
ang_bins0 = mean(diff(Ang_RewardLoc_ontrack));

% TFR
th1 = 6;                    % Theta rhythm (6 - 12 Hz)
th2 = 12;
[~,ind1] = min(abs(freq_TFR-th1));[~,ind2] = min(abs(freq_TFR-th2));
ind_th = [ind1,ind2];
tfrz_th_max = nan(Nseq,1);
for nseq = 1:Nseq
    tfrz0 = TFRz_all{nseq,2};
    tfrz0_mean = mean(tfrz0(th1:th2,:),2);
    tfrz_th_max(nseq,1) = max(tfrz0_mean);
end


%%
ncell = 3;
nspk = 5;
nmove = 1;

ind_seq = {};
ind_seq{1} = find(data_info(:,3) == 2 & ... % 1(Pre-run); 2(Sample); 3(Test); 4(Post-test)
    data_info(:,4) <= 8 & ... % trial number
    pos_real(:,2) < data_info(:,8) &... % stop location
    data_info(:,10) >= ncell & data_info(:,11) >= nspk & ...  % limit active cells number and spikes
    data_info(:,6) == 1 &...  % only correct or error trials
    data_info(:,12) > 0 &... % slope    
    data_info(:,13) >= .6 &... % replay score
    para_all(:,1) <= 20 &... % max jump (in bins)
    para_all(:,4) >= nmove &... % total distance moved (in bins)
    dist_prdc_real <= 5*bin_ang); % minimal distance between predicted and real locations
title12{1} = 'Correct sample trials';

ind_seq{2} = find(data_info(:,3) == 2 & ... % 1(Pre-run); 2(Sample); 3(Test); 4(Post-test)
    data_info(:,4) <= 8 & ... % trial number
    pos_real(:,2) < data_info(:,8) &... % stop location
    data_info(:,10) >= ncell & data_info(:,11) >= nspk & ...  % limit active cells number and spikes
    data_info(:,6) == 0 &...  % only correct or error trials
    data_info(:,12) > 0 &... % slope    
    data_info(:,13) >= .6 &... % replay score    
    para_all(:,1) <= 20 &... % max jump (in bins)
    para_all(:,4) >= nmove &... % total distance moved (in bins)
    dist_prdc_real <= 5*bin_ang);
title12{2} = 'Error sample trials';

ind_seq{3} = find(data_info(:,3) == 3 & ... % 1(Pre-run); 2(Sample); 3(Test); 4(Post-test)
    data_info(:,4) <= 8 & ... % trial number
    pos_real(:,2) < data_info(:,8) &... % stop location
    data_info(:,10) >= ncell & data_info(:,11) >= nspk & ...  % limit active cells number and spikes
    data_info(:,6) == 1 &...  % only correct or error trials
    data_info(:,12) > 0 &... % slope    
    data_info(:,13) >= .6 &... % replay score    
    para_all(:,1) <= 20 &... % max jump (in bins)
    para_all(:,4) >= nmove &... % total distance moved (in bins)
    dist_prdc_real <= 5*bin_ang);
title12{3} = 'Correct test trials';

ind_seq{4} = find(data_info(:,3) == 3 & ... % 1(Pre-run); 2(Sample); 3(Test); 4(Post-test)
    data_info(:,4) <= 8 & ... % trial number
    pos_real(:,2) < data_info(:,8) &... % stop location
    data_info(:,10) >= ncell & data_info(:,11) >= nspk & ...  % limit active cells number and spikes
    data_info(:,6) == 0 &...  % only correct or error trials
    data_info(:,12) > 0 &... % slope    
    data_info(:,13) >= .6 &... % replay score    
    para_all(:,1) <= 20 &... % max jump (in bins)
    para_all(:,4) >= nmove &... % total distance moved (in bins)
    dist_prdc_real <= 5*bin_ang);
title12{4} = 'Error test trials';

% Downsample Method1: 
% downsample ind_seq so that sequence# in each category are same
s = RandStream('mt19937ar','Seed',1); 
min0 = Nseq;
for itrial = 1:length(ind_seq)
    min0 = min(min0,length(ind_seq{itrial}));
end
for itrial = 1:length(ind_seq)
    if length(ind_seq{itrial}) > min0
        ind = datasample(s,1:length(ind_seq{itrial}),min0,'Replace',false);
        ind = sort(ind);
        ind_new = ind_seq{itrial}(ind);
        ind_seq_new{itrial} = ind_new;
    elseif length(ind_seq{itrial}) == min0
        ind_seq_new{itrial} = ind_seq{itrial};
    end
end


% % Downsample Method2: 
% % downsample ind_seq in each location area
% % so that sequence# within each location bin are same across trial types
% realloc_mean = nan(Nseq,1);
% predloc_max = nan(Nseq,1);
% for ii = 1:Nseq
%     realloc_mean(ii) = mean(Pxn_all{ii,6});
%     predloc_max(ii) = max(Pxn_all{ii,4});
% end
% dist_real_stop = realloc_mean-data_info(:,8);
% dist_pred_stop = predloc_max-data_info(:,8);
% 
% binw = mean(diff(Ang_RewardLoc_ontrack))*2;
% dist_bins = -binw*6:binw:binw*6;
% 
% ind_seq_new = cell(size(ind_seq));
% for i_r = 1:length(dist_bins)-1
%     ind_all = {};
%     len_all = [];
%     for itrial = 1:length(ind_seq)
%         dist_real_stop0 = dist_real_stop(ind_seq{itrial},:);
%         dist_pred_stop0 = dist_pred_stop(ind_seq{itrial},:);
%         ind_all{itrial} = find(dist_real_stop0 >= dist_bins(i_r) &...
%             dist_real_stop0 <= dist_bins(i_r+1) &...
%             dist_pred_stop0 >= dist_real_stop0);
%         len_all(itrial) = length(ind_all{itrial});
%     end
%     min0 = min(len_all);
%     
%     for itrial = 1:length(ind_seq)
%         if len_all(itrial) > min0
%             ind = datasample(s,1:len_all(itrial),min0,'Replace',false);
%             ind = sort(ind);
%             ind_new = ind_all{itrial}(ind);
%             ind_seq_new{itrial} = [ind_seq_new{itrial};ind_seq{itrial}(ind_new)];
%         elseif len_all(itrial) == min0
%             ind_seq_new{itrial} = [ind_seq_new{itrial};ind_seq{itrial}(ind_all{itrial})];
%         end
%     end
% end

% Bootstrap confidence interval parameters
s2=statset('bootci');
s2.UseSubstreams=true;
s2.Streams=RandStream('mlfg6331_64','Seed',1);
nBoot = 5000;

ind_seq_all = {ind_seq,ind_seq_new};
ind_Type = {'all','ds'};
ffa1 = figure('Units','normalized','Position',[0 0 1 1]);
ffa2 = figure('Units','normalized','Position',[0 0 1 1]);
ffa3 = figure('Units','normalized','Position',[0 0 1 .5]);
figh = [ffa1, ffa2];
for i1 = 1:length(ind_Type)
ind_seq = ind_seq_all{i1};

%% group data
Ntrial = length(ind_seq);
n_seq0 = cellfun(@length,ind_seq);
xspan0 = nan(max(n_seq0),Ntrial);
xspandif0 = nan(max(n_seq0),Ntrial);
tspan0 = nan(max(n_seq0),Ntrial);
slope0 = nan(max(n_seq0),Ntrial);
dist_forward0 = nan(max(n_seq0),Ntrial);
vel0 = nan(max(n_seq0),Ntrial);
realloc0_mean = nan(max(n_seq0),Ntrial);
predloc0_max = nan(max(n_seq0),Ntrial);
for itrial = 1:Ntrial
    Pxn0 = Pxn_all(ind_seq{itrial},:);
    TFRz0 = TFRz_all(ind_seq{itrial},:);
    data_info0 = data_info(ind_seq{itrial},:);
    
    for ii = 1:n_seq0(itrial)
        min0 = min(Pxn0{ii,4});
        max0 = max(Pxn0{ii,4});
        xspan0(ii,itrial) = max0-min0;
        xspandif0(ii,itrial) = max0-min0-(max(Pxn0{ii,6})-min(Pxn0{ii,6}));
        tspan0(ii,itrial) = Pxn0{ii,1}(end)+dt-step_param-Pxn0{ii,1}(1);
        slope0(ii,itrial) = data_info0(ii,12);
%         slope0(ii,itrial) = xspan0(ii,itrial)/tspan0(ii,itrial);
        dist_forward0(ii,itrial) = max(Pxn0{ii,4}-Pxn0{ii,6}');
        vel0(ii,itrial) = mean(Pxn0{ii,7});
        realloc0_mean(ii,itrial) = mean(Pxn0{ii,6});
        predloc0_max(ii,itrial) = max(Pxn0{ii,4});
    end
end

% ==========================================================================
% ==========================================================================
% measure0 = xspandif0;
% label0 = 'X-span diff (rad)';

% measure0 = xspan0;
% label0 = 'X-span(rad)';

measure0 = slope0;
label0 = 'Slope (rad/s)';

% measure0 = tspan0;
% label0 = 'Duration (s)';

% Matrix of sequence measure against dist(real-stop) and dist(pret-stop)
% Method 1: discrete bins

binw = mean(diff(Ang_RewardLoc_ontrack))*2;
dist_bins = -binw*7:binw:binw*7;
dist_bins_x = -2*6:2:2*8;

% binw = 0.4;
% dist_bins = -4:binw:4;

dist_bins_center = dist_bins_x+1;

X = [];
measure_x = {};
for itrial = 1:Ntrial
    data_info0 = data_info(ind_seq{itrial},:);
    extra = length(realloc0_mean(:,itrial))-size(data_info0,1);
    if extra > 0
        data_info0 = cat(1,data_info0,NaN(extra,size(data_info0,2)));
    end
    % circular distance
%     dist_real_stop0 = angle(exp((realloc0_mean(:,itrial)-data_info0(:,8))*1i));
%     dist_pred_stop0 = angle(exp((predloc0_max(:,itrial)-data_info0(:,8))*1i));
    
    % linear distance
    dist_real_stop0 = realloc0_mean(:,itrial)-data_info0(:,8);
    dist_pred_stop0 = predloc0_max(:,itrial)-data_info0(:,8);    
    % average sequence measure across all sequences in the individual x-axis bins
    measure0_x = nan(3,length(dist_bins)-1); % row1:mean; row2:CI_low; row3:CI_up
    X0 = [];
    len = 0;
    for i_r = 1:length(dist_bins)-1
        ind = find(dist_real_stop0 >= dist_bins(i_r) & dist_real_stop0 < dist_bins(i_r+1));
        len0 = length(ind);
        if ~isempty(ind)
            measure0_x(1,i_r) = mean(measure0(ind,itrial));
            
            measure0_x(2:3,i_r) = bootci(nBoot,{@nanmean,measure0(ind,itrial)},'Options',s2);
            measure0_x(2,i_r) = measure0_x(1,i_r)-measure0_x(2,i_r);
            measure0_x(3,i_r) = measure0_x(3,i_r)-measure0_x(1,i_r);
            reset(s2.Streams)
            
            X0(len+1:len+len0,2) = ones(len0,1)*i_r;
            X0(len+1:len+len0,3) = measure0(ind,itrial);
            len = len+len0;
        end
    end
    X0(:,1) = ones(len,1)*itrial;   
    
    measure_x = [measure_x,{measure0_x}];
    
    % make matrix for stats in SPSS
    X = [X;X0];
end

% Z: col1: samp1test2; col2:crt1err2
Z = nan(size(X));
ind = find(X(:,1)==1); Z(ind,1) = 1; Z(ind,2) = 1;
ind = find(X(:,1)==2); Z(ind,1) = 1; Z(ind,2) = 2;
ind = find(X(:,1)==3); Z(ind,1) = 2; Z(ind,2) = 1;
ind = find(X(:,1)==4); Z(ind,1) = 2; Z(ind,2) = 2;
Z(:,3:4) = X(:,2:3);

if strcmp(ind_Type{i1},'all')
    StatsData = array2table(Z(:,[3 2 1 4]),'VariableNames',{'PosBin','CrtErr','TrialType','Slope'});
    StatsData.TrialType = categorical(StatsData.TrialType);
    StatsData.CrtErr = categorical(StatsData.CrtErr);
    rmv = StatsData.PosBin==7;
    StatsData(rmv,:) = []; % remove data points after stop
    StatsData.PosBin = categorical(StatsData.PosBin);
    lm = fitlm(StatsData,'Slope ~ TrialType*CrtErr*PosBin');
    StatsOut.all = anova(lm,'component',3);
    
    % separate sample and test
    in = StatsData.TrialType == '1'; % sample
    lm = fitlm(StatsData(in,:),'Slope ~ CrtErr*PosBin');
    StatsOut.sample = anova(lm,'component',3);
    
    in = StatsData.TrialType == '2'; % test
    lm = fitlm(StatsData(in,:),'Slope ~ CrtErr*PosBin');
    StatsOut.test = anova(lm,'component',3);
end
% Plot v2: compare two conditions and plot them together
% tick_color = [0,20];
% figure('Units','normalized','Position',[0 0 0.5 0.8]);
% mat_all = mat0;
% for iplot = 1:length(mat_all)
%     subplot(2,2,iplot)
%     imagesc(dist_bins_x,dist_bins_x,mat_all{iplot},tick_color)
%     h = colorbar;
%     y = ylabel(h,label0,'FontSize',20,'HorizontalAlignment','center');
%     set(y, 'Units', 'Normalized', 'Position', [2.5, 0.5, 0]);
%     axis xy
%     hold on
%     plot(dist_bins_x,dist_bins_x,'k','LineWidth',2)
%     plot(dist_bins_x([1,end]),[0,0],'r--','LineWidth',2)
%     plot([0,0],dist_bins_x([1,end]),'r--','LineWidth',2)
%     hold off
%     set(gca,'XTick',dist_bins_x(1):1:dist_bins_x(end));
%     set(gca,'YTick',dist_bins_x(1):1:dist_bins_x(end));
%     set(gca,'fontsize',20);
% %     xlabel('Dist of CurrentLoc-StopLoc (rad)');
% %     ylabel('Dist of PredictLoc-StopLoc (rad)');
%     xlabel('Loc #');
%     ylabel('Loc #');
%     xlim([-16,16])
%     ylim([-16,16])
%     title(title12{iplot})
% end

color_samp_crt = [255,165,0]./255;
color_test_crt = [111,57,214]./255;
color_samp_err = [220,220,220]./255;
color_test_err = [40,40,40]./255;
color = {color_samp_crt,color_samp_err,color_test_crt,color_test_err};
for ff = 1:length(figh)
    if strcmp(ind_Type{i1},'all')
        figure(figh(ff))
        subplot(4,1,[3 4]);
        hold on
        for i = 1:length(measure_x)
            errorbar(dist_bins_center(1:6),measure_x{i}(1,1:6),measure_x{i}(2,1:6),measure_x{i}(3,1:6),'s-','LineWidth',1,'Color',color{i});
            %h1 = errorbar(dist_bins_center(1:6),measure_x{i}(1,1:6),measure_x{i}(2,1:6),measure_x{i}(3,1:6),'s-','LineWidth',1,'Color',color{i});
            %errorbar_tick(h1, 0);
        end
        lhd = legend(title12,'Location','SouthEast');
        set(lhd,'Box', 'off')
        hold off

        set(gca,'XTick',dist_bins_x(1):1:dist_bins_x(end));
        xlim([-12-1/ang_bins0,.5])
        ylim([0,max(ylim)])
        set(gca,'fontsize',16,'Box','off');
        % xlabel('Dist of CurrentLoc-StopLoc (rad)');
        xlabel('Loc #');
        ylabel(label0);
        colorbar
    end
end
%%
% ==========================================================================
% ==========================================================================
% allign stop location, and plot prediction line(regression line) with
% color showing slope
pxn_shift1 = cell(max(n_seq0),Ntrial);
predloc_shift1 = cell(max(n_seq0),Ntrial);
pxn_shift2 = cell(max(n_seq0),Ntrial);
predloc_shift2 = cell(max(n_seq0),Ntrial);
data_info_seq = cell(1,Ntrial);
Pxn0_seq = cell(1,Ntrial);
for itrial = 1:Ntrial
    Pxn0 = Pxn_all(ind_seq{itrial},:);
    data_info0 = data_info(ind_seq{itrial},:);
    Pxn0_seq{1,itrial} = Pxn0;
    data_info_seq{1,itrial} = data_info0;
    
    for ii = 1:n_seq0(itrial)
        pxn0 = Pxn0{ii,2};
        
        % NEED TO allign reward locations
        % shift Pxn so that the reward location align to pi
        Loc_reward = data_info0(ii,9);
        [~,indbin_rewardloc] = min(abs(ang_bins-Loc_reward));
        n_shift = numbins/2-indbin_rewardloc;
        pxn_shift1{ii,itrial} = circshift(pxn0,[n_shift,0]);
        predloc_shift1{ii,itrial} = Pxn0{ii,3}+n_shift;
        
        % NEED TO allign stop locations
        % shift Pxn so that the stop location align to pi
        Loc_stop = data_info0(ii,8);
        [~,indbin_rewardloc] = min(abs(ang_bins-Loc_stop));
        n_shift = numbins/2-indbin_rewardloc;
        pxn_shift2{ii,itrial} = circshift(pxn0,[n_shift,0]);
        predloc_shift2{ii,itrial} = Pxn0{ii,3}+n_shift;
    end
end


% Plot all prediction lines for all sequences - Figures 3 and 4, (c), (d),
% (e)
sign_plot = 1;
locNumb = -12:1;
if sign_plot && strcmp(ind_Type{i1},'ds')
    colorbin = 30;
    measure0_2 = reshape(measure0,size(measure0,1)*size(measure0,2),1);
    measure0_2_r = tiedrank(measure0_2);
    measure0_2_r = floor(measure0_2_r/(max(measure0_2_r)/colorbin));
    measure0_2_r(measure0_2_r==0)=1;
    measure0_r = reshape(measure0_2_r,size(measure0,1),size(measure0,2));
    
    % % NEED TO allign stop locations or reward locations
    
    cmap = colormap(cool(colorbin));
    for iplot = 1:Ntrial
        pxn0_shift = pxn_shift2(:,iplot);
        predloc_shift = predloc_shift2(:,iplot);
        if iplot<3
            figure(ffa1)
            figInd = 0;
        else
            figure(ffa2)
            figInd = 2;
        end
        subplot(4,1,iplot-figInd)
        hold on
        for ii = 1:length(pxn0_shift)
            pxn0_shift0 = pxn0_shift{ii};
            if isempty(pxn0_shift0)
                continue
            end
            predloc_shift0 = predloc_shift{ii}-numbins/2;
            len = length(predloc_shift0);
            ind1 = Pxn0_seq{iplot}{ii,5}(1); 
            ind2 = max(Pxn0_seq{iplot}{ii,5}(end),ind1+1);
            
            % x axis: loc relative to stop location
            Loc_reward = data_info_seq{iplot}(ii,8);
            [~,indbin_rewardloc] = min(abs(ang_bins-Loc_reward));
            if predloc_shift0(1)*bin_ang - (ang_bins(ind1)-ang_bins(indbin_rewardloc)) > pi
                predloc = [predloc_shift0([1,end])]*bin_ang-2*pi;
            elseif predloc_shift0(1)*bin_ang - (ang_bins(ind1)-ang_bins(indbin_rewardloc)) < -pi
                predloc = [predloc_shift0([1,end])]*bin_ang+2*pi;
            else
                predloc = [predloc_shift0([1,end])]*bin_ang;
            end
            plot([ang_bins(ind1),ang_bins(ind2)]-ang_bins(indbin_rewardloc),predloc,'color',cmap(measure0_r(ii,iplot),:),'LineWidth',0.25)
        end
        xlim([min(locNumb)*ang_bins0-1, (max(locNumb)-.5)*ang_bins0])
        ylim([min(locNumb)*ang_bins0-1, max(locNumb)*ang_bins0+1])
        plot(xlim,[0,0],'k--','LineWidth',1)
        hold off
        set(gca,'XTick',locNumb*ang_bins0,'XTickLabel',locNumb,'YTick',locNumb(5:8:end)*ang_bins0,'YTickLabel',locNumb(5:8:end))
        colormap cool        
        h = colorbar;
        set(h,'YTick',[1,colorbin]);
        set(h,'YTickLabel',{'min','max'});
        y = ylabel(h,label0,'FontSize',16,'HorizontalAlignment','center');
        set(y, 'Units', 'Normalized', 'Position', [2.5, 0.5, 0]);
        set(gca,'fontsize',16);
        ylabel('Predicted Loc #');
        title(title12{iplot})
    end
end

%% Plot ranked power against ranked slope - Sup Figure 11 (e)?
if strcmp(ind_Type{i1},'all')
    in_SG = freq_TFR>=25 & freq_TFR<55;
    in_FG = freq_TFR>=60 & freq_TFR<100;
    binWidth = 1/5;
    powerAxis = 0:binWidth:1;
    ha3 = zeros(Ntrial,1);
    for itrial = 1:Ntrial
           spect0 = TFRz_all(ind_seq{itrial},2);
           SG_ranked = NaN(length(spect0),1);
           FG_ranked = NaN(length(spect0),1);
           for i2 = 1:length(spect0)
               SG_ranked(i2) = nanmean(nanmean(spect0{i2}(in_SG,:)));
               FG_ranked(i2) = nanmean(nanmean(spect0{i2}(in_FG,:)));
           end
           SG_ranked = tiedrank(SG_ranked)/length(SG_ranked);
           FG_ranked = tiedrank(FG_ranked)/length(FG_ranked);

           slope0 = data_info(ind_seq{itrial},12);
           slope_ranked = tiedrank(slope0)/length(slope0);

           [~,powerInd_SG] = histc(SG_ranked,powerAxis);
           [~,powerInd_FG] = histc(FG_ranked,powerAxis);

           meanSlope_SG = zeros(1,length(powerAxis)-1);
           meanSlope_FG = zeros(1,length(powerAxis)-1);
           errorSlope_SG = zeros(2,length(powerAxis)-1);
           errorSlope_FG = zeros(2,length(powerAxis)-1);
           for pp = 1:length(powerAxis)-1
               in = powerInd_SG == pp;
               meanSlope_SG(pp) = nanmean(slope_ranked(in));
               errorSlope_SG(:,pp) = bootci(nBoot,{@nanmean,slope_ranked(in)},'Options',s2);
               errorSlope_SG(1,pp) = meanSlope_SG(pp)-errorSlope_SG(1,pp);
               errorSlope_SG(2,pp) = errorSlope_SG(2,pp)-meanSlope_SG(pp);
               
               in = powerInd_FG == pp;
               meanSlope_FG(pp) = nanmean(slope_ranked(in));
               errorSlope_FG(:,pp) = bootci(nBoot,{@nanmean,slope_ranked(in)},'Options',s2);
               errorSlope_FG(1,pp) = meanSlope_FG(pp)-errorSlope_FG(1,pp);
               errorSlope_FG(2,pp) = errorSlope_FG(2,pp)-meanSlope_FG(pp);
               reset(s2.Streams)
           end
           figure(ffa3)
           ha3(itrial) = subplot(1,Ntrial,itrial); hold on
           h1 = errorbar(powerAxis(1:end-1)+binWidth/2,meanSlope_SG,errorSlope_SG(1,:),errorSlope_SG(2,:),'s-','LineWidth',1,'Color','b');
           %h1 = errorbar(powerAxis(1:end-1)+binWidth/2,meanSlope_SG,errorSlope_SG(1,:),errorSlope_SG(2,:),'s-','LineWidth',1,'Color','b');
           %errorbar_tick(h1, 0);
           h2 = errorbar(powerAxis(1:end-1)+binWidth/2,meanSlope_FG,errorSlope_FG(1,:),errorSlope_FG(2,:),'s-','LineWidth',1,'Color','r');
           %h2 = errorbar(powerAxis(1:end-1)+binWidth/2,meanSlope_FG,errorSlope_FG(1,:),errorSlope_FG(2,:),'s-','LineWidth',1,'Color','r');
           %errorbar_tick(h2, 0);
           title(title12{itrial})
           xlabel('Ranked power')
           axis square
           if itrial == 1
               ylabel('Ranked slope')
           elseif itrial == Ntrial
               lhd = legend([h1,h2],'SG','FG');
               set(lhd,'Box', 'off')
           end
    end
    linkaxes(ha3,'y')
    ylim([0.4 0.58])
    % Save selected figures - not necessary
    %saveas(ffa3,[FiguresDir,'\SeqSlopePower'],'epsc')
    %saveas(ffa3,[FiguresDir,'\SeqSlopePower'],'fig')
end
end
%% Save selected figures
saveas(ffa1,[FiguresDir,'\Fig4_bc'],'epsc')
saveas(ffa1,[FiguresDir,'\Fig4_bc'],'fig')
saveas(ffa2,[FiguresDir,'\Fig3_bc'],'epsc')
saveas(ffa2,[FiguresDir,'\Fig3_bc'],'fig')
close all

%% Save stats output
save([AnalysisDir,'\Stats_SeqSlope.mat'],'StatsOut','StatsData')
end