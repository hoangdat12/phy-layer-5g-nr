function out = Scrambling(inBits, cinit)
% Scrambling for transport block (3GPP 38.211 Section 5.2.1)
%
% inBits : vector (0/1) các bit đã mã hoá (LDPC/Polar output)
% cinit  : seed để sinh Gold sequence (tuỳ kênh: PDSCH, PDCCH, PBCH, …)
% out    : vector sau khi scrambling

    % Độ dài dãy cần sinh
    N = length(inBits);

    % Sinh Gold sequence
    seq = PRBS(cinit, N);

    % Scrambling = XOR giữa coded bits và Gold sequence
    out = xor(inBits(:), seq(:));
end
