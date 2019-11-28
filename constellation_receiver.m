function [out,phase_error_rec,d_phase_rec,d_freq_rec,sample_rec]=constellation_receiver(in)
if size(in,2)>1
    error('constellation_receiver::size(in,2)>1')
end
out=zeros(size(in));
phase_error_rec=[];
d_phase_rec=[];
d_freq_rec=[];
sample_rec=[];

% constellation
SQRT_TWO=sqrt(2);
d_constellation(1) = SQRT_TWO + 1i*SQRT_TWO;
d_constellation(2) = -SQRT_TWO + 1i*SQRT_TWO;
d_constellation(3) = -SQRT_TWO - 1i*SQRT_TWO;
d_constellation(4) = SQRT_TWO - 1i*SQRT_TWO;

% control loop init
d_loop_bw=2*pi/100;
d_freq=0;
d_phase=0;
d_max_freq=0.25;
d_min_freq=-0.25;
d_damping = sqrt(2)/2;
[d_alpha, d_beta] = update_gains(d_damping, d_loop_bw);

for i=1:length(in)
    nco=exp(1i*d_phase);
    sample = nco*in(i);
    [sym_value, phase_error]=decision_maker_pe(sample,d_constellation);
    
    % advance_loop
    d_freq = d_freq + d_beta * phase_error;
    d_phase = d_phase + d_freq + d_alpha * phase_error;
    
    % phase_wrap
    while d_phase>2*pi
        d_phase=d_phase-2*pi;
    end
    while d_phase<-2*pi
        d_phase=d_phase+2*pi;
    end
    
    % frequency_limit
    if(d_freq > d_max_freq)
        d_freq = d_max_freq;
    elseif(d_freq < d_min_freq)
        d_freq = d_min_freq;
    end
    
    out(i) = sym_value;
    
    phase_error_rec=[phase_error_rec;phase_error];
    d_phase_rec=[d_phase_rec;d_phase];
    d_freq_rec=[d_freq_rec;d_freq];
    sample_rec=[sample_rec;sample];
end