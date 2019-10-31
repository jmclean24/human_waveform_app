%% human_waveform_script.m
%
% J McLean 9/1/2019
clc; clear;

%% Parameters
user_str = getenv('USER');
ref_path = ['/Users/' user_str '/Library/HumanWaveform/'];
top_path = ['/Users/' user_str];
valid_file_ext = {'.aif','.mp3','.m4a'};

wf_color = [0 0 0]; % black waveform color
wf_position = [1 1 400 120]; % size and position of waveform plot
wf_ext = '.png';

low_freq_range = 160; %Hz
low_freq_thresh = 0.001;

% if library folder does not exist, make it
if (exist(ref_path) ~= 7)
    mkdir(ref_path);
end

% load lp filter coefs
load(fullfile(ref_path,'filter_coef.mat'));

%% Create the waveform figure
f = figure('Position',wf_position,'Visible','off');
a = axes(f);

%% User input/output folders
% path = '/Users/jamesmclean/Dropbox/repos/popup_slicer/test_vid_audio/_sausage_audio';
path = uigetdir(top_path,'Select audio file directory');
path_out = uigetdir(top_path,'Select waveform output file directory');

if (path == 0)
    error('No input path was selected');
end

if (path_out == 0)
    error('No output path was selected');
end

%% Get # audio files in selected directory
d = dir(path);
d = d(4:end);
n_files = length(d);

% remove subfolders and non-audio files
valid_files = logical(ones(1,n_files));
for i = 1:n_files
    if d(i).isdir % check that file isn't a directory
        valid_files(i) = false;
    else % check that file is actually an audio file
        [~,~,ext] = fileparts(d(i).name);
        valid_file = false;
        for j = 1:length(valid_file_ext)
            if strcmp(ext,valid_file_ext{j})
                valid_file = true;
            end
        end

        if ~valid_file
            valid_files(i) = false;
        end
    end
end

% remove invalid files and directory
d = d(valid_files);
n_files = length(d);

%% Print waveforms
% this is going to be run on 30K tracks so everything needs to be done one
% at a time 
for i = 1:n_files
    % setup filenames
    [~,name,ext] = fileparts(d(i).name);
    fname = fullfile(path,d(i).name);
    fname_ref = fullfile(ref_path,['audio_file' ext]);
    fname_out_wf = fullfile(path_out,[name wf_ext]);
    
    % copy audio and paste into workspace in library folder
    copyfile(fname, ref_path);
    movefile(fullfile(ref_path, d(i).name), fname_ref);
    
    % load audio file
    [y,fs] = audioread(fname_ref);
    
    % Get spectrum
    [Y,f] = single_sided_fft(y(:,1),fs);
    
    % Determine if sausage
    low_freq_energy = median(Y(f<low_freq_range));
    sausage_flag = low_freq_energy > low_freq_thresh;
    
    % lowpass is necessary
    if sausage_flag
        fname_out_wf = fullfile(path_out,[name '_lowpass' wf_ext]);
        y = filter(Num,1,y);
    end
    
    % take mean if stereo
    if (size(y,2) == 2)
        y = mean(y,2);
    end
    L = length(y);

    % Display waveform and save it
    plot(y,'Color',wf_color,'Parent',a,'AlignVertexCenters','on');
    set(gca,'XLim',[1 L],'YLim',[-1 1],'XTickLabel','','YTickLabel','','TickLength',[0 0],'color','none');
    set(gcf,'color','none');
    export_fig(fname_out_wf,'-transparent');

    % delete library folder copy
    delete(fname_ref);
end

% close the figure before terminating
close all;












