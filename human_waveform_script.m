%% human_waveform_script.m
%
% J McLean 9/1/2019
clc; clear;

%% Parameters
valid_file_ext = {'.aif','.mp3','.m4a'};

wf_color = [99 99 99]/255; % gray waveform color
wf_position = [1 1 1000 200]; % size and position of waveform plot
wf_ext = '.png';

low_freq_range = 160; %Hz
low_freq_thresh = 0.001;

%% Load
path = '/Users/jamesmclean/Dropbox/repos/popup_slicer/test_vid_audio/_sausage_audio';

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

% extract filenames and extentions
filenames = cell(1,n_files);
ext = cell(1,n_files);
for i = 1:n_files
    filenames{i} = fullfile(path,d(i).name);
    [~,~,ext{i}] = fileparts(d(i).name);
end

%% cut all the files to the same length
y_all = cell(1,n_files);
y_length = zeros(1,n_files);
fs_all = zeros(1,n_files);
for i = 1:n_files
    [y,fs] = audioread(filenames{i});
    y_all{i} = y;
    y_length(i) = size(y,1);
    fs_all(i) = fs;
end
min_length = min(y_length);

for i = 1:n_files
    y_all{i} = y_all{i}(1:min_length,:);
end

%% Get spectrum
L = 2^nextpow2(min_length);
low_freq_energy = zeros(1,n_files);
for i = 1:n_files
    [Y,f] = single_sided_fft(y_all{i}(:,1),fs_all(i));
    low_freq_energy(i) = median(Y(f<low_freq_range));
end

sausage_waveforms = low_freq_energy > low_freq_thresh;

%% Print waveforms
if nnz(sausage_waveforms > 0)
    % make output folder for waveforms in audio file folder
    wf_folder = fullfile(path,'_audio_wf');
    mkdir(wf_folder);
    
    for i = 1:n_files
        if sausage_waveforms(i)
            % get correct i/o filenames
            [~,name,ext] = fileparts(filenames{i});
            fname_out = fullfile(path,[name '_lowpass' ext]);
            fname_out_wf = fullfile(wf_folder,[name '_lowpass' wf_ext]);
            
            % lowpass
            setenv('fname',filenames{i});
            setenv('fname_out',fname_out);
            !~/Library/HumanEditor/ffmpeg -i $fname -filter_complex "highpass=f=100:width_type=o:w=8" $fname_out
            
            % read lowpassed waveform
            [y,fs] = audioread(fname_out);
            if (size(y,2) == 2)
                y = mean(y,2);
            end
            L = length(y);
            
            % Display
            figure (1);
            set(gcf,'Position',wf_position,'Visible','off');
            plot(y,'Color',wf_color);
            set(gca,'XLim',[1 L],'YLim',[-1 1],'XTickLabel','','YTickLabel','','TickLength',[0 0]);
            export_fig(fname_out_wf,'-transparent');
            
            % Delete lowpass filtered file
            delete(fname_out);
        end
    end
end














