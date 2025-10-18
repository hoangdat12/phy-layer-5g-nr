function out = LDPCrateMatching(in, outlen, rv, modulation, nlayers, varargin)
%LDPCrateMatching Perform 5G NR LDPC rate matching.
%
% This function performs two main operations:
% 1. It distributes the total target output length 'outlen' among the
%    multiple input code blocks (the columns of 'in'). Since the total
%    length might not be perfectly divisible, some blocks get a slightly
%    larger target size (E_ceil) and some get a smaller one (E_floor).
% 2. For EACH code block, it performs rate matching using a circular buffer
%    to select bits, followed by bit interleaving to produce the target
%    number of bits for that block.
%
% The final output is the concatenation of all processed blocks.
%
% ## VISUALIZATION OF THE ENTIRE PROCESS ##
%
% Input ('in' with C code blocks)
%  Block 1       Block 2         Block C
% /-------\     /-------\       /-------\
% | bits  |     | bits  |  ...  | bits  |
% \-------/     \-------/       \-------/
%     |             |               |
%     |             |               |
%     V             V               V
%
% Step 1: Each block is processed individually by 'cbsRateMatch'
%         to a target length of E_floor or E_ceil.
%
%  (Inside cbsRateMatch for ONE block)
%  1. Select bits using circular buffer --> [ Intermediate Bits ]
%  2. Interleave bits (reshape/transpose) --> [ Processed Block ]
%
% Processed Block 1   Processed Block 2     Processed Block C
%  (Length E_floor)    (Length E_ceil)       (Length E_ceil)
% /---------------\   /---------------\     /---------------\
% | processed_bits|   | processed_bits| ... | processed_bits|
% \---------------/   \---------------/     \---------------/
%         |                 |                     |
%         |                 |                     |
%         V                 V                     V
%
% Step 2: Concatenate all processed blocks into a single output stream.
%
% Final Output ('out' with length 'outlen')
% /-------------------------------------------------\
% | Block 1 Bits | Block 2 Bits | ... | Block C Bits |
% \-------------------------------------------------/
%

    % Validate Input
    narginchk(5,6);
    if nargin == 5
        Nref = []; 
    else
        Nref = varargin{1};
    end

    [N, C] = size(in);

    % Determine the soft buffer size (Ncb) for the circular buffer
    if ~isempty(Nref)
        Ncb = min(N, Nref); % Limited buffer rate matching
    else
        Ncb = N;            % Full buffer size
    end

    ZcVec = [2:16 18:2:32 36:4:64 72:8:128 144:16:256 288:32:384];

    % Determine Base Graph (BG) number from the codeword length N
    if any(N == (ZcVec.*66))
        bg = 1; % Base Graph 1
    else 
        bg = 2; % Base Graph 2
    end

    % Set parameters based on the Base Graph
    switch bg
        case 1
            numRow = 66;
            rv_table = [0 17 33 56]; % rv-to-k0 mapping for BG1
        case 2
            numRow = 50;
            rv_table = [0 13 25 43]; % rv-to-k0 mapping for BG2
    end

    % Lifting size Zc
    Zc = N / numRow;

    % Get the starting position parameter from the rv_table
    rv_p = rv_table(rv + 1); % MATLAB uses 1-based indexing

    % Calculate k0, the starting position in the circular buffer
    k0 = floor(rv_p * Ncb / N) * Zc;

    % Get Qm, the number of bits per modulation symbol
    switch modulation
        case {'pi/2-BPSK', 'BPSK'}, Qm = 1;
        case 'QPSK',              Qm = 2;
        case '16QAM',             Qm = 4;
        case '64QAM',             Qm = 6;
        otherwise,                Qm = 8; % '256QAM'
    end

    out = zeros(outlen, 1, class(in));
    writeIdx = 1; % Use an index to track the current write position

    % 1. Calculate the total number of modulation symbols to distribute across all blocks.
    totalSymbolsPerLayer = outlen / (nlayers * Qm);

    % 2. Determine how many code blocks get the larger (ceil) size.
    % This is the remainder of the division.
    numBlocksWithCeilSize = mod(totalSymbolsPerLayer, C);

    % 3. The rest of the code blocks get the smaller (floor) size.
    numBlocksWithFloorSize = C - numBlocksWithCeilSize;

    % 4. Pre-calculate the two possible bit lengths for the code blocks.
    baseSymbolsPerBlock = totalSymbolsPerLayer / C;
    E_floor = nlayers * Qm * floor(baseSymbolsPerBlock); % The smaller of the two possible lengths
    E_ceil  = nlayers * Qm * ceil(baseSymbolsPerBlock);  % The larger of the two possible lengths

    for r = 0:C-1
        % Assign the appropriate length (E) to the current code block.
        if r < numBlocksWithFloorSize
            % The first 'numBlocksWithFloorSize' blocks get the smaller length.
            E = E_floor;
        else
            % The remaining blocks get the larger length.
            E = E_ceil;
        end

        % Perform rate matching on the current code block.
        e_block = cbsRateMatch(in(:,r+1), E, k0, Ncb, Qm);
        
        % Write the result directly into the pre-allocated vector.
        out(writeIdx : writeIdx + E - 1) = e_block;
        
        % Update the write position for the next block.
        writeIdx = writeIdx + E;
    end

end


function e = cbsRateMatch(d,E,k0,Ncb,Qm)
% Rate match a single code block segment as per TS 38.212 Section 5.4.2

    % Bit selection, Section 5.4.2.1
    k = 0;
    j = 0;
    e = zeros(E,1,class(d));
    while k < E
        if d(mod(k0+j,Ncb)+1) ~= -1     % Filler bits
            e(k+1) = d(mod(k0+j,Ncb)+1);
            k = k+1;
        end
        j = j+1;
    end

    % Bit interleaving, Section 5.4.2.2
    e = reshape(e,E/Qm,Qm);
    e = e.';
    e = e(:);
end