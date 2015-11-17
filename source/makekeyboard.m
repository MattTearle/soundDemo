function [keys,keymapping,notenumber] = makekeyboard(nnotes,ax)

if nargin<1
    nnotes = 132;
end

if nargin<2
    f = figure;
    ax = axes('Parent',f,'Position',[0.1 0.4 0.8 0.2]);
end

keys = gobjects(nnotes,1);
ktype = ones(nnotes,1);

for k = 1:nnotes
    oct = floor((k-1)/12);
    j = k - 12*oct;
    octoff = 7*oct;
    if ismember(j,[2 4 7 9 11])
        % black key
        xoff = octoff + ceil(j/2);
        keys(k) = patch([xoff-0.4 xoff-0.4 xoff+0.4 xoff+0.4],[0.5 1 1 0.5],'k');
        ktype(k) = 2;
    else
        xoff = octoff + ceil((j+1)/2);
        keys(k) = patch([xoff-1 xoff-1 xoff xoff],[0 1 1 0],'w');
    end
end

[~,notenumber] = sort(ktype,'descend');
keys = keys(notenumber);
ax.Children = keys;
ax.XTick = [];
ax.YTick = [];
ax.XLim = [0 7*nnotes/12];
ax.YLim = [0 1];

[~,keymapping] = sort(notenumber);
