%% compare_ffmpeg_matlab_lowpass.m
% J McLean 9/6/19
clc; clear; close all;

%%
fname = '/Users/jamesmclean/Dropbox/repos/popup_slicer/test_vid_audio/_sausage_audio/audi.aif';
fname_out = '/Users/jamesmclean/Dropbox/repos/popup_slicer/test_vid_audio/_sausage_audio/audi_lowpass.aif';
fname_filter = '/Users/jamesmclean/Dropbox/repos/popup_slicer/_main_waveform/filter_coef.mat';

%% FFMPEG lowpass
setenv('fname',fname);
setenv('fname_out',fname_out);
% !~/Library/HumanEditor/ffmpeg -i $fname -c:a alac -filter_complex "highpass=f=100:width_type=o:w=8" $fname_out
!~/Library/HumanEditor/ffmpeg -i $fname -filter_complex "highpass=f=100:width_type=o:w=8" $fname_out
[y_lp_ff,fs] = audioread(fname_out);

%% MATLAB lowpass
load(fname_filter);
[y,fs] = audioread(fname);

y_lp_m = filter(Num,1,y);


%%
y = mean(y,2);
y_lp_m = mean(y_lp_m,2);
y_lp_ff = mean(y_lp_ff,2);

figure (1);
subplot(3,1,1); plot(y); title('Original')
subplot(3,1,2); plot(y_lp_m); title('MATLAB')
subplot(3,1,3); plot(y_lp_ff); title('FFMPEG')