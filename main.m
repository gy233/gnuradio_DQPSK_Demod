clc;clear;close all;

global d_taps_per_filter
global d_dtaps_per_filter

%% pfb clock sync data (input)
data_length=20000;
samples_per_symbol=2;
filename='/home/guyu/my_gnuradio_projects/cma/cma_test.bin';
[fid]=fopen(filename,'rb');
input=fread(fid,samples_per_symbol*2*data_length,'float32');
input=input(1:2:end)+1i*input(2:2:end);
input=[zeros(d_taps_per_filter+3,1)+1i*zeros(d_taps_per_filter+3,1); input];
fclose(fid);

%% RRC
% firdes.root_raised_cosine
nfilts=32;

gain=nfilts;
sampling_freq=nfilts*samples_per_symbol;
symbol_rate=1;
alpha=0.35;
ntaps = nfilts * 11 * samples_per_symbol;    % make nfilts filters of ntaps each
[taps,t,num,den] = root_raised_cosine(gain,sampling_freq,symbol_rate,alpha,ntaps);

%% init pfb_clock_sync
d_max_dev = 1.5;
d_error=0;
init_phase = floor(nfilts/2);
d_out_idx = 0;

d_nfilters = 32;
d_sps = floor(samples_per_symbol);

% Set the damping factor for a critically damped system
d_damping = 2*d_nfilters;

% Set the bandwidth, which will then call update_gains()
d_loop_bw = 2*pi/100;
[d_alpha, d_beta] = update_gains(d_damping, d_loop_bw);

% Store the last filter between calls to work
% The accumulator keeps track of overflow to increment the stride correctly.
% set it here to the fractional difference based on the initial phase
d_k = init_phase;
d_rate = (samples_per_symbol-floor(samples_per_symbol))*d_nfilters;
d_rate_i = floor(d_rate);
d_rate_f = d_rate - d_rate_i;
d_filtnum = floor(d_k);

dtaps = [0,taps(3:end)-taps(1:end-2),0];
dtaps = dtaps * d_nfilters/sum(abs(dtaps));
d_taps=create_taps(taps,0);
d_dtaps=create_taps(dtaps,1);

%% pfb_clock_sync_ccf_impl::general_work
d_k_rec=[];
d_error_rec=[];
d_rate_f_rec=[];
i = 1;
count = 0;
output = zeros(2,1);

while(count <= length(input)-d_taps_per_filter)
    
    d_filtnum = floor(d_k);
    
    % Keep the current filter number in [0, d_nfilters]
    % If we've run beyond the last filter, wrap around and go to next sample
    % If we've gone below 0, wrap around and go to previous sample
    while(d_filtnum >= d_nfilters)
        d_k = d_k - d_nfilters;
        d_filtnum = d_filtnum - d_nfilters;
        count = count + 1;
    end
    while(d_filtnum < 0)
        d_k = d_k + d_nfilters;
        d_filtnum = d_filtnum + d_nfilters;
        count = count - 1;
    end
    output(i) = fliplr(d_taps(d_filtnum+1,:))*input(count+1:count+d_taps_per_filter);
    d_k = d_k + d_rate_i + d_rate_f; % update phase
    
    % record
    d_error_rec=[d_error_rec;d_error];
    d_rate_f_rec=[d_rate_f_rec;d_rate_f];
    d_k_rec=[d_k_rec;d_k];
    
    % Update the phase and rate estimates for this symbol
    diff = fliplr(d_dtaps(d_filtnum+1,:)) * input(count+1:count+d_dtaps_per_filter);
    error_r = real(output(i)) * real(diff);
    error_i = imag(output(i)) * imag(diff);
    d_error = (error_i + error_r) / 2.0;       % average error from I&Q channel
    
    
    % Run the control loop to update the current phase (k) and
    % tracking rate estimates based on the error value
    % Interpolating here to update rates for ever sps.
    for s = 0 : d_sps-1
        d_rate_f = d_rate_f + d_beta*d_error;
        d_k = d_k + d_rate_f + d_alpha*d_error;
    end
    
    % Keep our rate within a good range
    d_rate_f = branchless_clip(d_rate_f, d_max_dev);
    
    i = i + 1;
    count = count + floor(d_sps);
end

%% pfb clock sync data (output)
filename='/home/guyu/my_gnuradio_projects/cma/cma_test_pfb.bin';
[fid]=fopen(filename,'rb');
output_verify=fread(fid,2*length(output),'float32');
output_verify=output_verify(1:2:end)+1i*output_verify(2:2:end);
fclose(fid);

%% figures
figure
subplot(131)
scatter(real(input),imag(input))
title('input')
subplot(132)
scatter(real(output),imag(output))
title('output')
subplot(133)
scatter(real(output_verify),imag(output_verify))
title('output verify')

figure
plot(real(output),'b','LineWidth',2);
hold on
plot(real(output_verify),'r');
legend('output','output verify')

%% constellation_receiver
[out_constellation_receiver,phase_error_rec,d_phase_rec,d_freq_rec,sample_rec]=constellation_receiver(output);

%% diff_decoder_bb
modulus=4;
out_diff_decoder_bb=diff_decoder_bb(out_constellation_receiver,modulus);

%% map
for i=1:length(out_diff_decoder_bb)
    if out_diff_decoder_bb(i)==2
        out_diff_decoder_bb(i)=3;
    elseif out_diff_decoder_bb(i)==3
        out_diff_decoder_bb(i)=2;
    end
end

%% unpack_k_bits
k=2;
out_unpack_k_bits=unpack_k_bits(out_diff_decoder_bb, k);

%% correlate_access_code
threshold=-1;
packet_start = correlate_access_code(out_unpack_k_bits, threshold);

%% BER (Bit Error Ratio)
filename='/home/guyu/Documents/GNURADIO/temp.bin';
[fid]=fopen(filename,'rb');
packet_encoder_out=fread(fid,528,'uint8');
fclose(fid);
packet_encoder_out_bit=unpack_k_bits(packet_encoder_out, 8);

ber=zeros(length(out_unpack_k_bits)-length(packet_encoder_out_bit)+1,1);
for i=1:length(out_unpack_k_bits)-length(packet_encoder_out_bit)+1
    ber(i)=sum(out_unpack_k_bits(i:i+length(packet_encoder_out_bit)-1)==packet_encoder_out_bit)/length(packet_encoder_out_bit);
end
figure
plot(ber)
title('ber')

