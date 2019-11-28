% referene: control_loop.cc
function [d_alpha, d_beta] = update_gains(d_damping, d_loop_bw)
denom = (1.0 + 2.0*d_damping*d_loop_bw + d_loop_bw*d_loop_bw);
d_alpha = (4*d_damping*d_loop_bw) / denom;
d_beta = (4*d_loop_bw*d_loop_bw) / denom;