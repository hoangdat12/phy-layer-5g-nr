function out = LDPCrateMatching(in, outlen, rv, modulation, nlayers, varargin)
%LDPCrateMatching Perform 5G NR LDPC rate matching.
%   OUT = LDPCrateMatching(IN, OUTLEN, RV, MODULATION, NLAYERS) performs
%   rate matching on the LDPC-encoded input bits IN to produce an output
%   bit vector OUT of length OUTLEN, according to 3GPP TS 38.212 Section
%   5.4.2.
%
%   OUT = LDPCrateMatching(IN, OUTLEN, RV, MODULATION, NLAYERS, NREF)
%   performs rate matching with a limited soft buffer size NREF.
%
%   Inputs:
%       IN          - Matrix of input bits after LDPC encoding. Each column
%                     represents a separate code block from a single
%                     transport block. The values are typically 0s and 1s.
%       OUTLEN      - Desired number of output bits (E). This is a scalar
%                     integer.
%       RV          - Redundancy Version, specified as 0, 1, 2, or 3.
%       MODULATION  - Modulation scheme, specified as a character vector or
%                     string, e.g., 'QPSK', '16QAM', '64QAM', '256QAM'.
%       NLAYERS     - Number of transmission layers (scalar integer, >= 1).
%       NREF        - (Optional) Limited soft buffer size for rate matching.
%                     If not provided, the full buffer size (N) is used.
%
%   Output:
%       OUT         - Column vector of output bits after rate matching and
%                     concatenation. The length of this vector is OUTLEN.
%
%   Usage Example:
%       % --- Parameters ---
%       E = 9000;         % Target output length
%       rv = 0;           % Redundancy version
%       modScheme = '64QAM';
%       numLayers = 2;
%
%       % --- LDPC Encoding (Simplified for example) ---
%       % In a real scenario, this would come from an actual LDPC encoder
%       % that produces a codeword of a valid length (e.g., 66*Zc or 50*Zc).
%       N = 8448;         % Example codeword length (BG1, Zc=128)
%       ldpcEncodedBits = randi([0 1], N, 1); % One code block
%
%       % --- Perform Rate Matching ---
%       rateMatchedBits = LDPCrateMatching(ldpcEncodedBits, E, rv, ...
%                                          modScheme, numLayers);
%
%       % --- Display Results ---
%       disp(['Length of rate-matched output: ', num2str(length(rateMatchedBits))]);
%       % disp('First 10 bits of the output:');
%       % disp(rateMatchedBits(1:10)');

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