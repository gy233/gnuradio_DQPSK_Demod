function out=unpack_k_bits(in, k)
if size(in,2)>1
    error('unpack_k_bits::size(in,2)>1')
end
out=zeros(k*length(in),1);
for i=1:length(in)
    out(k*i-k+1:k*i)=double(dec2bin(in(i),k))-double('0');
end