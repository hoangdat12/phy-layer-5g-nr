function cbs = LDPCsegmentation(in, bgn)
% LDPCsegmentation - Segments a transport block for 5G NR LDPC coding.
% It determines the number of code blocks, adds CRCs for segmentation,
% calculates the lifting size, and adds filler bits.
%
%% EXAMPLE
%
% --- Multi-Block Segmentation ---
%
% Let's assume the input is a large block of 10,000 bits and we use Base Graph 1.
%   B = 10000;      % Length of input block 'in'
%   bgn = 1;        % Base Graph Number
%
% Calling the function:
%   cbs = LDPCsegmentation(randi([0 1], B, 1), bgn);
%
% --- Step-by-Step Calculation by the Function ---
%
% 1. **Code Blocks (C):** Since B > 8448, the block is segmented.
%    C = ceil(10000 / (8448 - 24)) = 2 code blocks.
%
% 2. **Size per Block:** The 10,000 bits are split into two segments of 5,000 bits each.
%    A 24-bit CRC is added to each segment.
%    Size after CRC (Kd) = ceil((10000 + 2*24) / 2) = 5024 bits per block.
%
% 3. **Lifting Size (Zc):** The function finds the smallest valid lifting size.
%    For bgn=1, this results in Zc = 240.
%
% 4. **Filler Bits (F):** The total block size K becomes 22 * Zc = 5280.
%    The number of filler bits is F = K - Kd = 5280 - 5024 = 256.
%
% --- Expected Output 'cbs' ---
%
% The output 'cbs' will be a matrix of size 5280x2.
%
% cbs = [ 5000 data bits (Col 1)  |  5000 data bits (Col 2)  ]
%       [   24 CRC bits (Col 1)   |    24 CRC bits (Col 2)   ]
%       [ 256 filler bits (-1)    |  256 filler bits (-1)    ]
%
%       Total Rows: 5000 (data) + 24 (CRC) + 256 (filler) = 5280 rows.
%       Total Columns: 2 (because C=2).

    B = length(in);

    % --- Basic setup based on TS 38.212 Section 5.2.2 ---
    if bgn == 1
        Kcb = 8448; % Maximum code block size for BG1
        Kb = 22;
    else % bgn == 2
        Kcb = 3840; % Maximum code block size for BG2
        if B > 640, Kb = 10;
        elseif B > 560, Kb = 9;
        elseif B > 192, Kb = 8;
        else, Kb = 6;
        end
    end

    % --- Determine number of code blocks (C) ---
    if B <= Kcb
        % No segmentation needed
        L = 0; C = 1; Bd = B;
    else
        % Segmentation required
        L = 24; % CRC length for segmentation
        C = ceil(B / (Kcb - L));
        Bd = B + C * L; % Total bits after adding all CRCs
    end

    cbz = ceil(B / C);  % Bits per block before CRC attachment
    Kd  = ceil(Bd / C); % Bits per block after CRC attachment

    % --- Choose lifting size (Zc) ---
    % Find smallest Zc from the standard list such that the code can contain Kd bits.
    Zlist = [2:16 18:2:32 36:4:64 72:8:128 144:16:256 288:32:384];
    Zc = min(Zlist(Kb * Zlist >= Kd));
    
    % --- Calculate filler bits (F) ---
    if bgn == 1
        K = 22 * Zc; % Information bits per code block for BG1
    else % bgn == 2
        K = 10 * Zc; % Information bits per code block for BG2
    end
    F = K - Kd;  % Number of filler bits to add

    % --- Segmentation and CRC attachment ---
    if C == 1
        % If only one block, no internal CRC is added here
        cbCRC = in;
    else
        % Pad with zeros to make divisible by C, then reshape
        pad = [in; zeros(cbz * C - B, 1)];
        cb = reshape(pad, cbz, C);
        % Add 24-bit CRC to each code block column
        cbCRC = nrCRCEncode(cb, '24B'); % Assumes existence of a CRC function
    end

    % --- Add filler bits (-1) ---
    % Append F filler bits (represented by -1) to each column.
    cbs = [cbCRC; -1 * ones(F, C)];
end