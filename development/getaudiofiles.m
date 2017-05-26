
p = {'http://theremin.music.uiowa.edu/';'MIS-Pitches-2012/'};
url = [p{:},'MISBbTrumpet2012.html'];
txt = webread(url);

%%
pages = regexp(txt,'<a href="([\./]*MIS\w*?.html)">','tokens');
pages = cat(1,pages{:});
for pagenum = 1:length(pages)
    thispage = pages{pagenum};
    if strncmp('../',thispage,3)
        thispath = p{1};
        thispage = thispage(4:end);
    else
        thispath = [p{:}];
    end
    thispage = [thispath,thispage]; %#ok<AGROW>
    thistxt = [];
    try
        thistxt = webread(thispage);
    catch
    end
    if ~isempty(thistxt)
        files = regexp(thistxt,'<a href="([^>]*?\.aiff*)"','tokens');
        files = cat(1,files{:});
        for filenum = 1:length(files)
            [d,f,e] = fileparts(files{filenum});
            [~,d] = fileparts(d);
            d = ['AudioFiles',filesep,d]; %#ok<AGROW>
            if ~exist(d,'dir')
                mkdir(d)
            end
            thisfile = [d,filesep,f,e];
            foo = dir(thisfile);
            if isempty(foo) || (foo.bytes == 0)
                try
                    websave(thisfile,[thispath,files{filenum}]);
                catch
                end
            end
        end
    end
end
