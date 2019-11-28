function index = dqpsk_decision_maker(sample)
a = real(sample) > 0;
b = imag(sample) > 0;
if a
    if b
        index = 0;
    else
        index = 3;
    end
else
    if b
        index = 1;
    else
        index = 2;
    end
end