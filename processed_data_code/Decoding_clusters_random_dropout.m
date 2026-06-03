%% =========================================================================
% Decoding_clusters_random_dropout.m
% =========================================================================
% 
% This script performs decoding analysis with cluster-based random dropout
% for the manuscript "Contextual gating of whisker-evoked responses by frontal 
% cortex supports flexible decision making" (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
% 
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script performs binary classification decoding using SVM
% with cluster-based random dropout analysis. It systematically removes
% specific clusters of neurons and evaluates decoding performance, comparing
% it to random dropout scenarios. The analysis includes both original cluster
% dropout and random selection dropout for validation.
%
% Dependencies: 
%   - psth_10ms.mat (contains trial data)
%   - area_list.mat (contains brain area information)
%   - Data_Clustering.mat (contains cluster information)
%   - mySMOTE.m (for data balancing)
%   - svmtrain/svmpredict (LIBSVM functions)
%
% Input: Processed PSTH data and cluster information
% Output: Decoding accuracy results saved to Decoding_clusters_dropout_mndropout.mat
%         and Decoding_clusters_random_dropout.mat
% =========================================================================

%%
clear all
close all
clc

CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'data_helpers' filesep 'area_list.mat'])
load([directory filesep 'processed_data' filesep 'Data_Clustering.mat'])
load([directory filesep 'processed_data' filesep 'psth_10ms.mat'])

% Set random seed for reproducibility
rng(0)


%% Extract unique cluster IDs
[a, b, c] = unique(Cluster_Counter_Ordered);

