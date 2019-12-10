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