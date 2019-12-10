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
wf_position = [1 1 600 200]; % size and position of waveform plot
wf_ext = '.png';

image_dim = [120 400];

low_freq_range = 160; %Hz
low_freq_thresh = 0.001;

% if library folder does not exist, make it
if (exist(ref_path) ~= 7)
    mkdir(ref_path);
end

% load lp filter coefs
load(fullfile(ref_path,'filter_coef.mat'));

%% Create the waveform figure
f = figure('Units','pixels','Position',wf_position,'Visible','off');
a = axes(f);

%% User input/output folders
path = '/Users/jamesmclean/Dropbox/repos/popup_slicer/test_vid_audio/_sausage_audio/';
path_out = '/Users/jamesmclean/Dropbox/repos/popup_slicer/test_vid_audio/_sausage_audio/_audio_wf';
% path = '/Users/jamesmclean/Dropbox/repos/popup_slicer/_main_waveform/test_tracks/not_sausage/';
% path_out = '/Users/jamesmclean/Dropbox/repos/popup_slicer/_main_waveform/test_tracks/not_sausage/_audio_wf';
% path = uigetdir(top_path,'Select audio file directory');
% path_out = uigetdir(top_path,'Select waveform output file directory');

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
    [y,fs] = audioread(fname_ref,'native');
    [y_norm,~] = audioread(fname_ref);
    
    % Get spectrum
    [Y,f] = single_sided_fft(y_norm(:,1),fs);
    
    % Determine if sausage
    low_freq_energy = median(Y(f<low_freq_range));
    sausage_flag = low_freq_energy > low_freq_thresh;
    
    % lowpass is necessary
    if sausage_flag
        fname_out_wf = fullfile(path_out,[name wf_ext]);
        y = filter(Num,1,y);
        disp('sausage');
    end
    
    % take mean if stereo
    if (size(y,2) == 2)
        y = mean(y,2);
    end
    L = length(y);
    
    % get y-axis limits
    if strcmp(ext,'.aif')
        info = audioinfo(fname);
        disp([name ' BitsPerSample = ' num2str(info.BitsPerSample) ' Max Int = ' num2str(max(y))])
        switch info.BitsPerSample
            case 8
                ylim_low = 0;
                ylim_high = 255;
            case 16
                ylim_low = -32768;
                ylim_high = 32768;
            case 24
                ylim_low = -(2^31);
                ylim_high = (2^31)-1;
        end
    else
        ylim_low = -1;
        ylim_high = 1;
    end 

    % Display waveform and save it
    plot(y,'Color',wf_color,'Parent',a,'AlignVertexCenters','on');
    set(gca,'XLim',[1 L],'YLim',[ylim_low ylim_high],'XTickLabel','','YTickLabel','','TickLength',[0 0],...
        'color','none');
%     set(gca,'XLim',[1 L],'YLim',[ylim_low ylim_high],'XTickLabel','','YTickLabel','','TickLength',[0 0],...
%         'color','none','XColor','none','YColor','none');
%     set(gca,'Units','pixels','Position',[100 50 400 120]);
    set(gcf,'color','none');
    pbaspect([3 1 1])
    export_fig(fname_out_wf,'-transparent');
    
    % read image, resize to exact size, then write
    [im,~,alpha] = imread(fname_out_wf);
    
    % need to resize a little extra then crop the border
    % we could remove the border in the inital plot but that messes up
    % export fig and causes the image to basically crop to the max points
    % of the waveform
    im = imresize(im,image_dim+6);
    im = im(4:end-3,4:end-3,3);
    alpha = imresize(alpha,image_dim+6);
    alpha = alpha(4:end-3,4:end-3);
    imwrite(im,fname_out_wf,'Mode','lossless','Alpha',alpha);

    % delete library folder copy
    delete(fname_ref);
end

% close the figure before terminating
close all;












