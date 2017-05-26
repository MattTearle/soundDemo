load('C:\MATLAB\sandbox\soundDemo\source\instrumentspectra.mat')

%%
n = length(instrument);
scnew = zeros(17640,n);
for k = 1:n
    scnew(:,k) = decimate(soundclips(:,k),5);
end

%%
soundclips = scnew;
save instrumentspectra_downsamp_int instrument note soundclips spec
