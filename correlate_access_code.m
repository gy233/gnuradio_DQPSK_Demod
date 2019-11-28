function out = correlate_access_code(in, threshold)
if size(in,2)>1
    error('correlate_access_code::size(in,2)>1')
end
preamble=double(dec2bin(hex2dec('A4F2'),16))-double('0');
preamble=preamble';
access_code=double(strcat(dec2bin(hex2dec('ACDD'),16),dec2bin(hex2dec('A4E2'),16),dec2bin(hex2dec('F28C'),16),dec2bin(hex2dec('20FC'),16)))-double('0');
access_code=access_code';
l_preamble=length(preamble);
l_access_code=length(access_code);

correlation=zeros(length(in)-l_access_code-l_preamble+1,1);
for i=1:length(in)-l_access_code-l_preamble+1
    if sum(in(i:i+l_preamble-1)==preamble)==l_preamble
        correlation(i)=sum(in(i+l_preamble:i+l_preamble+l_access_code-1)==access_code);
    end
end
if threshold<0
    threshold=12;
end
out=find(correlation>=(l_access_code-threshold));