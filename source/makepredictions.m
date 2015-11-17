instnames = categories(instrument);
instrument = mergecats(instrument,instnames(~cellfun(@isempty,regexp(instnames,'Trombone'))),'Trombone');
instrument = mergecats(instrument,instnames(~cellfun(@isempty,regexp(instnames,'Flute'))),'Flute');
instrument = mergecats(instrument,instnames(~cellfun(@isempty,regexp(instnames,'Clarinet'))),'Clarinet');
instrument = mergecats(instrument,instnames(~cellfun(@isempty,regexp(instnames,'Saxophone'))),'Saxophone');
instrument = renamecats(instrument,'Bb Trumpet','Trumpet');
hist(instrument)

%%
instnames = categories(instrument);
insts2keep = instnames([1:3,5:8,10,14,18:end]);
idx = ~ismember(instrument,insts2keep);
soundclips(:,idx) = [];
note(idx) = [];
instrument(idx) = [];
spec(:,idx) = [];
instrument = removecats(instrument);
hist(instrument)
idx = find(~idx);

%%
cvp = cvpartition(length(instrument),'holdout',0.25);
trainidx = training(cvp);
testidx = test(cvp);
bt_inst = TreeBagger(200,spec(:,trainidx)',instrument(trainidx),'OOBPred','On');
plot(oobError(bt_inst))

%%
bt_inst = TreeBagger(150,spec(:,trainidx)',instrument(trainidx));
instpred = predict(bt_inst,spec(:,testidx)');

%%
X = [spec',double(instrument)];
bt_note = TreeBagger(200,X(trainidx,:),note(trainidx),'OOBPred','On','CategoricalPredictors',133);
plot(oobError(bt_note))
ipcat = categorical(instpred,categories(instrument));
notepred = predict(bt_note,[spec(:,testidx)',double(ipcat)]);

%%
predictions = table(idx(testidx),cellstr(instrument(testidx)),cellstr(note(testidx)),instpred,notepred,'VariableNames',{'Index','Instrument','Note','PredictedInstrument','PredictedNote'})

% save predictiontrees predictions
