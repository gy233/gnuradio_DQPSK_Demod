function out=diff_decoder_bb(in,modulus)
if size(in,2)>1
    error('diff_decoder_bb::size(in,2)>1')
end
in=[0;in];
out = mod(in(2:end) - in(1:end-1), modulus);