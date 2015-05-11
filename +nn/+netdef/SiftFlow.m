opts.scale = 1 ;
opts.initBias = 0.1 ;
opts.weightDecay = 1 ;
opts = vl_argparse(opts, varargin) ;



% Create Net Obj
no = nn.buildnet('SiftFlow_test', 'train');

% Data Top Size
no.setDataBlobSize('data' , [227 227 3    128]);% if you use subbatch, then you should set the N to subbatch number
no.setDataBlobSize('label', [1   1   1000 128]); 

% Block 1
no.newLayer({
            'type'         'layers.convolution'          ...
            'name'         'conv1'                       ...
            'bottom'       {'data'}                      ...
            'top'          {'conv1'}                     ...
            'convolution_param' {                        ...
                           'num_output'   96             ...
                           'kernel_size'  [11 11]        ...
                           'stride'       4              ...
                           'pad'          0
                           }                             ...
            'weight_param' {                             ...
                           'name'         {'w1', 'b1'}   ...
                           'enable_terms' [true, false]  ... % this means don't use bias term
                           'generator'    {@rand, @rand} ...
                           'learningRate' [1 2]          ...
                           'weightDecay'  [1 0]
                           }                             ...
            }) ;
no.newLayer({
            'type'         'relu'    ...
            'name'         'relu1'   ...
            'bottom'       {'conv1'} ...
            'top'          {'relu1'} ...
            }) ;
no.newLayer({
            'type'         'pool'    ...
            'name'         'pool1'   ...
            'bottom'       {'relu1'} ...
            'top'          {'pool1'} ...
            'method'       'max'     ...
            'pool'         [3 3]     ...
            'stride'       2         ...
            'pad'          0
            }) ;
no.newLayer({
            'type'         'normalize' ...
            'bottom'       {'pool1'}   ...
            'name'         'norm1'     ...
            'top'          {'norm1'}   ...
            'param'        [5 1 0.0001/5 0.75]
            }) ;

% Block 2
no.newLayer({
            'type'         'conv'    ...
            'name'         'conv2'   ...
            'bottom'       {'norm1'}  ...
            'top'          {'conv2'} ...
            'weights'      {0.01/opts.scale * randn(5, 5, 48, 256, 'single'), []} ...
            'stride'       1         ...
            'pad'          2         ...
            'learningRate' [1 2]     ...
            'weightDecay'  [opts.weightDecay 0]
            }) ;
no.newLayer({
            'type'         'relu'    ...
            'name'         'relu2'   ...
            'bottom'       {'conv2'} ...
            'top'          {'relu2'} ...
            }) ;
no.newLayer({
            'type'         'pool'    ...
            'name'         'pool2'   ...
            'bottom'       {'relu2'} ...
            'top'          {'pool2'} ...
            'method'       'max'     ...
            'pool'         [3 3]     ...
            'stride'       2         ...
            'pad'          0
            }) ;
no.newLayer({
            'type'         'normalize' ...
            'bottom'       {'pool2'}   ...
            'name'         'norm2'     ...
            'top'          {'norm2'}   ...
            'param'        [5 1 0.0001/5 0.75]
            }) ;

% Block 3
no.newLayer({
            'type'         'conv'    ...
            'name'         'conv3'   ...
            'bottom'       {'norm2'}  ...
            'top'          {'conv3'} ...
            'weights'      {0.01/opts.scale * randn(3, 3, 256, 384, 'single'), []} ...
            'stride'       1         ...
            'pad'          1         ...
            'learningRate' [1 2]     ...
            'weightDecay'  [opts.weightDecay 0]
            }) ;
no.newLayer({
            'type'         'relu'    ...
            'name'         'relu3'   ...
            'bottom'       {'conv3'} ...
            'top'          {'relu3'} ...
            }) ;

% Block 4
no.newLayer({
            'type'         'conv'    ...
            'name'         'conv4'   ...
            'bottom'       {'relu3'}  ...
            'top'          {'conv4'} ...
            'weights'      {0.01/opts.scale * randn(3, 3, 192, 384, 'single'), []} ...
            'stride'       1         ...
            'pad'          1         ...
            'learningRate' [1 2]     ...
            'weightDecay'  [opts.weightDecay 0]
            }) ;
