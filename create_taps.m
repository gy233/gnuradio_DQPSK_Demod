function ourtaps=create_taps(newtaps,if_diff) % size(newtaps)=[1,n]
global d_taps_per_filter
global d_dtaps_per_filter
d_int_rate=32;
ntaps = length(newtaps);
if if_diff
    d_dtaps_per_filter = ceil(ntaps/d_int_rate);
    
    % Make a vector of the taps plus fill it out with 0's to fill
    % each polyphase filter with exactly d_taps_per_filter
    tmp_taps=zeros(1,d_int_rate*d_dtaps_per_filter);
    tmp_taps(1:ntaps) = newtaps;
    
    ourtaps=zeros(d_int_rate,d_dtaps_per_filter);
    for i = 1:d_int_rate
        % Each channel uses all d_taps_per_filter with 0's if not enough taps to fill out
        ourtaps(i,:) = tmp_taps(i:d_int_rate:end);
    end
else
    d_taps_per_filter = ceil(ntaps/d_int_rate);
    
    % Make a vector of the taps plus fill it out with 0's to fill
    % each polyphase filter with exactly d_taps_per_filter
    tmp_taps=zeros(1,d_int_rate*d_taps_per_filter);
    tmp_taps(1:ntaps) = newtaps;
    
    ourtaps=zeros(d_int_rate,d_taps_per_filter);
    for i = 1:d_int_rate
        % Each channel uses all d_taps_per_filter with 0's if not enough taps to fill out
        ourtaps(i,:) = tmp_taps(i:d_int_rate:end);
    end
end