% reference: gnuradio firdes.cc
function [taps,t,num,den] = root_raised_cosine(gain,sampling_freq,symbol_rate,alpha,ntaps)
ntaps = bitor(ntaps,1);             %ensure that ntaps is odd
spb = sampling_freq/symbol_rate;    %samples per bit/symbol
taps=zeros(1,ntaps);
num=zeros(1,ntaps);
den=zeros(1,ntaps);
xindx=zeros(1,ntaps);
scale = 0;
for i=1:ntaps
    xindx(i) = i - ceil(ntaps/2);
    x1 = pi * xindx(i)/spb;
    x2 = 4 * alpha * xindx(i) / spb;
    x3 = x2*x2 - 1;
    if abs(x3)>= 0.000001           %Avoid Rounding errors...
        if i ~= ceil(ntaps/2)
            num(i) = cos((1+alpha)*x1) + sin((1-alpha)*x1)/(4*alpha*xindx(i)/spb);
        else
            num(i) = cos((1+alpha)*x1) + (1-alpha) * pi / (4*alpha);
        end
        den(i) = x3 * pi;
    else
        if alpha==1
            taps(i) = -1;
            continue;
        end
        x3 = (1-alpha)*x1;
        x2 = (1+alpha)*x1;
        num(i) = (sin(x2)*(1+alpha)*pi - cos(x3)*((1-alpha)*pi*spb)/(4*alpha*xindx(i)) + sin(x3)*spb*spb/(4*alpha*xindx(i)*xindx(i)));
        den(i) = -32 * pi * alpha * alpha * xindx(i)/spb;
    end
    taps(i) = 4 * alpha * num(i) / den(i);
    scale = scale + taps(i);
end
for i=1:ntaps
    taps(i) = taps(i) * gain / scale;
end
t=xindx./spb;