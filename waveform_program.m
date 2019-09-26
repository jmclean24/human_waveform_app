function waveform_program(fname, path_out)
%% waveform_program.m
% Command line tool intend to be a "single song" version of
% human_waveform_script.m
%
% J McLean 9/1/2019

%% Parameters
user_str = getenv('USER');
ref_path = ['/Users/' user_str '/Library/HumanWaveform/'];
valid_file_ext = {'.aif','.mp3','.m4a'};

% wf_color = [99 99 99]/255; % gray waveform color
wf_color = [0 0 0]; % black waveform color
wf_position = [1 1 400 120]; % size and position of waveform plot
wf_ext = '.png';

low_freq_range = 160; %Hz
low_freq_thresh = 0.001;

if (exist(ref_path) ~= 7)
    mkdir(ref_path);
end

%% Check inputs
% Check the input filename corresponds to an audio file and that it exists
if (exist(fname) ~= 2)
    error('Audio track not found, check the path and filename is correct');
end

% Check that filename corresponds to an audio file
[~,name,ext] = fileparts(fname);
valid_file = false;
for j = 1:length(valid_file_ext)
    if strcmp(ext,valid_file_ext{j})
        valid_file = true;
    end
end

if ~valid_file
    error('Valid audio track not provided. Must be a support file type (AIF, MP3, or M4A)');
end

% Check that output folder exists
if (exist(path_out) ~= 7)
    error('The output path provided does not exist. Please provide a valid output location');
end

%% Create the waveform figure
f = figure('Position',wf_position,'Visible','off');
a = axes(f);

%% Load
% copy audio track and paste into workspace in Library folder
fname_ref = fullfile(ref_path,['audio_file' ext]);
copyfile(fname, ref_path);
movefile([ref_path name ext], fname_ref);

% output waveform image filename
fname_out_wf = fullfile(path_out,[name wf_ext]);

%% Read audio file and calculate spectrum
[y,fs] = audioread(fname_ref);
[Y,f] = single_sided_fft(y(:,1),fs);

%% Determine if sausage
low_freq_energy = median(Y(f<low_freq_range));
sausage_flag = low_freq_energy > low_freq_thresh;

%% Apply Lowpass
if sausage_flag
    % get correct i/o filenames
%     fname_out = fullfile(ref_path,['audio_file_lowpass' ext]);
    fname_out_wf = fullfile(path_out,[name '_lowpass' wf_ext]);

%     % lowpass
%     setenv('fname',fname_ref);
%     setenv('fname_out',fname_out);
%     !~/Library/HumanEditor/ffmpeg -i $fname -filter_complex "highpass=f=100:width_type=o:w=8" $fname_out
% 
%     % read lowpassed waveform
%     [y,~] = audioread(fname_out);
% 
%     % Delete lowpass filtered file
%     delete(fname_out);
    load('/Users/jamesmclean/Dropbox/repos/popup_slicer/_main_waveform/filter_coef.mat');
    y = filter(Num,1,y);
end

%% Display
% take mean if stereo
if (size(y,2) == 2)
    y = mean(y,2);
end
L = length(y);

% Display waveform and save it
plot(y,'Color',wf_color,'Parent',a);
set(gca,'XLim',[1 L],'YLim',[-1 1],'XTickLabel','','YTickLabel','','TickLength',[0 0]);
export_fig(fname_out_wf,'-transparent');

% delete library folder copy
delete(fname_ref);

% close the figure before terminating
close all;

end














