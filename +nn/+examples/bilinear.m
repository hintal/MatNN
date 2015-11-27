function trainer = bilinear()

trainer = nn.nn('BILINEAR');
inputData1 = {ones(3,3,3,3)};
inputData1{1}(1) = 10;

inputData2 = {ones(3,3,3,3)};
inputData2{1}(1) = 20;

targetData = {ones(3,3,3,3)};

trainer.add({
    'type' 'data.Replicate'  ...
    'name' 'data1'  ...
    'top'  {'data1'}  ...
    'data_param' {
        'src' ''  ...
        'root_folder' ''  ...
        'batch_size' []  ...
               'full' false  ...
            'shuffle' false  ...
        } ...
    'replicate_param' {
           'value' inputData1  ...
        } ...
    'phase' 'test'  ...
    });
trainer.add({
    'type' 'data.Replicate'  ...
    'name' 'data2'  ...
    'top'  {'data2'}  ...
    'data_param' {
        'src' ''  ...
        'root_folder' ''  ...
        'batch_size' []  ...
               'full' false  ...
            'shuffle' false  ...
        } ...
    'replicate_param' {
           'value' inputData2  ...
        } ...
    'phase' 'test'  ...
    });
trainer.add({
    'type' 'data.Replicate'  ...
    'name' 'target'  ...
    'top'  {'target'}  ...
    'data_param' {
        'src' ''  ...
        'root_folder' ''  ...
        'batch_size' []  ...
               'full' false  ...
            'shuffle' false  ...
        } ...
    'replicate_param' {
           'value' targetData  ...
        } ...
    'phase' 'test'  ...
    });
trainer.add({
    'type'   'Bilinear'  ...
    'name'   'bilinear'  ...
    'bottom' {'data1', 'data2'}  ...
    'top'    'bilinear'  ...
    'bilinear_param' {
        'transpose' false  ...
        }  ...
    'phase' 'test'  ...
    })
trainer.add({
    'type'   'loss.EuclideanLoss'  ...
    'name'   'loss'  ...
    'bottom' {'bilinear', 'target'}  ...
    'top'    'loss'  ...
    'phase'  'test'  ...
    });


trainer.setPhaseOrder('test');
trainer.setRepeat(5);
trainer.setSavePath(fullfile('data','exp'));
trainer.setGpu(1);

testOp.numToNext           = 100;
testOp.numToSave           = [];
testOp.displayIter         = 100;
testOp.showFirstIter       = false;
testOp.learningRate        = 1;
trainer.setPhasePara('test', testOp);

trainer.run();

end

function res = lrPolicy(globalIterNum, currentPhaseTotalIter, lr, gamma, power, steps)
     res = lr*(gamma^floor((currentPhaseTotalIter-1)/steps));
end

