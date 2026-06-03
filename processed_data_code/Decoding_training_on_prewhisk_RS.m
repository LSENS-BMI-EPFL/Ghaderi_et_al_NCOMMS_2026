%% =========================================================================
% Decoding_training_on_prewhisk_RS.m
% =========================================================================
% 
% This script performs decoding analysis with training on pre-whisker
% stimulation data for Regular Spiking (RS) cells only for the manuscript 
% "Contextual gating of whisker-evoked responses by frontal cortex supports 
% flexible decision making" (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
% 
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script performs binary classification decoding using SVM
% with an approach: it trains the classifier on pre-whisker stimulation
% data (bins 180-199, concatenated into 200ms bins) and then tests it on
% all time bins. This allows assessment of how well pre-stimulus neural
% activity can predict post-stimulus behavioral outcomes. This version
% focuses exclusively on Regular Spiking (RS) pyramidal neurons.
%
% Dependencies: 
%   - psth_10ms.mat (contains trial data with 10ms bins)
%   - area_list.mat (contains brain area information)
%   - mySMOTE.m (for data balancing, if using SMOTE method)
%   - svmtrain/svmpredict (LIBSVM functions)
%
% Input: Processed PSTH data with 10ms bins
% Output: Decoding accuracy results saved to Decoding_training_on_prewhisk_RS.mat
% =========================================================================

%% Initialize workspace and load data
clear all
close all
clc

CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'data_helpers' filesep 'area_list.mat'])
load([directory filesep 'processed_data' filesep 'psth_10ms.mat'])

rng(0)
%% Define analysis parameters
% Trial selection and behavioral parameters
params.quietstate = 'Quiet_(jaw & whisker)';   % Options: 'Quiet_(whisker_speed)', 'Quiet_(jaw_movement)', 'Quiet_(jaw & whisker)', 'Non_quiet', 'All_trials'
params.BaselineSubtraction = 0;  % 0: no baseline subtraction
params.completion_state = 'completed_trials';   % Options: 'early_licks', 'completed_trials'
params.TrialType = [1, 2, 3, 4, 5];   % 1: gotone/whisker, 2: gotone/nowhisker, 3: nogotone/whisker, 4: nogotone/nowhisker, 5: notone/whisker
params.LickState = [1, 0, 0, 0, 0];  % lick 1: lick, 0: nolick
params.celltype = 'RS';           % Options: 'RS', 'FS', 'FS-RS', 'All' (set to 'RS' for this analysis)
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
params.BinSize = 0.01;  % 10ms bins
params.BinStep = 0.01;  % 10ms step
params.normalization = 0;
params.zscoring = 1;  % Do zscore on feature matrix
params.Separation = 0;
params.spikecount = 1;    % 1: spike count, 0: rate
params.windowCenters = psth_mat(1).trial_timestamps;

NaN_Vector(1,1:300)=NaN;

%% Define classification expressions
% Binary classification between two trial conditions
class_expr1 = 'Ind.Class1 = [trial == 1 & lick == 1];';   % Go-tone with whisker and lick
class_expr2 = 'Ind.Class2 = [trial == 3 & lick == 0];';   % No-go-tone with whisker, no lick

%% Main analysis loop across brain regions
for ind_area = 1:length(params.regionlist)
    currentarea = cell2mat(params.regionlist(ind_area));
    list_probes = find(strcmp(currentarea, [psth_mat.probe_location]));
    session_counter = 1;
    
    for ind_probe = list_probes
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
                Qind = ones(length(trial), 1);
        end
        
        %% Evaluate classification expressions
        eval(class_expr1);
        eval(class_expr2);
        
        % Apply quiet trial and completion filters
        Ind.Class1 = Ind.Class1 & Qind & completed_trials_ind;
        Ind.Class2 = Ind.Class2 & Qind & completed_trials_ind;

        %% Determine cell type filter (RS cells only)
        switch params.celltype
            case 'RS'
                CelltypeInd = psth_mat(ind_probe).unit_rsUnits;
            case 'FS'
                CelltypeInd = psth_mat(ind_probe).unit_fsUnits;
            case 'FS-RS'
                CelltypeInd = (psth_mat(ind_probe).unit_fsUnits | psth_mat(ind_probe).unit_rsUnits);
            case 'All'
                CelltypeInd = logical(ones(length(psth_mat(ind_probe).unit_rsUnits), 1));
        end

        %% Apply CCF location filter
        ind_ccf_filter = ismember(psth_mat(ind_probe).unit_ccf_location, area_list.(currentarea));
        CurrCellInd = (CelltypeInd & ind_ccf_filter);

        % Skip sessions with insufficient cells
        if sum(CurrCellInd) < 5   % For condition in RS there is one session which has just 1 RS cell

            Accuracy.(currentarea)(session_counter, :) = NaN_Vector;
            Accuracy_shuffeled.(currentarea)(session_counter, :) = NaN_Vector;
            Accuracy.sessionaddress.(currentarea)(session_counter) = psth_mat(ind_probe).session_id;
            Accuracy_shuffeled.sessionaddress.(currentarea)(session_counter) = psth_mat(ind_probe).session_id;
            session_counter = session_counter + 1;

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

        %% Training phase: Use pre-whisker stimulation data (bins 180-199)
        % Concatenate 10ms bins to create larger 200ms bins for training
        X1 = [];
        X2 = [];
        bin_cnt = 1;
        for iBin = 180:199
            X1bin = (Value.Class1(iBin, :, :)); X1(:, :, bin_cnt) = squeeze(X1bin);
            X2bin = (Value.Class2(iBin, :, :)); X2(:, :, bin_cnt) = squeeze(X2bin);
            bin_cnt = bin_cnt + 1;
        end
        
        % Sum across bins to create 200ms time windows
        X1 = sum(X1, 3);
        X2 = sum(X2, 3);
        
        % Create labels for binary classification
        y1 = [ones(size(X1, 1), 1)];
        y2 = -1 * [ones(size(X2, 1), 1)];

        C1 = length(y1);
        C2 = length(y2);

        % Skip if insufficient trials
        if (size(X1, 2) < params.mintrial || size(X2, 2) < params.mintrial)
