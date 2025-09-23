function codeBlocks = LDPCsegmentation(in_bits, bg)
%LDPCsegmentation Segments a transport block into code blocks for 5G NR LDPC encoding.
%
%   codeBlocks = LDPCsegmentation(in_bits, bg) takes a transport block (bit stream)
%   and a base graph index, then performs the segmentation process
%   according to the 5G NR standard. This process includes:
%   1. Appending a 24-bit CRC to each segment if the transport block is large enough.
%   2. Prepending filler bits to the front to ensure all final code blocks
%      have an equal size.
%   3. Formatting the result into an output matrix.
%
%   INPUTS:
%       in_bits: A row vector containing the original data bit stream to be processed.
%       bg:      The LDPC Base Graph to use, which must be 1 or 2.
%
%   OUTPUT:
%       codeBlocks: A matrix of size K x C, where:
%                   - K is the size of each code block after processing.
%                   - C is the number of code blocks.
%                   - **Each COLUMN** of the matrix is a complete code block.
%
%   KEY INTERNAL PARAMETERS:
%       B:       The initial size of the input transport block (in bits).
%       Kcb:     The maximum size (in bits) that a single code block can have,
%                as defined by the standard for each base graph.
%       C:       The total number of code blocks that the transport block is
%                segmented into.
%       L:       The length of the CRC (0 or 24) appended to each segment when C > 1.
%       BPrime:  The total number of bits after all per-segment CRCs are added
%                (B' in the standard, where B' = B + C*L).
%       K:       The final, uniform size of each code block after filler bits
%                are added (K' in the standard).
%       F:       The number of filler bits prepended to the stream to ensure the
%                total length is perfectly divisible by C.
%
%   EXAMPLE:
%       % This example assumes you have the CRCadd(bits, type) function from earlier.
%
%       % Create an input bit stream long enough to require segmentation
%       B = 10000; % Number of bits > 8448
%       input_data = randi([0 1], 1, B);
%       base_graph = 1;
%
%       % Call the segmentation function
%       codeBlocksMatrix = segmentLDPC(input_data, base_graph);
%
%       % Display the size of the output code block matrix
%       fprintf('Size of the output code block matrix (K x C):\n');
%       disp(size(codeBlocksMatrix));
%
%       % Expected Result Explanation:
%       % For B=10000 and bg=1 (Kcb=8448), the number of code blocks C will be 2.
%       % The final code block size K will be 5024.
%       % Therefore, the output matrix will have a size of 5024 x 2.
%       % The first column is the first code block, the second column is the second.


    % The number of input bit
    B = length(in_bits);

    % Determine Kcb and Kb based on the base graph
    if bg == 1
        Kcb = 8448;
    elseif bg == 2
        Kcb = 3840;
    else
        error("Invalid base graph (bg). Must be 1 or 2.");
    end

    % Determine segmentation parameters C and L
    % BPrime is a new length of 
    if (B <= Kcb)
        % No segmentation needed
        L = 0;
        C = 1;
        BPrime = B;
    else
        % Segmentation is required
        L = 24;
        C = ceil(B / (Kcb - L));
        BPrime = B + C*L;
    end

    % Size of each code block
    K = ceil(BPrime / C);

    % Add CRC for each code block
    if (C > 1) 
        bitWithCRC      = [];
        % The number of data in the segment
        KSegment        = K - L;
        for i = 1:C
            startIdx    = (i-1)*KSegment + 1;
            endIdx      = min(i*KSegment, B); 

            segment     = in_bits(startIdx:endIdx);
            segmentCRC  = CRCadd(segment, '24A');
            bitWithCRC  = [bitWithCRC, segmentCRC];
        end
    else
        bitWithCRC = in_bits;
    end
    
    % Number of filler bits
    F = (K * C) - BPrime;

    % Filler -1 into bitWithCRC
    paddeBits = [-1*ones(1, F), bitWithCRC];

    % Create matrix output 
    % [code     code    code
    %  block    block   block]
    codeBlocks = zeros(K, C);
    for r = 1:C
        startIdx            = (r - 1)*K + 1;
        endIdx              = r*K;

        % Copy into codeBlocks
        codeBlocks(:, r)    = paddeBits(startIdx:endIdx)';
    end
end