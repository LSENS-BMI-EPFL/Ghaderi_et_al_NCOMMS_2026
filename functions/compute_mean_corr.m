function [lags, mean_correlations, sem_correlations] = compute_mean_corr(mat, start_bin, end_bin, max_lag)
% compute_mean_corr calculates mean correlations and SEM along diagonals
% within specified bin boundaries.
%
% INPUT:
% mat        : correlation matrix (e.g., 300x300)
% start_bin  : starting bin index for calculations (e.g., 100)
% end_bin    : ending bin index for calculations (e.g., 199)
% max_lag    : maximum absolute lag to consider (e.g., 200)
%
% OUTPUT:
% lags                : vector of lag values considered
% mean_correlations   : mean correlation values at each lag
% sem_correlations    : standard error of the mean at each lag

lags = -max_lag:max_lag;
n_lags = length(lags);

% Preallocate for speed
mean_correlations = NaN(n_lags,1);
sem_correlations = NaN(n_lags,1);

% Loop through each lag
for idx = 1:n_lags
    lag = lags(idx);
    values = [];

    for i = start_bin:end_bin
        j = i + lag;

        % Only consider indices within the specified bin boundaries
        if j >= start_bin && j <= end_bin
            values(end+1) = mat(i, j);
        end
    end

    % Compute mean and SEM, handle cases with no valid values
    if ~isempty(values)
        mean_correlations(idx) = mean(values);
        sem_correlations(idx) = std(values) / sqrt(length(values));
    else
        mean_correlations(idx) = NaN;
        sem_correlations(idx) = NaN;
    end
end

mean_correlations(lags == 0,1) = NaN;
sem_correlations(lags == 0,1) = NaN;
end


