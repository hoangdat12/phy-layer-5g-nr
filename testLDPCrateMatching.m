% test_rate_matching_compare.m
% So sánh kết quả giữa LDPCrateMatching (custom) và nrRateMatchLDPC (MATLAB)

clear; clc;

% --- Giả định 1 codeword LDPC sau khi mã hoá ---
Zc = 128;              % lifting size (common in 5G)
bg = 1;                % base graph 1 -> N = 66*Zc
N = 66 * Zc;           
ldpcEncodedBits = randi([0 1], N, 1, 'int8');  % 1 code block

% --- Thông số rate matching ---
E = 9000;              % Output length
rv = 0;                % redundancy version
modulation = '64QAM';  % modulation scheme
nlayers = 2;           % number of layers

% --- MATLAB reference (5G Toolbox) ---
outMatlab = nrRateMatchLDPC(ldpcEncodedBits, E, rv, modulation, nlayers);

% --- Your custom function ---
outCustom = LDPCrateMatching(ldpcEncodedBits, E, rv, modulation, nlayers);

% --- So sánh kết quả ---
sameLen = length(outMatlab) == length(outCustom);
nDiff = sum(outMatlab ~= outCustom);

fprintf('--- So sánh LDPC Rate Matching ---\n');
fprintf('Chiều dài MATLAB output : %d\n', length(outMatlab));
fprintf('Chiều dài Custom output : %d\n', length(outCustom));
fprintf('Kết quả chiều dài giống nhau: %d\n', sameLen);
fprintf('Số bit khác nhau: %d\n', nDiff);

if nDiff > 0
    fprintf('Tỷ lệ sai khác: %.4f%%\n', nDiff / length(outMatlab) * 100);
    diffIdx = find(outMatlab ~= outCustom);
    fprintf('Vị trí sai đầu tiên: %d\n', diffIdx(1));
else
    fprintf('✅ Kết quả trùng khớp hoàn toàn!\n');
end
