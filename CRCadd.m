function out = CRCadd(in_bits, type)
%
%   out = CRCadd(in_bits, type) computes the Cyclic Redundancy
%   Check (CRC) for the input bit stream 'in_bits' based on the CRC
%   standard specified by 'type'. The function then appends the calculated
%   CRC bits to the end of 'in_bits' to produce the output stream 'out'.
%
%   INPUTS:
%       in_bits: A row vector containing the original data bit stream.
%                Each element must be 0 or 1 (double or logical type).
%
%       type:    A character string (or char vector) specifying the CRC
%                standard to be used. Valid options include:
%                '24A', '24B', '24C', '16', '11', '6'.
%
%   OUTPUT:
%       out:     A row vector containing the original data bit stream
%                with the calculated CRC bits appended to the end.
%
%   EXAMPLE:
%       % --- Example of calculating CRC-16 for an 8-bit stream ---
%
%       % Input bit stream
%       input_bits = [1 0 1 1 0 1 0 0];
%
%       % Call the function to compute and append the CRC-16
%       output_bits = CRCAdd(input_bits, '16');
%
%
%       % Expected Result:
%       % output_bits will be a 1x24 vector, consisting of the 8 original
%       % bits followed by the 16 appended CRC bits.
%       % output_bits = [1 0 1 1 0 1 0 0 0 1 1 0 1 0 1 1 0 1 0 1 0 0 0 1]
%
%   REQUIREMENTS:
%       - MATLAB

% --- Start of Code ---

    % Generator Polynominals
    gCRC24A = [1 1 0 0 0 0 1 1 0 0 1 0 0 1 1 0 0 1 1 1 1 1 0 1 1];
    gCRC24B = [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 1];
    gCRC24C = [1 1 0 1 1 0 0  1 0 1 0 1 1 0 0 0 1 0 0 0 1 0 1 1 1];
    gCRC16  = [1 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 1];                
    gCRC11  = [1 1 1 0 0 0 1 0 0 0 0 1];                        
    gCRC6   = [1 1 0 0 0 0 1];        

    % CRC Type
    switch upper(type)
        case '24A'
            L = 24;
            polyValue = gCRC24A;
        case '24B'
            L = 24;
            polyValue = gCRC24B;
        case '24C'
            L = 24;
            polyValue = gCRC24C;
        case '16'
            L = 16;
            polyValue = gCRC16;
        case '11'
            L = 11;
            polyValue = gCRC11;
        case '6'
            L = 6;
            polyValue = gCRC6;
            
        otherwise
            error("Invalid CRC type. Choose from: '24A', '24B', '24C', '16', '11', or '6'.");
    end

    % Make sure input bit is row vector
    in_bits = logical(in_bits(:)');

    % Padding 
    K = length(in_bits);
    dataPadded = [in_bits, false(1, L)];

    % XOR
    for i = 1:K;
        if (dataPadded(i) == 1)
            dataPadded(i:i+L) = xor(dataPadded(i:i+L), polyValue);
        end
    end

    % Get CRC bits
    crcBits = double(dataPadded(end-L+1:end));

    % Combine to get data = in_bits + crcBits
    out     = double([in_bits crcBits]);
end