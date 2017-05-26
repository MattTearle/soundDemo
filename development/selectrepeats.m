load instrumentspectra_trim

[g,inst,n] = findgroups(instrument,note);
num = histcounts(g,'BinMethod','integers');
repgrp = g(num>3);
idx = find(ismember(g,repgrp));
foo = g(idx);
[g,sidx] = sort(foo);
idx = idx(sidx);

f1 = figure;
for k = 1:length(idx)
    [r,c] = ind2sub([16 16],k);
    uicontrol('Style','pushbutton','Units','normalized',...
        'Position',[c-1,r-1,1,1]/16,'String',num2str(idx(k)),...
        'Callback',@(a,b) soundsc(soundclips(:,idx(k)),44100))
end

f2 = figure;
for k = 1:length(idx)
    [r,c] = ind2sub([16 16],k);
    uicontrol('Style','togglebutton','Units','normalized',...
        'Position',[c-1,r-1,1,1]/16,'String',num2str(idx(k)))
end