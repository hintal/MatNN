classdef SoftMaxLoss < nn.layers.template.LossLayer


    properties (Access = {?nn.layers.template.BaseLayer, ?nn.layers.template.LossLayer})
        threshold = realmin('single');
        batchSize = 1;
        ind         = [];
        N           = [];
        ll          = [];
        accumulateN = single(0);
        accumulateL = single(0);
    end
    

    methods
        function v = propertyDevice(obj)
            v = obj.propertyDevice@nn.layers.template.LossLayer();
            v.threshold = 2;
            v.batchSize = 0;
            v.ind         = 2;
            v.N           = 2;
            v.ll          = 2;
            v.accumulateN = 2;
            v.accumulateL = 2;
        end
        function loss = f(obj, in, label, varargin) % varargin{1} = label_weight
            %reshape
            resSize    = nn.utils.size4D(in);
            labelSize  = nn.utils.size4D(label);
            if resSize(4) == numel(label) || resSize(1) == numel(label)
                label = reshape(label, [1, 1, 1 resSize(4)]);
                label = repmat(label, [resSize(1), resSize(2)]);
            else
                if ~isequal(resSize([1,2,4]), labelSize([1,2,4]))
                    error('Label size must be Nx1, 1xN or HxWx1xN.');
                end
            end

            obj.calc_internalPara(resSize, label);

            % Do softmax
            y = exp( bsxfun(@minus, in, max(in, [], 3)) );
            y = bsxfun(@rdivide, y, sum(y,3));
            y = y(obj.ind);

            if numel(varargin)==1
                label_weight = varargin{1}(obj.ll);
                obj.N = sum(label_weight(:));
                loss = -sum( label_weight .* log(max(y,obj.threshold)))/obj.N;
            else
                obj.N = resSize(1)*resSize(2)*resSize(4);
                loss = -sum(log(max(y,obj.threshold)))/obj.N;
            end
            obj.batchSize = resSize(4);

        end

        % must call .f() first
        function in_diff = b(obj, in, out_diff, varargin)
            y = exp( bsxfun(@minus, in, max(in, [], 3)) );
            y = bsxfun(@rdivide, y, max(sum(y,3), obj.threshold));
            y(obj.ind)  = y(obj.ind)-1;
            if numel(varargin)==1
                in_diff = bsxfun(@times, varargin{1}, (y.*out_diff)/obj.N );
            else
                in_diff = (y.*out_diff)/obj.N;
            end
        end

        function calc_internalPara(obj, resSize, label)
            % Calc correspond indices
            labelQ  = label >= obj.params.loss.labelIndex_start;
            index   = (1:numel(label))' -1;
            index   = index(labelQ(:));
            %index   = find(labelQ(:))-1;
            labelQ  = index+1;
            label   = label(:);
            label   = label(labelQ)-obj.params.loss.labelIndex_start; % DO NOT ADD 1, we calc zero-based ind.
            index   = mod(index, resSize(1)*resSize(2)) + ...
                      label*resSize(1)*resSize(2) + ...
                      floor(index/(resSize(1)*resSize(2)))*resSize(1)*resSize(2)*resSize(3) + ...
                      1; % ADD 1 to match matlab 1-based ind
            obj.ind = index;
            obj.ll  = labelQ;
        end

        % Forward function for training/testing routines
        function [top, weights, misc] = forward(obj, opts, top, bottom, weights, misc)
            if numel(bottom) == 3
                loss = obj.params.loss.loss_weight * obj.f(bottom{1}, bottom{2}, bottom{3});
            else
                loss = obj.params.loss.loss_weight * obj.f(bottom{1}, bottom{2});
            end
            
            if obj.params.loss.accumulate
                if opts.currentIter == 1
                    obj.accumulateL = obj.accumulateL*0;
                    obj.accumulateN = obj.accumulateN*0;
                end
                obj.accumulateL = obj.accumulateL + loss*obj.batchSize;
                obj.accumulateN = obj.accumulateN + obj.batchSize;
                loss = obj.accumulateL/obj.accumulateN;
            end
            top{1} = loss;
        end
        % Backward function for training/testing routines
        function [bottom_diff, weights_diff, misc] = backward(obj, opts, top, bottom, weights, misc, top_diff, weights_diff)
            p = obj.params.loss;
            if numel(bottom) == 3
                bd = p.loss_weight * obj.b(bottom{1}, top_diff{1}, bottom{3});
            else
                bd = p.loss_weight * obj.b(bottom{1}, top_diff{1});
            end
            if ~isa(bd,'gpuArray') && opts.gpuMode
                bd = gpuArray(bd);
            end
            if numel(bottom) == 3
                bottom_diff = {bd,[],[]};
            else
                bottom_diff = {bd,[]};
            end
        end

        % Calc Output sizes
        function outSizes = outputSizes(obj, opts, inSizes)
            resSize = inSizes{1};
            ansSize = inSizes{2};
            if ~isequal(resSize(4),prod(ansSize))
                if ~(isequal(resSize([1,2,4]), ansSize([1,2,4])) && ansSize(3) == 1) && ~(isequal(resSize(4), ansSize(4)) && isequal(ansSize(1:3),[1 1 1]))
                    error('Label size must be Nx1, 1xN or HxWx1xN.');
                end
            end
            outSizes = {[1,1,1,1]};
        end

        function setParams(obj, baseProperties)
            obj.setParams@nn.layers.template.BaseLayer(baseProperties);
            obj.threshold = obj.params.loss.threshold;
        end

        function [outSizes, resources] = setup(obj, opts, baseProperties, inSizes)
            [outSizes, resources] = obj.setup@nn.layers.template.LossLayer(opts, baseProperties, inSizes);
            assert(numel(baseProperties.bottom)>=2 && numel(baseProperties.bottom)<=3);
            assert(numel(baseProperties.top)==1);
            if opts.gpuMode
                obj.accumulateN = gpuArray.zeros(1,1,'single');
                obj.accumulateL = gpuArray.zeros(1,1,'single');
            end
        end

    end
    

end