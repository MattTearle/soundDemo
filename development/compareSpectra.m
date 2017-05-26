load instrumentspectra

spec = sqrt(bsxfun(@rdivide,spec,max(spec)));
r = groot;
dx = r.ScreenSize(3) - r.ScreenSize(1);
dy = r.ScreenSize(4) - r.ScreenSize(2);
f = figure('Position',[r.ScreenSize(1)+0.1*dx,r.ScreenSize(2)+0.1*dy,0.8*dx,0.8*dy]);

n = 5*3;
idx = randsample(size(spec,2),n);

for i = 1:n
    inst = idx(i);
    ax = subplot(5,3,i);
    
    y = soundclips(:,inst);
    playfunc = @(h,e) soundsc(y,44100);
    
    [keys,keybdmap] = makekeyboard(132,ax);
    
    mx = spec(:,inst);
    for k = 1:length(mx)
        j = keybdmap(k);
        if (keys(j).FaceColor(1) == 1)
            keys(j).FaceColor = [1 1-mx(k) 1-mx(k)];
        else
            keys(j).FaceColor = [mx(k) 0 0];
        end
        keys(k).ButtonDownFcn = playfunc;
    end
   
    title(ax,[instrument{inst},'  ',note{inst}])
end
