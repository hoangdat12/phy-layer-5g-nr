function out = CRCadd(in_data, type)
% CRCadd - Adds a Cyclic Redundancy Check (CRC) to input data.
% This version supports matrix inputs, processing each column individually.
%
%% EXAMPLE
%
% --- Single Column Input ---
%
% If your input data is a single column vector representing the bits of ASCII 'A':
%   in_data = [0; 1; 0; 0; 0; 0; 0; 1]; 
%
% And you call the function with CRC type '16':
%   out = CRCadd(in_data, '16');
%
% The output 'out' will be the original 8 bits followed by the 16 calculated CRC bits.
% The CRC-16-CCITT-FALSE for 'A' (0x41) is 0x34D1.
% 0x34D1 in binary is [0 0 1 1  0 1 0 0  1 1 0 1  0 0 0 1]
%
% Expected 'out' (24x1 vector):
%   out = [ 0;  <-- Original Data (8 bits)
%           1;
%           0;
%           0;
%           0;
%           0;
%           0;
%           1;
%           0;  <-- Calculated CRC (16 bits)
%           0;
%           1;
%           1;
%           0;
%           1;
%           0;
%           0;
%           1;
%           1;
%           0;
%           1;
%           0;
%           0;
%           0;
%           1 ];

    % --- 1. Get CRC Polynomial Information ---
    % Select the CRC polynomial and length based on the 'type' input.
    switch upper(type)
        case '24A'
            L = 24;
            polyValue = [1 1 0 0 0 0 1 1 0 0 1 0 0 1 1 0 0 1 1 1 1 1 0 1 1];
        case '24B'
            L = 24;
            polyValue = [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 1];
        case '16'
            L = 16;
            polyValue = [1 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 1];
        otherwise
            error("Unsupported CRC type.");
    end
    
    % --- 2. Prepare for Matrix Processing ---
    % Get the size of the input data matrix.
    [num_rows, num_cols] = size(in_data);
    
    % Initialize the output matrix. Each column will be L bits longer.
    out = zeros(num_rows + L, num_cols);
    
    % Loop to calculate CRC for each column independently.
    for c = 1:num_cols
        % Get the data for the current column.
        in_bits = logical(in_data(:, c));
        K = length(in_bits);
        
        % Pad the end of the current column with L zero-bits.
        dataPadded = [in_bits; false(L, 1)];
        
        % --- 3. Perform CRC Calculation ---
        % Ensure the polynomial is a column vector for XOR operation.
        polyValue_col = logical(polyValue(:)); 
        
        % This loop performs the polynomial division using XOR operations.
        for i = 1:K
            if dataPadded(i) == 1
                % If the current bit is 1, XOR with the polynomial.
                dataPadded(i:i+L) = xor(dataPadded(i:i+L), polyValue_col);
            end
        end
        
        % The remainder of the division is the CRC bits.
        crcBits = double(dataPadded(end-L+1:end));
        
        % --- 4. Append CRC to Original Data ---
        % Attach the calculated CRC bits to the end of the original data column.
        out(:, c) = [double(in_data(:, c)); crcBits];
    end
end