%% Main analysis loop across clusters
for i_cluster = a
    cluster_name = ['cluster' num2str(i_cluster)];
    cluster_name = strrep(cluster_name, ' ', '_');
    id_2drop = Id_Ordered(Cluster_Counter_Ordered == i_cluster);

    % Optional: Analyze specific clusters
    % i_cluster = [2, 16, 5, 14, 11, 21];
    % id_2drop = Id_ordered(ismember(Cluster_Counter_Ordered, i_cluster));

    %% Define analysis parameters
    % Trial selection and behavioral parameters
    params.quietstate = 'Quiet_(jaw & whisker)';   % Options: 'Quiet_(whisker_speed)', 'Quiet_(jaw_movement)', 'Quiet_(jaw & whisker)', 'Non_quiet', 'All_trials'
    params.BaselineSubtraction = 0;
    params.completion_state = 'completed_trials';   % Options: 'early_licks', 'completed_trials'
    params.TrialType = [1, 2, 3, 4, 5];   % 1: gotone/whisker, 2: gotone/nowhisker, 3: nogotone/whisker, 4: nogotone/nowhisker, 5: notone/whisker
    params.LickState = [1, 0, 0, 0, 0];  % lick 1: lick, 0: nolick
    params.celltype = 'All';           % Options: 'RS', 'FS', 'RS_FS', 'All'
    params.regionlist = {'A1', 'wM2', 'wS1', 'ALM', 'wS2'};       % Brain regions to analyze

    % Time window parameters
    params.t_start = -1;  % Start time (seconds)
    params.t_end = 2;     % End time (seconds)
    params.bin_width = 0.01;  % 10ms bins
    params.XTickLabel = {'-1'; '0'; '1'; '2'};
    params.xtick = [-1; 0; 1; 2];

    % Analysis parameters
    params.balance_method = 'downsample';
    params.mintrial = 5;
    params.Folds = 10;
    params.preTime = -1;
    params.postTime = 2;
    params.BinSize = 0.01;
    params.BinStep = 0.01;
    params.normalization = 0;
    params.zscoring = 1;  % Do zscore on feature matrix
    params.Separation = 0;
    params.spikecount = 1;    % 1: spike count, 0: rate
    params.windowCenters = psth_mat(1).trial_timestamps;

    %% Define classification expressions
    % Binary classification between two trial conditions
    class_expr1 = 'Ind.Class1 = [trial == 1 & lick == 1];';   % Go-tone with whisker and lick
    class_expr2 = 'Ind.Class2 = [trial == 3 & lick == 0];';   % No-go-tone with whisker, no lick

    %% Main analysis loop across brain regions
    for ind_area = 1:length(params.regionlist)
        currentarea = cell2mat(params.regionlist(ind_area));
        list_probes = find(strcmp(currentarea, [psth_mat.probe_location]));
        session_counter = 0;
        
        for ind_probe = list_probes
            session_counter = session_counter + 1;
            
            % Extract trial information
            trial = psth_mat(ind_probe).trial_type;
            lick = psth_mat(ind_probe).lick_flag;
            
            %% Determine trial completion status
            switch params.completion_state
                case 'completed_trials'
                    completed_trials_ind = ~psth_mat(ind_probe).early_lick;
                case 'early_licks'
                    early_licks_all = psth_mat(ind_probe).early_lick;
                    lick_time = 0 < (psth_mat(ind_probe).lick_time - psth_mat(ind_probe).start_time);
                    completed_trials_ind = lick_time & early_licks_all;
            end
            
            %% Determine quiet trial status
            switch params.quietstate
                case 'Quiet_(whisker_speed)'
                    Qind = psth_mat(ind_probe).quiet_trial_whisker_speed;
                case 'Quiet_(jaw_movement)'
                    Qind = psth_mat(ind_probe).quiet_trial_jaw_movement;
                case 'Quiet_(jaw & whisker)'
                    Qind = psth_mat(ind_probe).quiet_trial_jaw_movement & psth_mat(ind_probe).quiet_trial_whisker_speed;
                case 'Non_quiet'
                    Qind = ~(psth_mat(ind_probe).quiet_trial_jaw_movement & psth_mat(ind_probe).quiet_trial_whisker_speed);
                case 'All_trials'
                    Qind = logical(ones(length(trial), 1));
            end
            
            %% Evaluate classification expressions
            eval(class_expr1);
            eval(class_expr2);
            
            % Apply quiet trial and completion filters
            Ind.Class1 = Ind.Class1 & Qind & completed_trials_ind;
            Ind.Class2 = Ind.Class2 & Qind & completed_trials_ind;

            %% Determine cell type filter
            switch params.celltype
                case 'RS'
                    CelltypeInd = psth_mat(ind_probe).unit_rsUnits;
                case 'FS'
                    CelltypeInd = psth_mat(ind_probe).unit_fsUnits;
                case 'RS-FS'
                    CelltypeInd = (psth_mat(ind_probe).unit_fsUnits | psth_mat(ind_probe).unit_rsUnits);
                case 'All'
                    CelltypeInd = logical(ones(length(psth_mat(ind_probe).unit_rsUnits), 1));
            end

            %% Apply cluster dropout filter
            curr_global_id = psth_mat(ind_probe).GlobalclusterID;
            curr_id_not2drop = ~ismember(curr_global_id, id_2drop);
            
            %% Generate shuffled vectors for random dropout comparison
            num_vectors = 5; % How many shuffled vectors to generate
            num_zeros = sum(~curr_id_not2drop); % Number of cells to drop

            shuffled_vectors = true(length(curr_id_not2drop), num_vectors); % Preallocate with ones

            % Identify available positions for zeros (positions with original ones)
            available_positions = find(curr_id_not2drop);

            for i = 1:num_vectors
                % Randomly select positions for zeros from available positions
                random_zero_positions = available_positions(randperm(length(available_positions), num_zeros));

                % Initialize the new shuffled vector (all ones)
                temp_vec = true(length(curr_id_not2drop), 1);

                % Set randomly chosen positions to zero
                temp_vec(random_zero_positions) = false;

                % Save this shuffled vector
                shuffled_vectors(:, i) = temp_vec;
            end
            
            %% Apply CCF location filter
            ind_ccf_filter = ismember(psth_mat(ind_probe).unit_ccf_location, area_list.(currentarea));
            CurrCellInd = (CelltypeInd & ind_ccf_filter & curr_id_not2drop');

            % Skip sessions with insufficient cells
            if sum(CurrCellInd) < 5   % For condition in FS there is one session which has just 1 FS cell
                continue
            end

            %% Extract current session data
            Currsig = psth_mat(ind_probe).spike_counts;
            Currsig_CurrCellInd = Currsig(:, :, CurrCellInd);

            %% Extract data for each class
            classnames = fieldnames(Ind);
            for iClass = 1:length(classnames)
                theseIndices = Ind.(cell2mat(classnames(iClass)));
                Value.(cell2mat(classnames(iClass))) = Currsig_CurrCellInd(:, theseIndices, :);
            end

            %% Perform decoding analysis for each time bin
            for iBin = 1:size(Value.Class1(:, :, :), 1)
                % Extract data for current time bin
                X1 = (Value.Class1(iBin, :, :)); X1 = squeeze(X1);
                X2 = (Value.Class2(iBin, :, :)); X2 = squeeze(X2);

                % Create labels for binary classification
                y1 = [ones(size(X1, 1), 1)];
                y2 = -1 * [ones(size(X2, 1), 1)];

                C1 = length(y1);
                C2 = length(y2);

                % Skip if insufficient trials
                if (size(X1, 2) < params.mintrial || size(X2, 2) < params.mintrial)
                    Accuracy.(currentarea)(session_counter, iBin) = nan;
                    continue
                end

                %% Balance classes using specified method
                switch params.balance_method
                    case 'downsample'
                        % Downsample larger class to match smaller class
                        if C1 < C2
                            X2 = datasample(X2, C1, 1, 'Replace', false);
                            y2 = -1 * ones(size(X2, 1), 1);
                        else
                            X1 = datasample(X1, C2, 1, 'Replace', false);
                            y1 = ones(size(X1, 1), 1);
                        end

                        X = [X1; X2];
                        y = [y1; y2];

                    case 'smote'
                        % Use SMOTE for data augmentation
                        if C2 < C1
                            allData_smote = mySMOTE([X, y], 5, y);
                            Xc = squeeze(cat(2, X1, X2));
                            yc = [y1; y2];
                            dataset = array2table([Xc]);
                            dataset = addvars(dataset, [string(y1); string(y2)], 'NewVariableNames', 'label');
                            labels = dataset(:, end);
                            t = tabulate(dataset.label);
                            uniqueLabels = string(t(:, 1));
                            labelCounts = cell2mat(t(:, 2));
                            [tmp, visdata] = mySMOTE(dataset, string(y2(1)), C1 - C2, "NumNeighbors", 4, "Standardize", true);
                            newdata = [dataset; tmp];
                            X = table2array(newdata(:, 1:end-1));
                            y = double(table2array(newdata(:, end)));
                        elseif C1 < C2
                            Xc = squeeze(cat(2, X1, X2));
                            yc = [y1; y2];
                            dataset = array2table([Xc]);
                            dataset = addvars(dataset, [string(y1); string(y2)], 'NewVariableNames', 'label');
                            labels = dataset(:, end);
                            t = tabulate(dataset.label);
                            uniqueLabels = string(t(:, 1));
                            labelCounts = cell2mat(t(:, 2));
                            tmp = mySMOTE(dataset, string(y1(1)), C2 - C1, "NumNeighbors", 4, "Standardize", true);
                            newdata = [dataset; tmp];
                            X = table2array(newdata(:, 1:end-1));
                            y = double(table2array(newdata(:, end)));
                        else
                            X = squeeze(cat(2, X1, X2));
                            y = [y1; y2];
                        end
                    case 'no'
                        X = [X1; X2];
                        y = [y1; y2];
                end

                %% Preprocess data
                if params.zscoring
                    out = zscore(X);
                else
                    out = X;
                end

                % Remove neurons with all zero activity during all trials
                col_zero = (~any(out, 1));
                out = out(:, ~col_zero);

                %% Perform cross-validation
                CVO = cvpartition(y, 'KFold', 5, 'Stratify', true);
                acc = zeros(CVO.NumTestSets, 1);
                for icv = 1:CVO.NumTestSets
                    trIdx = CVO.training(icv);
                    teIdx = CVO.test(icv);
                    
                    % Train SVM model
                    model = svmtrain(y(trIdx), out(trIdx, :), '-s 1 -t 0 -q');
                    
                    % Test model
                    [~, accuracy, ~] = svmpredict(y(teIdx), out(teIdx, :), model, '-q');
                    
                    % Test with shuffled labels
                    label = y(teIdx);
                    shuffeled_label = label(randperm(length(label)));
                    [~, accuracy_shuffeled, ~] = svmpredict(shuffeled_label, out(teIdx, :), model, '-q');

                    acc(icv) = accuracy(1);
                    acc_shuffeled(icv) = accuracy_shuffeled(1);
                end  % End of cross-validation loop
                
                %% Store results
                mean(acc);
                Accuracy.(currentarea)(session_counter, iBin) = mean(acc);
                Accuracy_shuffeled.(currentarea)(session_counter, iBin) = mean(acc_shuffeled);
            end % End of time bin loop
            
            %% Store session information
            Accuracy.sessionaddress.(currentarea)(session_counter) = psth_mat(ind_probe).session_id;
            Accuracy_shuffeled.sessionaddress.(currentarea)(session_counter) = psth_mat(ind_probe).session_id;
            {cluster_name, currentarea, session_counter}
        end % End of probe loop
    end     % End of area loop
    
    %% Prepare output variables
    windowCenters = params.windowCenters;
    ACC.(cluster_name).Accuracy = Accuracy;
    ACC.(cluster_name).Accuracy_shuffeled = Accuracy_shuffeled;
    ACC.(cluster_name).windowCenters = windowCenters;
end    % End of cluster loop


%% Save results from random dropout analysis

directory=[CurrentDir filesep 'processed_data' filesep];
save([directory 'Decoding_clusters_random_dropout.mat'], "ACC");
