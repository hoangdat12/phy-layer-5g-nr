function out = Modulation(in, type)
% modulation  Map scrambled bits -> modulation symbols (3GPP TS 38.211)
%
% This function converts a stream of bits into a stream of complex-valued
% modulation symbols. It works in two stages:
% 1. Grouping: The input bitstream is chunked into groups of Qm bits,
%    where Qm depends on the modulation type (e.g., Qm=4 for 16QAM).
% 2. Mapping: Each group of bits is mapped to a specific point on the
%    complex plane (the constellation diagram).
%
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

    % Ensure input is a column vector
    in = in(:);

    % Determine number of bits per symbol (Qm)
    switch upper(type)
        case {'PI/2-BPSK','BPSK'}
            Qm = 1;   % 1 bit per symbol
        case 'QPSK'
            Qm = 2;   % 2 bits per symbol
        case '16QAM'
            Qm = 4;   % 4 bits per symbol
        case '64QAM'
            Qm = 6;   % 6 bits per symbol
        case '256QAM'
            Qm = 8;   % 8 bits per symbol
        otherwise
            error('Unknown modulation type: %s', type);
    end
    
    % Check: input length must be divisible by Qm
    if mod(length(in), Qm) ~= 0
        error('Input length must be a multiple of Qm (%d).', Qm);
    end

    % Group input bits into rows of Qm bits
    % Example: QPSK -> [b0 b1], 16QAM -> [b0 b1 b2 b3], etc.
    in = reshape(in, Qm, []).';   
    numSymbols = size(in,1);
    out = zeros(numSymbols,1);  % initialize output vector

    % Mapping according to 3GPP standard
    switch upper(type)
        case 'BPSK'
            % BPSK: 1 bit → ±1
            % Mapping: 0 → +1, 1 → -1
            out = 1 - 2*in;  

        case 'QPSK'
            % QPSK: 2 bits → (I,Q)
            % I = b0 (0→+1, 1→-1), Q = b1 (0→+1, 1→-1)
            % Normalize by sqrt(2) so average power = 1
            I = 1 - 2*in(:,1);
            Q = 1 - 2*in(:,2);
            out = (I + 1i*Q) / sqrt(2);

        case '16QAM'
            % 16QAM: 4 bits = [b0 b1 | b2 b3]
            % Gray mapping levels:
            % 00 -> -3, 01 -> -1, 11 -> +1, 10 -> +3
            M = [-3 -1 3 1]; 
            I_levels = M(bin2dec(num2str(in(:,1:2)))+1);
            Q_levels = M(bin2dec(num2str(in(:,3:4)))+1);
            % Normalize by sqrt(10) so average power = 1
            out = (I_levels + 1i*Q_levels) / sqrt(10);

        case '64QAM'
            % 64QAM: 6 bits = [b0 b1 b2 | b3 b4 b5]
            % Gray mapping levels for 3 bits -> 8 amplitudes
            % 000->-7, 001->-5, 011->-3, 010->-1,
            % 110->+1, 111->+3, 101->+5, 100->+7
            M = [-7 -5 -3 -1 7 5 3 1];
            I_levels = M(bin2dec(num2str(in(:,1:3)))+1);
            Q_levels = M(bin2dec(num2str(in(:,4:6)))+1);
            % Normalize by sqrt(42)
            out = (I_levels + 1i*Q_levels) / sqrt(42);

        case '256QAM'
            % 256QAM: 8 bits = [b0 b1 b2 b3 | b4 b5 b6 b7]
            % Gray mapping levels for 4 bits -> 16 amplitudes
            % Example sequence: -15, -13, -11, -9, -1, -3, -5, -7,
            %                   +15, +13, +11, +9, +1, +3, +5, +7
            M = [-15 -13 -11 -9 -1 -3 -5 -7 15 13 11 9 1 3 5 7];
            I_levels = M(bin2dec(num2str(in(:,1:4)))+1);
            Q_levels = M(bin2dec(num2str(in(:,5:8)))+1);
            % Normalize by sqrt(170)
            out = (I_levels + 1i*Q_levels) / sqrt(170);
    end
end

%% Soft buffer size (Nref, Ncb) va puncturing