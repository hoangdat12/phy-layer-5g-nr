function sym = PDSCH(in_bits, modulation, nLayers, TPMI, nID, rnti, E, rv)
    %% Step 1: CRC addition
    in_bits_crc = CRCadd(in_bits, '24A');
    % Appends 24 CRC bits to the data block.
    %
    % Structure of 'in_bits_crc':
    %
    %   [ data_bit_1  ]
    %   [ data_bit_2  ]
    %   [    ...      ] <-- Original 'in_bits'
    %   [ data_bit_K  ]
    %   +-------------+
    %   [  crc_bit_1  ]
    %   [    ...      ] <-- 24 appended CRC bits
    %   [  crc_bit_24 ]

    %% Step 2: Select Base Graph
    if length(in_bits_crc) > 3824
        bg = 1; % Base Graph 1
    else
        bg = 2; % Base Graph 2
    end

    %% Step 3: LDPC segmentation
    codeBlocks = LDPCsegmentation(in_bits_crc, bg);
    %       Column 1                  Column 2
    %   /-------------\         /-------------\
    %  | 5000 data bits  |       | 5000 data bits  |  <-- Original data, split in half
    %  |   24 CRC bits   |       |   24 CRC bits   |  <-- Error-checking bits for each column
    %  | 256 filler bits |       | 256 filler bits |  <-- Padding bits (-1) to standardize size
    %   \-------------/         \-------------/
    %

    %% Step 4: LDPC encoding
    codewords = LDPCencode(codeBlocks, bg);
    % Encodes each column of 'codeBlocks' using LDPC.
    % This process calculates and adds a large block of parity bits for
    % error correction, then punctures (removes) the first 2*Zc bits
    % from the systematic part.
    %
    % Transformation for each column:
    %
    %  Input (from codeBlocks)            Output (a column in codewords)
    % /----------------------\
    % |      Data Bits       |
    % |       CRC Bits       |  --- LDPC ENCODING --->  [   Remaining Systematic Bits   ]
    % | Filler Bits (value -1) | (Adds Parity & Punctures) [        New Parity Bits        ]
    % \----------------------/                           (First 2*Zc bits were removed)
    %

    %% Step 5: Rate matching
    rateMatchedBits = LDPCrateMatching(codewords, E, rv, modulation, nLayers);
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

    % %% Step 6: Concentration (Bit Interleaving)
    % concentrationBits = LDPCconcentration(rateMatchedBits, E);
    % % Concentration  Concatenate rate-matched code blocks into one bit stream.
    % %
    % % Visual representation of the process:
    % %
    % %   Input ('rateMatchedBlocks' as a matrix)
    % %
    % %   Block 1       Block 2       Block 3
    % %   /-----\       /-----\       /-----\
    % %  | b1_1  |     | b2_1  |     | b3_1  |
    % %  | b1_2  |     | b2_2  |     | b3_2  |
    % %  |  ...  |     |  ...  |     |  ...  |
    % %   \-----/       \-----/       \-----/
    % %
    % %        |
    % %        V  CONCATENATION (Joining columns end-to-end)
    % %        |
    % %
    % %   Output ('d' as a single column vector)
    % %   /-----\
    % %  | b1_1  | <-- Start of Block 1
    % %  | b1_2  |
    % %  |  ...  |
    % %  +-------+
    % %  | b2_1  | <-- Start of Block 2
    % %  | b2_2  |
    % %  |  ...  |
    % %  +-------+
    % %  | b3_1  | <-- Start of Block 3
    % %  | b3_2  |
    % %  |  ...  |
    % %   \-----/
    % %
    % % If a target length 'E' is provided, the final stream is either
    % % truncated (cut) or padded (filled with a value) to match length E.

    %% Step 7: Scrambling
    cinit = rnti * 2^14 + nID;
    scrambledBits = Scrambling(concentrationBits, cinit);
    % ## VISUALIZATION OF THE PROCESS ##
    %
    %   Input Data ('inBits')
    %   [ 1 | 1 | 0 | 0 | 1 | 0 | 1 | ... ]
    %     |   |   |   |   |   |   |
    %    XOR XOR XOR XOR XOR XOR XOR  <-- Element-wise XOR operation
    %     |   |   |   |   |   |   |
    %   Scrambling Sequence ('seq', generated from 'cinit')
    %   [ 0 | 1 | 1 | 0 | 1 | 1 | 0 | ... ]
    %     |   |   |   |   |   |   |
    %     =   =   =   =   =   =   =
    %     |   |   |   |   |   |   |
    %   Output Data ('out')
    %   [ 1 | 0 | 1 | 0 | 0 | 1 | 1 | ... ]

    %% Step 8: Modulation
    modulatedBits = Modulation(scrambledBits, modulation);
    % ## VISUALIZATION OF THE PROCESS (Example: 16QAM) ##
    %
    % 1. Input bit stream is grouped into chunks of 4 bits (Qm=4).
    %
    %    Input 'in': [1,0,1,1, 0,1,1,0, ...]
    %                   |
    %                   V
    %    Group 1: [1,0,1,1]  ---> maps to Symbol 1
    %    Group 2: [0,1,1,0]  ---> maps to Symbol 2
    %    ...
    %
    % 2. Each group is used as a coordinate to find a point on the constellation.
    %
    %    For Group 1 = [1,0,1,1]:
    %      - First 2 bits [1,0] map to +3 on the I-axis (Real part).
    %      - Next 2 bits [1,1] map to +1 on the Q-axis (Imaginary part).
    %
    %                                     Q (Imaginary)
    %                                      ^
    %                                      |
    %                                   3 o| o o o
    %                                      |
    %                                   1 o| o o X  <-- Symbol 1 (+3 + 1i)
    %         <----------------------------+---------------------------> I (Real)
    %                                 -1 o | o o o
    %                                      |
    %                                 -3 o | o o o
    %                                      |
    % The final output 'out' is a column vector of these complex values
    % (e.g., [(+3+1i)/sqrt(10), ...]).

    %% Step 9: Layer mapping
    mappedBits = LayerMapping(modulatedBits, nLayers);
    % ## VISUALIZATION OF THE PROCESS (Example: 1 Codeword, 3 Layers) ##
    %
    % 1. The input is a single long stream of modulation symbols.
    %
    %    Input Codeword: [s1, s2, s3, s4, s5, s6, s7, s8, s9, ...]
    %
    % 2. The symbols are "dealt" cyclically to each layer.
    %
    %    s1 -> Layer 1
    %    s2 -> Layer 2
    %    s3 -> Layer 3
    %    s4 -> Layer 1 (wraps around)
    %    s5 -> Layer 2
    %    s6 -> Layer 3
    %    ...and so on.
    %
    % 3. The output 'out' is a matrix where each COLUMN is a layer,
    %    containing the symbols it was dealt.
    %
    %    Output 'out' matrix:
    %
    %      Layer 1   Layer 2   Layer 3
    %     /-------\   /-------\   /-------\
    %    |   s1    | |   s2    | |   s3    |
    %    |   s4    | |   s5    | |   s6    |
    %    |   s7    | |   s8    | |   s9    |
    %    |   ...   | |   ...   | |   ...   |
    %     \-------/   \-------/   \-------/

    %% Step 10: Precoding
    transformPrecode = false;
    if nLayers == 1
        nPorts = 2;   % 1 layer → 2 antenna ports (beamforming)
    elseif nLayers == 2
        nPorts = 4;   % 2 layer → 4 ports (2x4 MIMO)
    else
        nPorts = 4;
    end

    W = Precoding(nLayers, nPorts, TPMI, transformPrecode);
    precodedSymbols = W.' * mappedBits;