no.newLayer({
            'type'         'relu'    ...
            'name'         'relu4'   ...
            'bottom'       {'conv4'} ...
            'top'          {'relu4'} ...
            }) ;


% Block 5
no.newLayer({
            'type'         'conv'    ...
            'name'         'conv5'   ...
            'bottom'       {'relu4'}  ...
            'top'          {'conv5'} ...
            'weights'      {0.01/opts.scale * randn(3, 3, 192, 256, 'single'), []} ...
            'stride'       1         ...
            'pad'          1         ...
            'learningRate' [1 2]     ...
            'weightDecay'  [opts.weightDecay 0]
            }) ;
no.newLayer({
            'type'         'relu'    ...
            'name'         'relu5'   ...
            'bottom'       {'conv5'} ...
            'top'          {'relu5'} ...
            }) ;
no.newLayer({
            'type'         'pool'    ...
            'name'         'pool5'   ...
            'bottom'       {'relu5'} ...
            'top'          {'pool5'} ...
            'method'       'max'     ...
            'pool'         [3 3]     ...
            'stride'       2         ...
            'pad'          0
            }) ;

% Block 6
no.newLayer({
            'type'         'conv'    ...
            'name'         'fc6'     ...
            'bottom'       {'pool5'} ...
            'top'          {'fc6'}   ...
            'weights'      {
                              0.01/opts.scale * randn(6, 6, 256, 4096, 'single') ...
                              []
                           }         ...
            'stride'       1         ...
            'pad'          0         ...
            'learningRate' [1 2]     ...
            'weightDecay'  [opts.weightDecay 0]
            }) ;
no.newLayer({
            'type'         'relu'    ...
            'name'         'relu6'   ...
            'bottom'       {'fc6'}   ...
            'top'          {'relu6'} ...
            }) ;
no.newLayer({
            'type'         'dropout'    ...
            'name'         'dropout6'   ...
            'bottom'       {'relu6'}    ...
            'top'          {'dropout6'} ...
            'rate'          0.5
            }) ;


% Block 7
no.newLayer({
            'type'         'conv'    ...
            'name'         'fc7'     ...
            'bottom'       {'dropout6'} ...
            'top'          {'fc7'}   ...
            'weights'      {0.01/opts.scale * randn(1, 1, 4096, 4096, 'single'), []} ...
            'stride'       1         ...
            'pad'          0         ...
            'learningRate' [1 2]     ...
            'weightDecay'  [opts.weightDecay 0]
            }) ;
no.newLayer({
            'type'         'relu'    ...
            'name'         'relu7'   ...
            'bottom'       {'fc7'}   ...
            'top'          {'relu7'} ...
            }) ;
no.newLayer({
            'type'         'dropout'    ...
            'name'         'dropout7'   ...
            'bottom'       {'relu7'}    ...
            'top'          {'dropout7'} ...
            'rate'          0.5
            }) ;

% Block 8
no.newLayer({
            'type'         'conv'    ...
            'name'         'fc8'     ...
            'bottom'       {'dropout7'} ...
            'top'          {'fc8'}   ...
            'weights'      {0.01/opts.scale * randn(1, 1, 4096, 1000, 'single'), []} ...
            'stride'       1         ...
            'pad'          0         ...
            'learningRate' [1 2]     ...
            'weightDecay'  [opts.weightDecay 0]
            }) ;
no.newLayer({
            'type'         'relu'    ...
            'name'         'relu8'   ...
            'bottom'       {'fc8'}   ...
            'top'          {'relu8'} ...
            }) ;
%net.layers(end) = [] ; %????? =====================?????

% Block 9
no.newLayer({
            'type'         'softmaxloss'      ...
            'name'         'loss'             ...
            'bottom'       {'relu8', 'label'} ...
            'top'          {'loss'}           ...
            'phase'        'train'
            }) ;


% Accuracy
no.newLayer({
            'type'         'custom'           ...
            'name'         'accuracy'         ...
            'bottom'       {'relu8', 'label'} ...
            'top'          {'accuracy'}       ...
            'phase'        'val'
            }) ;
%net.layers{end+1} = struct('type', 'custom', ...
%                           'forward',  @(a,b,c) XDD(a,b,c,'forward'), ...
%                           'backward', @(a,b,c) XDD(a,b,c,'backward')) ;

% Wrap it in a handle function
net = no.getNet();