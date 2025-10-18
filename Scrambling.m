function out = Scrambling(inBits, cinit)
% Scrambling for transport block (3GPP 38.211 Section 5.2.1)
%
% This function randomizes the input data by performing an element-wise
% XOR operation with a pseudo-random sequence (Gold sequence). This helps
% break up long runs of identical bits (e.g., all 0s or all 1s), which
% improves signal quality and receiver performance.
%
% The 'cinit' seed ensures that both the transmitter and receiver can
% generate the exact same pseudo-random sequence for scrambling and
% descrambling.
%
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

    % Length of the sequence to generate
    N = length(inBits);

    % Generate the pseudo-random Gold sequence
    seq = PresudoGenerator(cinit, N);

    % Scrambling = XOR between coded bits and the Gold sequence
    out = xor(inBits(:), seq(:));
end