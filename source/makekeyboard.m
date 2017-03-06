function [keys,keymapping,notenumber] = makekeyboard(nnotes,ax)
% Makes a graphical keyboard in given axes
%
% Inputs: nnotes = number of keys in the keyboard (starting from a C)
%         ax = axes object
%
% Outputs: keys = array of graphics patches representing the keys (each key
%                 is just a black or white rectangle)
%          keymapping = array of patch indices for each key; that is, the
%                       jth key on the keyboard is represented by the patch
%                       object keys(keymapping(j))
%          notenumber = array of indices indicating which key is
%                       represented by each patch; that is, the jth patch
%                       [keys(j)] represents the notenumber(j) key on the
%                       keyboard.

% Set default number of keys
if nargin<1
    nnotes = 132;
end
% Make a new figure if no axes given
if nargin<2
    f = figure;
    ax = axes('Parent',f,'Position',[0.1 0.4 0.8 0.2]);
end

% Preallocate some arrays
keys = gobjects(nnotes,1);
ktype = ones(nnotes,1);  % 1 = white, 2 = black

% Loop over keys
for k = 1:nnotes
    % Which octave are we in?
    oct = floor((k-1)/12);
    % Which note in this octave?
    j = k - 12*oct;
    % Set baseline x position for this octave
    octoff = 7*oct;
    if ismember(j,[2 4 7 9 11])
        % black key
        xoff = octoff + ceil(j/2);
        keys(k) = patch([xoff-0.4 xoff-0.4 xoff+0.4 xoff+0.4],[0.5 1 1 0.5],'k');
        ktype(k) = 2;
    else
        % white key
        xoff = octoff + ceil((j+1)/2);
        keys(k) = patch([xoff-1 xoff-1 xoff xoff],[0 1 1 0],'w');
    end
end

% Sort patches so black keys are on top
[~,notenumber] = sort(ktype,'descend');
keys = keys(notenumber);
ax.Children = keys;
% Format axes to make a nice picture
ax.XTick = [];
ax.YTick = [];
ax.XLim = [0 7*nnotes/12];
ax.YLim = [0 1];

% Get mapping of keys to patch objects
[~,keymapping] = sort(notenumber);
