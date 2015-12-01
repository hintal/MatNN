classdef RandDistort < nn.layers.template.BaseLayer
% RandDistort
% top1 = distorted data
% top2 = affine matrix

    % Default parameters
    properties (SetAccess = protected, Transient)
        default_randDistort_param = {
            'angle'  [-50, 50] ...
            'scaleX' [0.3,  1] ...
            'scaleY' [0.3,  1] ...
            'scaleEQ'   false  ... % set to true if you want scaleX = scaleY
            'shiftX' [0,  0.3] ...
            'shiftY' [0,  0.3] ...
            'extend' [28,  28] ... % must >=0
            'mix'    0      ... % mix other images in the same batch, value = mix times
        };
    end

    % intermediate savings (computed values, recomputed every time)
    properties (Access = protected)
        forwardHandle;
    end


    methods
        function v = propertyDevice(obj)
            v = obj.propertyDevice@nn.layers.template.BaseLayer();
            v.forwardHandle = 1;
        end
        
        function varargout = f(obj, in, angles, scaleX, scaleY, scaleEQ, shiftX, shiftY, extend, doMix)
            error('not implemented yet.');
        end
        function varargout = gf(obj, in, angles, scaleX, scaleY, scaleEQ, shiftX, shiftY, extend, doMix)
            out = in.*single(0);
            s = nn.utils.size4D(in);
            len = prod(s);
            ral = gpuArray.rand(s(4),1, 'single')*(angles(2)-angles(1))+angles(1);
            if scaleEQ
                r = gpuArray.rand(s(4),1, 'single');
                rsx = r*(scaleX(2)-scaleX(1))+scaleX(1);
                rsy = r*(scaleY(2)-scaleY(1))+scaleY(1);
            else
                rsx = gpuArray.rand(s(4),1, 'single')*(scaleX(2)-scaleX(1))+scaleX(1);
                rsy = gpuArray.rand(s(4),1, 'single')*(scaleY(2)-scaleY(1))+scaleY(1);
            end

            rix = gpuArray.rand(s(4),1, 'single')*(shiftX(2)-shiftX(1))+shiftX(1);
            riy = gpuArray.rand(s(4),1, 'single')*(shiftY(2)-shiftY(1))+shiftY(1);
            w = gpuArray.zeros(1,1,6,s(4), 'single');
            %rix = rix-(rsx-1)./2;
            %riy = riy-(rsy-1)./2;

            w(1,1,1,:) = cosd(ral).*rsx;
            w(1,1,2,:) = sind(ral).*rsy;
            w(1,1,3,:) = -sind(ral).*rsx;
            w(1,1,4,:) = cosd(ral).*rsy;
            
            w(1,1,5,:) = rix;
            w(1,1,6,:) = riy;
            obj.forwardHandle.GridSize = ceil(len/obj.MaxThreadsPerBlock);
            if all(extend==0)
                out = feval(obj.forwardHandle, in, gpuArray(int32(s)), w, gpuArray(int32(len)), out);
            else
                tmpp = feval(obj.forwardHandle, in, gpuArray(int32(s)), w, gpuArray(int32(len)), out);
                out = gpuArray.zeros(extend(1)+s(1),extend(2)+s(2),1,s(4),'single');
                randPosx = randi(extend(1)+1,1,s(4));
                randPosy = randi(extend(2)+1,1,s(4));
                for i=1:s(4)
                    out(randPosy(i):(randPosy(i)+s(1)-1), randPosx(i):(randPosx(i)+s(2)-1),1,i) = tmpp(:,:,1,i);
                end
            end

            if doMix > 0
                maxV = max(out(:));
                for i=1:(doMix-1)
                    oo = out(:,:,:,randperm(s(4)));
                    oo = circshift(oo,randi(s(1)),1);
                    oo = circshift(oo,randi(s(2)),2);
                    out = min(out + oo, maxV);
                end
            end

            varargout{1} = out;
            
            if numel(nargout)==2
                ww = reshape(w,2,3,[]);
                w = gpuArray.zeros(3,3,s(4),'single');
                w(1:2,1:3,:) = ww;
                w(3,3,:) = 1.0;
                w = pagefun(@inv,w);
                w = w(1:2,1:3,:);
                w = reshape(w,1,1,6,[]);
                varargout{2} = w;
            end
        end
        function [in_diff] = b(obj, varargin)
            in_diff = [];
        end

        function [data, net] = forward(obj, nnObj, l, opts, data, net)
            p = obj.params.randDistort;
            if opts.gpuMode
                if numel(l.top)==1
                    data.val{l.top} = obj.gf(data.val{l.bottom}, p.angle, p.scaleX, p.scaleY, p.scaleEQ, p.shiftX, p.shiftY, p.extend, p.mix);
                elseif numel(l.top)==2
                    [data.val{l.top(1)}, data.val{l.top(2)}] = obj.gf(data.val{l.bottom}, p.angle, p.scaleX, p.scaleY, p.scaleEQ, p.shiftX, p.shiftY, p.extend, p.mix);
                else
                    error('top number mismatch.');
                end
            else
                error('RandDistort Layer : only support gpu mode currently.');
            end
        end
        function [data, net] = backward(obj, nnObj, l, opts, data, net)
            data = nn.utils.accumulateData(opts, data, l);
        end

        function outSizes = outputSizes(obj, opts, l, inSizes, varargin)
            p = obj.params.randDistort;
            if numel(inSizes)==1
                outSizes = {[p.extend(1)+inSizes{1}(1), p.extend(2)+inSizes{1}(2),inSizes{1}(3), inSizes{1}(4)]};
            else
                outSizes = {[p.extend(1)+inSizes{1}(1), p.extend(2)+inSizes{1}(2),inSizes{1}(3), inSizes{1}(4)], [1,1,6,inSizes{1}(4)]};
            end
        end
        function setParams(obj, l)
            obj.setParams@nn.layers.template.BaseLayer(l);
            p = obj.params.randDistort;
            assert(all(p.extend>=0));
        end
        function [outSizes, resources] = setup(obj, opts, l, inSizes, varargin)
            [outSizes, resources] = obj.setup@nn.layers.template.BaseLayer(opts, l, inSizes, varargin{:});
            assert(numel(l.bottom)==1);
            assert(numel(l.top)>=1 && numel(l.top)<=2);
            obj.createGPUFun(inSizes{1});
        end
        function createGPUFun(obj, sampleSize)
            mf = fileparts(mfilename('fullpath'));
            ptxp = fullfile(mf, 'private', 'affine.ptx');
            cup = fullfile(mf, 'private', 'affine.cu');
            obj.forwardHandle = nn.utils.gpu.createHandle(prod(sampleSize), ptxp, cup, 'AffineForward');
        end
    end

end
