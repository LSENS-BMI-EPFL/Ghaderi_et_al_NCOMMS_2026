

%%
%% Clear workspace and set up environment
clear all
close all
clc

%% Optional: Change figure name

change_name = 0;
newname = 'Figure7Sup2A_all';
fullname = mfilename('fullpath');
inds = regexp(fullname,'\','all');
name = fullname(inds(end)+1:end);
if change_name
    movefile([name '.m'],[newname '.m']);
end


%% Load required data

CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'psth_5ms.mat'])
load([directory filesep 'processed_data' filesep 'Roc_hit_cr3.mat'])
load([directory filesep 'data_helpers' filesep 'Area_list.mat'])


top_entries=[14,18;79,39]

%%


WindowCenters=[-1+0.005:0.005:2]' ;   % change later
params.QuietState='All_trials'     % 'Quiet_(whisker_speed)' 'Quiet_(jaw_movement)' 'Quiet_(jaw & whisker)' 'Non_quiet' 'All_trials'
params.BaselineSubtraction=1
params.completion_state= 'completed_trials'   % options 'early_licks'  'completed_trials'
params.TrialType=[1,3]          % 1: gotone/whisker  2: gotone/nowhisker 3: nogotone/whisker  4: nogotone/nowhisker  5: notone/whisker
params.LickState =[1,0]         % lick 1: lick  0:nolick
params.TrialType_name={'go-tone whisker';'nogo-tone whisker'}

params.CellType='All'           % 'RS' 'FS' 'RS_FS' 'All'
params.regionlist={'A1','wS1','wS2','wM2','ALM'}       % 'ALM','wM2','wS2','wS1','A1','tjM1'

bin_width=0.005
XTickLabel={'0.95';'1';'1.05';'1.1'}
xtick=[0.95;1;1.05;1.1]
t_show=[0.95,1.1]

% movements
movements_signals={'whisker_speed','snout_angle','piezo_lick_trace','jaw_movement','tongue_movement'}  %'whisker_speed','snout_angle','piezo_lick_trace','jaw_movement','tongue_movement'
movements_signals_tag={'Whisker','Snout','Piezo lick','Jaw','Tongue'}  %'whisker_speed','snout_angle','piezo_lick_trace','jaw_movement','tongue_movement'

params.movement_baselineSubtraction=1
params.movement_normalization=0

params.colormap={'#0008FF';'#228B22';'#00C3FF';'#FF0000';'#FF7F00';'#000000';'#00C3FF';'#FF7F00';'#FF7F00';'#808080';'#6B3686';'#74B99A';'#A020F0';'#FFD700'};params.colortype={'wS1';'wS2';'CR2';'ALM';'CR4';'wM2';'FA2';'FA3';'FA4';'FA5';'Lick';'NoLick';'A1';'tjM1'};
params.Map=horzcat(params.colortype,params.colormap);
colormaps=[0 0 1;1 0 0]




