function valid = CRCcheck(in_bits, type)
%CRCCHECK Verifies the integrity of a bit stream using a CRC check.
%
%   valid = CRCCHECK(in_bits, type) performs a Cyclic Redundancy Check
%   (CRC) on a received codeword 'in_bits'. The function divides the
%   entire codeword by the generator polynomial specified by 'type'. The
%   codeword is considered valid if the remainder of this division is zero.
%
%   INPUTS:
%       in_bits: A row vector representing the received codeword, which
%                should include the original message bits followed by the
%                CRC bits. Each element must be 0 or 1.
%
%       type:    A character string specifying the CRC standard to be used for
%                the check. Valid options include:
%                '24A', '24B', '24C', '16', '11', '6'.
%
%   OUTPUT:
%       valid:   A logical scalar value.
%                - Returns 'true' if the CRC check passes (remainder is zero),
%                  indicating no errors were detected.
%                - Returns 'false' if the CRC check fails (remainder is non-zero),
%                  indicating that the message is likely corrupted.
%
%   EXAMPLE:
%       % Assume a function CRCadd(data, type) exists to generate a valid CRC
%
%       % 1. Define original data and generate a valid codeword with CRC-16
%       original_data = [1 0 1 1 0 1 0 0 1 1 0 1];
%       % codeword_ok = CRCadd(original_data, '16'); % This would be the valid codeword
%       codeword_ok = [1 0 1 1 0 1 0 0 1 1 0 1 0 1 0 0 1 0 1 1 1 1 1 1 1 1 0 1]; % Pre-calculated
%
%       % 2. Create a corrupted codeword by flipping one bit
%       codeword_bad = codeword_ok;
%       codeword_bad(5) = ~codeword_bad(5); % Introduce an error
%
%       % 3. Check both codewords
%       is_valid_ok  = CRCcheck(codeword_ok, '16');
%       is_valid_bad = CRCcheck(codeword_bad, '16');
%
%       % 4. Display results
%       fprintf('Check on correct codeword returned: %s\n', string(is_valid_ok));
%       fprintf('Check on corrupted codeword returned: %s\n', string(is_valid_bad));
%
%       % Expected Output:
%       % Check on correct codeword returned: true
%       % Check on corrupted codeword returned: false
%
%   See also CRCadd.

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

    % XOR
    for i = 1:length(in_bits) - L
        if (in_bits(i) == 1)
            in_bits(i, i + L) = xor(in_bits(i: i + L), polyValue);
        end
    end

    % If comparedBit = [0, 0, ... , 0, 0] 
    comparedBit = in_bits(end-L+1:end);
    valid = all(comparedBit == 0);
end