bckgrnd = 240;

fname = {'loudspeaker.png','loudspeaker_delete.png','loudspeaker_run.png','media_play_green.png','media_pause.png'};
vname = {'spkr','spkroff','spkrrun','play','pause'};

for k = 1:length(fname)
x = imread(fname{k});
idx = all(x==0,3);
x(repmat(idx,1,1,3)) = bckgrnd;
s.(vname{k}) = imresize(x,[48 48]);
end

save('icons','-struct','s')