for index=1:size(top_entries,1)

    parent=figure('Units','centimeters','Position',[0 0 21 10],'PaperType','A4','PaperUnits','centimeters','PaperSize',[21 29.7],'PaperPosition',[0 0 21 29.7]);
    h = tight_subplot(2,1,[0 .1],[.2 .1],[0.08 0.08])% 'Quiet_(whisker_speed)' 'Qui
    axs=findall(gcf, 'type', 'axes')
    axs=flipud(axs);
    trial_offset = 0;
    ylabel_trials=1
    for ind_cond=1:length(params.TrialType)
        current_trialtype=cell2mat(params.TrialType_name(ind_cond))
        % for ind_cell=top_entries(:,3)'

        ind_cell=top_entries(index,2);
        ind_probe=top_entries(index,1);

        Trial=psth_mat(ind_probe).trial_type;
        Lick= psth_mat(ind_probe).lick_flag;
        % conditions
        IndTrialType=Trial==params.TrialType(ind_cond);
        IndLickstate=Lick==params.LickState(ind_cond);
        % id of completion
        switch params.completion_state
            case 'completed_trials'
                completion_state=~psth_mat(ind_probe).early_lick;
            case 'early_licks'
                early_licks_all=psth_mat(ind_probe).early_lick;
                lick_time=0<(psth_mat(ind_probe).lick_time-psth_mat(ind_probe).start_time);
                completion_state=lick_time & early_licks_all;
        end

        % ids of sequence
        switch params.QuietState
            case 'Quiet_(whisker_speed)'
                Qind=psth_mat(ind_probe).quiet_trial_whisker_speed;
            case 'Quiet_(jaw_movement)'
                Qind=psth_mat(ind_probe).quiet_trial_jaw_movement;
            case 'Quiet_(jaw & whisker)'
                Qind=psth_mat(ind_probe).quiet_trial_jaw_movement & psth_mat(ind_probe).quiet_trial_whisker_speed;
            case 'Non_quiet'
                Qind=~(psth_mat(ind_probe).quiet_trial_jaw_movement & psth_mat(ind_probe).quiet_trial_whisker_speed);
            case 'All_trials'
                Qind=ones(length(IndLickstate),1);
        end
        current_trial_ind=[Qind&completion_state & IndLickstate & IndTrialType];

        switch params.CellType
            case 'RS'
                CelltypeInd=psth_mat(ind_probe).unit_rsUnits;
            case 'FS'
                CelltypeInd=psth_mat(ind_probe).unit_fsUnits;
            case 'RS_FS'
                CelltypeInd=(psth_mat(ind_probe).unit_fsUnits | psth_mat(ind_probe).unit_rsUnits) ;
            case 'All'
                CelltypeInd=logical(ones(length(psth_mat(ind_probe).unit_rsUnits),1)) ;
        end
        % ccf filter on cell location


        % ind_ccf_filter=ismember(psth_mat(ind_probe).probe_location,area_list.(current_area));
        % current_cell_ind=(CelltypeInd & ind_ccf_filter);
        % current psth of selected session
        curr_sp=psth_mat(ind_probe).spike_counts;
        % current movements siganl
        % take the average over specific trials condition
        curr_sp_trials=curr_sp(:,current_trial_ind,:);
        % for specified cell types
        curr_sp_trials_cells=curr_sp_trials(:,:,ind_cell);
        t1=.95
        t2=1
        [a,b]=min(abs(WindowCenters-t1));baselineFirstBin=(b);
        [a,b]=min(abs(WindowCenters-t2));baselineLastBin=(b);
        baseline_mean=repmat(mean(curr_sp_trials_cells(baselineFirstBin:baselineLastBin,:),1),size(curr_sp_trials_cells,1),1);
        if params.BaselineSubtraction
            curr_sp_trials_cells=curr_sp_trials_cells-baseline_mean;
        end
        concat_sp=curr_sp_trials_cells;

        signal2plot=concat_sp;
        time2plot=WindowCenters;
        current_area=cell2mat(psth_mat(ind_probe).probe_location)
        signal2plot=signal2plot/bin_width; % convert to hz
        ind_color=find(strcmp(current_area,params.Map(:,1)));
        meansig=nanmean(signal2plot,2);
        semsig=nanstd(signal2plot,[],2)./sqrt(size(signal2plot,2));
        curve1 = meansig+semsig;
        curve2 = meansig-semsig;
        x2 = [time2plot',fliplr(time2plot')];
        inBetween = [curve1', fliplr(curve2')];

        fill(axs(2),x2, inBetween ,colormaps(ind_cond,:),'FaceAlpha',0.2,'LineStyle','none');
        hold (axs(2),'on')
        plot(axs(2),time2plot,meansig,'color',colormaps(ind_cond,:),'linewidth',1);
        % plot(axs(2),t,meansig(selected_bin),'o','color',colormaps(ind_cond,:),'linewidth',1);
        xline(axs(2),1.03)
        hold(axs(1),'on')


        % Setup
        dt = 0.005; % 5 ms
        time = -1:dt:2 - dt;  % 600 time points
        data = concat_sp;     % [600 x Ntrials]
        [n_time, n_trials] = size(data);

        for trial = 1:n_trials
            spike_inds = find(data(:,trial) > 0);  % Time indices with spikes

            if ~isempty(spike_inds)
                % Compute jittered spike times
                base_times = time(spike_inds);
                jitter = (rand(size(base_times)) - 0.5) * 0.005;  % ±0.5 ms jitter (1 ms range)
                spk_times = base_times + jitter;

                % Y values (trial number + offset)
                y_vals = trial + trial_offset * ones(size(spk_times));

                % Vectorized plotting
                plot(axs(1), spk_times, y_vals, '.', ...
                    'Color', colormaps(ind_cond,:), 'MarkerSize', 8);
            end
        end

        trial_offset = trial_offset + n_trials;
        ylabel_trials=[ylabel_trials;trial_offset]
    end % end of condition
    % Event markers
    xline(axs(1), [1,1.03]);
    xline(axs(2), [1,1.03]);

    ylim(axs(1),[0 trial_offset+1]);
    % end % end over areas
    xlim(axs(1),t_show)
    xlim(axs(2),t_show)

    % % ylim(axs(ind_cond),[-2,12])
    % yline(axs(1),0,'Tag','y=0')
    xlabel(axs(2),'Time (s)')
    ylabel(axs(2),'Firing rate (Hz)')
    ylabel(axs(1),'Trial number')

    % xticks(axs(1),xtick)
    % xticklabels(axs(1),XTickLabel)
    title(axs(1),[current_area ' session: ' cell2mat(psth_mat(ind_probe).session_id) '   unit:' num2str(ind_cell) ],'Interpreter','none')
    yticks(axs(1),ylabel_trials)
    yticklabels(axs(1),ylabel_trials)

end %end of session




% legend_just_txt(axs(1),params.regionlist,'Xoffset',1.1,'Yoffset',2,'relX',0,'relY',0.05,'type','line');
% prettify_plot('LineThickness', 1,'TickWidth',1.5,'AxisTightness', 'keep','TickLength',[.02 .02],'PointSize',4)
%% Export figure
directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];

outputPDF = [directory name '.pdf'];

% Delete previous version if exists
if exist(outputPDF, 'file')
    delete(outputPDF);
end

% Get all figure handles
figHandles = findall(0, 'Type', 'figure');

% Sort them by figure number (optional)
[~, idx] = sort(arrayfun(@(f) f.Number, figHandles));
figHandles = figHandles(idx);

% Loop over each figure and export to PDF
for i = 1:length(figHandles)
    fig = figHandles(i);

    % Export to PDF and append
    exportgraphics(fig, outputPDF, 'ContentType', 'vector', 'Append', true);
end

disp(['All figures saved into: ', outputPDF]);