function [y, f] = single_sided_fft(x, fs)
%% [y, f] = single_sided_fft(x, fs)
%
%%
% Get frequency axis vector
L = length(x);
n = 2^nextpow2(L);
f = fs*(0:(1/n):(0.5));

% Calculate single-sided spectrum
mag = abs(fft(x,n) / L);
y = mag(1:n/2+1);

% Double amplitude for single-sided, excluding DC and the final freq (fs/2)
% which is the center and end points, respectively, so they shouldnt be doubled
y(2:end-1) = 2*y(2:end-1);

end