%     %% Step 10: Resource Element Mapping + OFDM Modulation

% % Giả sử bạn đã có các thông số:
% %   - precodedSymbols  : đầu ra của Precoding()
% %   - nPorts           : số port phát
% %   - nID              : scrambling ID
% %   - rnti             : RNTI
% %   - carrier          : cấu hình sóng mang (carrier config)
% %   - pdschConfig      : cấu hình PDSCH (pdsch config)

% %=====================
% % 1️⃣ Tạo resource grid
% %=====================
% grid = nrResourceGrid(carrier, nPorts);

% %=====================
% % 2️⃣ Sinh DM-RS cho PDSCH
% %=====================
% [dmrsSymbols, dmrsIndices] = nrPDSCHDMRS(carrier, pdschConfig);

% %=====================
% % 3️⃣ Lấy chỉ số PDSCH mapping (chỗ đặt symbol dữ liệu)
% %=====================
% [pdschIndices, pdschInfo] = nrPDSCHIndices(carrier, pdschConfig);

% %=====================
% % 4️⃣ Ánh xạ symbol dữ liệu vào grid
% %=====================
% grid(pdschIndices) = precodedSymbols;

% %=====================
% % 5️⃣ Ánh xạ DM-RS vào grid
% %=====================
% grid(dmrsIndices) = dmrsSymbols;

% %=====================
% % 6️⃣ OFDM Modulation (đưa về dạng sóng thời gian)
% %=====================
% [txWaveform, info] = nrOFDMModulate(carrier, grid);

% %=====================
% % 7️⃣ (Tùy chọn) Chuẩn hóa công suất
% %=====================
% txWaveform = txWaveform / max(abs(txWaveform));


    %% ✅ Output
    sym = mappedBits;
end
