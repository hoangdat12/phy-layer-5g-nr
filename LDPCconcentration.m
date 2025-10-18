function d = Concentration(rateMatchedBlocks, E, varargin)
% Concentration  Concatenate rate-matched code blocks into one bit stream.
%
% This function takes multiple code blocks (either as columns of a matrix
% or cells in a cell array) and joins them end-to-end to form a single,
% continuous stream of bits.
%
% Visual representation of the process:
%
%   Input ('rateMatchedBlocks' as a matrix)
%
%   Block 1       Block 2       Block 3
%   /-----\       /-----\       /-----\
%  | b1_1  |     | b2_1  |     | b3_1  |
%  | b1_2  |     | b2_2  |     | b3_2  |
%  |  ...  |     |  ...  |     |  ...  |
%   \-----/       \-----/       \-----/
%
%        |
%        V  CONCATENATION (Joining columns end-to-end)
%        |
%
%   Output ('d' as a single column vector)
%   /-----\
%  | b1_1  | <-- Start of Block 1
%  | b1_2  |
%  |  ...  |
%  +-------+
%  | b2_1  | <-- Start of Block 2
%  | b2_2  |
%  |  ...  |
%  +-------+
%  | b3_1  | <-- Start of Block 3
%  | b3_2  |
%  |  ...  |
%   \-----/
%
% If a target length 'E' is provided, the final stream is either
% truncated (cut) or padded (filled with a value) to match length E.

    % parse args
    padValue = 0;
    if nargin >= 3
        E = varargin{1};
        % allow 'padValue' name-value
        if nargin == 4 && ischar(varargin{2})
            % not used in this signature, but left for extension
        end
    else
        E = [];
    end
    if nargin == 4
        % treat 4th arg as padValue if provided
        padValue = varargin{2};
    end

    % build a column vector of concatenated bits
    if iscell(rateMatchedBlocks)
        d_all = [];
        for i = 1:length(rateMatchedBlocks)
            blk = rateMatchedBlocks{i}(:); % ensure column
            d_all = [d_all; blk];
        end
    else
        % assume matrix: each column is a block
        [L, C] = size(rateMatchedBlocks);
        if C == 1
            d_all = rateMatchedBlocks(:);
        else
            d_all = reshape(rateMatchedBlocks, [], 1); % concat columnwise
        end
    end

    totalLen = length(d_all);

    % if E specified, adjust
    if ~isempty(E)
        if totalLen == E
            d = d_all;
            return;
        elseif totalLen < E
            % pad with padValue
            padLen = E - totalLen;
            d = [d_all; repmat(padValue, padLen, 1)];
            return;
        else
            % truncate to E (take first E bits)
            d = d_all(1:E);
            return;
        end
    else
        % no E specified: return full concatenation
        d = d_all;
        return;
    end
end
