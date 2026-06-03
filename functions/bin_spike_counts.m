function binned_spikes = bin_spike_counts(spike_counts, bin_size_ms, original_bin_size_ms)
    % Bins spike count matrix by summing over time bins.
    %
    % Inputs:
    % - spike_counts: 3D matrix (time_bins x trials x neurons)
    % - bin_size_ms: Desired bin size in milliseconds (e.g., 100, 20, etc.)
    % - original_bin_size_ms: Original bin size (10 ms)
    %
    % Output:
    % - binned_spikes: Re-binned spike count matrix

    % Compute the binning factor
    bin_factor = bin_size_ms / original_bin_size_ms;

    % Ensure that time dimension is divisible by bin_factor
    if mod(size(spike_counts, 1), bin_factor) ~= 0
        error('Time dimension (%d) is not divisible by bin factor (%d)', size(spike_counts, 1), bin_factor);
    end

    % Reshape the time dimension to group bins together
    new_time_bins = size(spike_counts, 1) / bin_factor;
    
    % Reshape and sum along the first dimension
    binned_spikes = reshape(spike_counts, bin_factor, new_time_bins, size(spike_counts, 2), size(spike_counts, 3));
    binned_spikes = sum(binned_spikes, 1);

    % Squeeze to remove singleton dimension
    binned_spikes = squeeze(binned_spikes);
end