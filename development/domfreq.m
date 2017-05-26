[x,fs] = audioread('Trumpet.novib.ff.Bb3.stereo.aif'); %'Flute.vib.pp.B3B4.aiff'); %Trumpet.novib.ff.G5.stereo.aif');
% x = x(1747080:end);
sound(x,fs)

%%
Y = fft(x); % Take the FFT
n = length(Y); % FFT length
range = ceil((n+1)/2);
P = Y.*conj(Y)/n; % Compute the power
P = P(1:range);
Nyq = fs/2; % Nyquist frequency
f = (0:range-1)*Nyq/range; % Frequency scale

%%
figure
semilogy(f,P)

%%
[~,idx] = max(P);
semitones = round(12*log2(f(idx)/261.6255653006));
octs = fix(semitones/12);
intvs = semitones - octs*12 + 1;
octs = octs + 4;
notes = {'C','C#','D','Eb','E','F','F#','G','G#','A','Bb','B'};
note = [notes{intvs},num2str(octs)]

%%
fRef = 440*(2.^((-57:74)/12))';
idx = round(12*log2(f/261.6255653006)) + 49;
P(idx<=0) = [];
idx(idx<=0) = [];
% peakPow = accumarray(idx(:),P(:),size(fRef),@max);
[mx,sd,mn,nm] = grpstats(P(:),idx(:),{'max','std','mean','gname'});

idx = str2double(nm);
fRef = fRef(idx);

[keys,keybdmap] = makekeyboard;

mx = sqrt(mx/max(mx));
for k = 1:length(mx)
    j = keybdmap(idx(k));
    if (keys(j).FaceColor(1) == 1)
        keys(j).FaceColor = [1 1-mx(k) 1-mx(k)];
    else
        keys(j).FaceColor = [mx(k) 0 0];
    end
end

%%
% b = bar(fRef,peakPow);
% b.Parent.YScale = 'log';

figure
subplot(3,1,1)
s = stem(fRef,mx);
s.Parent.YScale = 'log';

subplot(3,1,2)
s = stem(fRef,mn);
s.Parent.YScale = 'log';

subplot(3,1,3)
s = stem(fRef,sd);
s.Parent.YScale = 'log';

