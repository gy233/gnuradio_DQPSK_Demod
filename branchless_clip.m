function output = branchless_clip(x, clip)
x1 = abs(x+clip);
x2 = abs(x-clip);
x1 = x1 - x2;
output= 0.5*x1;