%             Accuracy.(currentarea)(session_counter, iBin) = nan;

            Accuracy.(currentarea)(session_counter, :) = NaN_Vector;
            Accuracy_shuffeled.(currentarea)(session_counter, :) = NaN_Vector;
            Accuracy.sessionaddress.(currentarea)(session_counter) = psth_mat(ind_probe).session_id;
            Accuracy_shuffeled.sessionaddress.(currentarea)(session_counter) = psth_mat(ind_probe).session_id;
            session_counter = session_counter + 1;

            continue
        end

        %% Balance classes using specified method for training
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

        %% Preprocess training data
        if params.zscoring
            out = zscore(X);
        else
            out = X;
        end

        %% Train SVM classifier on pre-whisker data
        CVO = cvpartition(y, 'KFold', 5, 'Stratify', true);
        acc = zeros(CVO.NumTestSets, 1);
        
        for icv = 1:CVO.NumTestSets
            trIdx = CVO.training(icv);
            teIdx = CVO.test(icv);
            
            % Train SVM model on pre-whisker data
            model_prewhisk = svmtrain(y(trIdx), out(trIdx, :), '-s 1 -t 0 -q');
            
            % Test model on pre-whisker data
            [~, accuracy, ~] = svmpredict(y(teIdx), out(teIdx, :), model_prewhisk, '-q');
            
            % Test with shuffled labels
            label = y(teIdx);
            shuffeled_label = label(randperm(length(label)));
            [~, accuracy_shuffeled, ~] = svmpredict(shuffeled_label, out(teIdx, :), model_prewhisk, '-q');

            acc(icv) = accuracy(1);
            acc_shuffeled(icv) = accuracy_shuffeled(1);
        end  % End of cross-validation loop

        %% Testing phase: Apply trained classifier to all time bins
        X1 = [];
        X2 = [];
        for iBin = 1:size(Value.Class1, 1)
            X1bin = (Value.Class1(iBin, :, :)); X1 = squeeze(X1bin);
            X2bin = (Value.Class2(iBin, :, :)); X2 = squeeze(X2bin);

            % Create labels for binary classification
            y1 = [ones(size(X1, 1), 1)];
            y2 = -1 * [ones(size(X2, 1), 1)];

            C1 = length(y1);
            C2 = length(y2);

            % Skip if insufficient trials
            if (size(X1, 2) < params.mintrial || size(X2, 2) < params.mintrial)
                %                 Accuracy.(currentarea)(session_counter, iBin) = nan;

                Accuracy.(currentarea)(session_counter, :) = NaN_Vector;
                Accuracy_shuffeled.(currentarea)(session_counter, :) = NaN_Vector;
                Accuracy.sessionaddress.(currentarea)(session_counter) = psth_mat(ind_probe).session_id;
                Accuracy_shuffeled.sessionaddress.(currentarea)(session_counter) = psth_mat(ind_probe).session_id;
                session_counter = session_counter + 1;
                continue
            end

            %% Balance classes using specified method for testing
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

            %% Preprocess testing data
            if params.zscoring
                out = zscore(X);
            else
                out = X;
            end

            %% Test pre-trained classifier on current time bin
            CVO = cvpartition(y, 'KFold', 5, 'Stratify', true);
            acc = zeros(CVO.NumTestSets, 1);
            
            for icv = 1:CVO.NumTestSets
                trIdx = CVO.training(icv);
                teIdx = CVO.test(icv);
                
                % Use pre-trained model to predict on current time bin
                [~, accuracy, ~] = svmpredict(y(teIdx), out(teIdx, :), model_prewhisk);
                
                % Test with shuffled labels
                label = y(teIdx);
                shuffeled_label = label(randperm(length(label)));
                [~, accuracy_shuffeled, ~] = svmpredict(shuffeled_label, out(teIdx, :), model_prewhisk);

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
        session_counter = session_counter + 1;
    end % End of probe loop
end     % End of area loop

%% Prepare output variables and save results
windowCenters = params.windowCenters;

directory=[CurrentDir filesep 'processed_data' filesep];
save([directory 'Decoding_training_on_prewhisk_RS.mat'], "Accuracy", "Accuracy_shuffeled", "windowCenters");
