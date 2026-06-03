%% =========================================================================
% Ghaderi2025_ExtendedData_Figure11_ab_NullPotent_GoNogo.m
% =========================================================================
%
% This script generates Figure 5Sup1 showing neuronal activity projection on Null potent subspace  
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description:
% ..............................
% Dependencies:
%   - Area_list.mat (contains brain area information)
%   - psth_10ms.mat (contains trial data)
%   - Movement_subspace.mat (contains ROC analysis results)
% =========================================================================

%% Clear workspace and set up environment
clear all
close all
clc

%% Option Same Y scaling for PSTHs

Option_Scaling=true;
PSTH_Scale=[-2 5];

%% Optional: Change figure name (set to 1 to enable)
change_name = 0;
newname = 'Figure4A_ROC_PSTH_Combined';
fullname = mfilename('fullpath');
inds = regexp(fullname, '\', 'all');
name = fullname(inds(end)+1:end);

if change_name
    movefile([name '.m'], [newname '.m']);
end

%% Load required data

CurrentDir=pwd;
directory=CurrentDir;

load([directory filesep 'processed_data' filesep 'psth_10ms.mat'])
load([directory filesep 'processed_data' filesep 'Movement_subspace.mat']) 


%%

parent=figure('Units','centimeters','Position',[1 1 21 25],'PaperType','A4','PaperUnits','centimeters','PaperSize',[21 29.7],'PaperPosition',[1 1 20 25]);
h = tight_subplot(5,2,[.1 .1],[.1 .03],[.1 .1])
axs=findall(gcf, 'type', 'axes');
axs=flipud(axs)
sgtitle(parent,' Movements Potent subspace                        Movements Null subspace    ')
params.QuietState='All_trials'   % 'Quiet_(whisker_speed)' 'Quiet_(jaw_movement)' 'Quiet_(jaw & whisker)' 'Non_quiet' 'All_trials'
params.BaselineSubtraction=0
params.completion_state= 'completed_trials'   %options 'early_licks'  'completed_trials'
params.TrialType=[3,1]   % 1: gotone/whisker  2: gotone/nowhisker 3: nogotone/whisker  4: nogotone/nowhisker  5: notone/whisker
params.LickState =[0,1]  % lick 1: lick  0:nolick
params.CellType='All'           % 'RS' 'FS' 'RS_FS' 'All'
regionlist={'A1','wS1','wS2','wM2','ALM'}       % 'ALM','wM2','wS2','wS1','A1','tjM1'
t_start=-1  % t start
t_end=2   % t end
bin_width=0.01
XTickLabel={'-1';'0';'1';'2'}
xtick=[-1;0;1;2]

% movements
movements_signals={'whisker_speed','snout_angle','piezo_lick_trace','jaw_movement','tongue_movement'}  %'whisker_speed','snout_angle','piezo_lick_trace','jaw_movement','tongue_movement'
movements_signals_tag={'Whisker speed (pixel/s)','Snout angle (degree)','Piezo lick (mv)','Jaw (pixel)','Tongue (pixel)'};  %'whisker_speed','snout_angle','piezo_lick_trace','jaw_movement','tongue_movement'
colorcodes=[1 0 0;0 0 1]
colormaps={'#0008FF';'#228B22';'#00C3FF';'#FF0000';'#FF7F00';'#000000';'#00C3FF';'#FF7F00';'#FF7F00';'#808080';'#6B3686';'#74B99A';'#A020F0';'#FFD700'};colortype={'wS1';'wS2';'CR2';'ALM';'CR4';'wM2';'FA2';'FA3';'FA4';'FA5';'Lick';'NoLick';'A1';'tjM1'};
Map=horzcat(colortype,colormaps);
shift_y_values=[-5,10,20,40,65]

cnt_area=0

for ind_area=1:length(regionlist)
    CurrentArea=cell2mat(regionlist(ind_area));



        for ind_condition=1:length(params.TrialType)

    ind_sessions=find(strcmp(CurrentArea,[psth_mat.probe_location]));
    session_counter=1
        current_null_condition=[];
        current_potent_condition=[];
    for ind_session=ind_sessions
            % ids of quesense
            Trial=psth_mat(ind_session).trial_type;
            Lick= psth_mat(ind_session).lick_flag;
            % conditions
            IndTrialType=Trial==params.TrialType(ind_condition);
            IndLickstate=Lick==params.LickState(ind_condition);
            % id of completion
            switch params.completion_state
                case 'completed_trials'
                    completion_state=~psth_mat(ind_session).early_lick;
                case 'early_licks'
                    early_licks_all=psth_mat(ind_session).early_lick;
                    lick_time=0<(psth_mat(ind_session).lick_time-psth_mat(ind_session).start_time);
                    completion_state=lick_time & early_licks_all;
            end

            CurrTrialInd=[completion_state & IndLickstate & IndTrialType];
            current_null=mov_potent_null(ind_session).null;
            current_potent=mov_potent_null(ind_session).potent;

        if isempty(current_null)
            continue
        end
            current_null_condition=[current_null_condition,sum(squeeze(mean(current_null(:,CurrTrialInd,:),2)).^2,2)];
            current_potent_condition=[current_potent_condition,sum(squeeze(mean(current_potent(:,CurrTrialInd,:),2)).^2,2)];
            WindowCenters=psth_mat(ind_session).trial_timestamps ;   % change later
             session_counter=session_counter+1
    end  % end over session
        [a,b]=min(abs(WindowCenters-t_start)),Win(1)=(b)
        [a,b]=min(abs(WindowCenters-t_end)),Win(2)=(b)
        signal2plot_potent=current_potent_condition(Win(1):Win(2),:);
        signal2plot_null=current_null_condition(Win(1):Win(2),:);
        time2plot=WindowCenters(Win(1):Win(2));
        %   plot potent subspace
        colorcode=colorcodes(ind_condition,:)
        meansig=nanmean(signal2plot_potent,2);
        semsig=nanstd(signal2plot_potent,[],2)./sqrt(size(signal2plot_potent,2));
        curve1 = meansig+semsig;
        curve2 = meansig-semsig;
        x2 = [time2plot',fliplr(time2plot')];
        inBetween = [curve1', fliplr(curve2')];
        fill(axs(2*ind_area-1),x2, inBetween ,colorcode,'FaceAlpha',0.2,'LineStyle','none');
        hold (axs(2*ind_area-1),'on')
        plot(axs(2*ind_area-1),time2plot,meansig,'color',colorcode,'linewidth',1)
       

       if Option_Scaling
          ylim(axs(2*ind_area-1),PSTH_Scale)
       else
          ylim(axs(2*ind_area-1),[-5 60])
       end

        xline(axs(2*ind_area-1),[0 1])
        %   plot null subspace
        meansig=nanmean(signal2plot_null,2);
        semsig=nanstd(signal2plot_null,[],2)./sqrt(size(signal2plot_null,2));
        curve1 = meansig+semsig;
        curve2 = meansig-semsig;
        x2 = [time2plot',fliplr(time2plot')];
        inBetween = [curve1', fliplr(curve2')];
        fill(axs(2*ind_area),x2, inBetween ,colorcode,'FaceAlpha',0.2,'LineStyle','none');
        hold (axs(2*ind_area),'on')
        plot(axs(2*ind_area),time2plot,meansig,'color',colorcode,'linewidth',1)
        ylabel(axs(2*ind_area-1),'Activity magnitude(a.u)')
        xline(axs(2*ind_area),[0 1])
        end %end of condition
     title(axs(2*ind_area-1),CurrentArea);title(axs(2*ind_area),CurrentArea)
    cnt_area=cnt_area+1;
end

if Option_Scaling

        ylim(axs(2),PSTH_Scale)
         ylim(axs(4),PSTH_Scale)
         ylim(axs(6),PSTH_Scale)
         ylim(axs(8),PSTH_Scale)
         ylim(axs(10),PSTH_Scale)

else
         ylim(axs(2),[-10 200])
         ylim(axs(4),[-10 200])
         ylim(axs(6),[-10 200])
         ylim(axs(8),[-5 25])
         ylim(axs(10),[-5 25])

end
       xlabel(axs(10),'Time(s)')
        xlabel(axs(9),'Time(s)')
legend_just_txt(axs(1),{'Nogo-tone whisker','Go-tone whisker'},'Xoffset',1,'Yoffset',40,'relX',0,'relY',0.12,'type','line');
prettify_plot('LineThickness', 1,'TickWidth',1.5,'AxisTightness', 'keep','TickLength',[.01 .01],'PointSize','keep')

%% Export figure
directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');





