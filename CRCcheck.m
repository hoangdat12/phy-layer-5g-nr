function valid = CRCcheck(in_bits, type)
% CRCcheck - Verifies the integrity of a bit stream using a CRC check.
%
%   valid = CRCcheck(in_bits, type) performs a Cyclic Redundancy Check
%   (CRC) on a received codeword 'in_bits'. The function divides the
%   entire codeword by the generator polynomial specified by 'type'. The
%   codeword is considered valid if the remainder of this division is zero.
%
%   INPUTS:
%       in_bits: A vector representing the received codeword (message + CRC).
%                Each element should be 0 or 1.
%
%       type:    CRC type ('24A', '24B', '24C', '16', '11', '6').
%
%   OUTPUT:
%       valid:   Logical scalar.
%                - true  → CRC check passed (no errors)
%                - false → CRC check failed (errors detected)
%
%   Example:
%       data = [1 0 1 1 0 1 0 0 1 1 0 1];
%       codeword = CRCadd(data', '16'); % append CRC bits
%       is_valid = CRCcheck(codeword', '16')
%
%   See also: CRCadd

    % --- Define Generator Polynomials ---
    gCRC24A = [1 1 0 0 0 0 1 1 0 0 1 0 0 1 1 0 0 1 1 1 1 1 0 1 1];
    gCRC24B = [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 1];
    gCRC24C = [1 1 0 1 1 0 0 1 0 1 0 1 1 0 0 0 1 0 0 0 1 0 1 1 1];
    gCRC16  = [1 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 1];
    gCRC11  = [1 1 1 0 0 0 1 0 0 0 0 1];
    gCRC6   = [1 1 0 0 0 0 1];

    % --- Select CRC Polynomial ---
    switch upper(type)
        case '24A'
            L = 24; polyValue = gCRC24A;
        case '24B'
            L = 24; polyValue = gCRC24B;
        case '24C'
            L = 24; polyValue = gCRC24C;
        case '16'
            L = 16; polyValue = gCRC16;
        case '11'
            L = 11; polyValue = gCRC11;
        case '6'
            L = 6;  polyValue = gCRC6;
        otherwise
            error("Invalid CRC type. Choose from: '24A', '24B', '24C', '16', '11', or '6'.");
    end

    % --- Ensure row vector of logical bits ---
    in_bits = logical(in_bits(:)'); 
    polyValue = logical(polyValue(:)');

    % --- Polynomial Division (Modulo-2) ---
    data = in_bits;
    N = length(data);
    for i = 1:(N - L)
        if data(i)
            data(i:i+L) = xor(data(i:i+L), polyValue);
        end
    end

    % --- Check Remainder ---
    remainder = data(end - L + 1:end);
    valid = all(~remainder);
end
