function out = LayerMapping(in, nlayers)
% layerMapping - Maps modulation symbols from codewords to transmission layers.
%
% This function acts like a card dealer. It takes one or two "decks" of
% symbols (codewords) and deals them one-by-one across the available
% transmission layers.
%
% If there are two codewords, the total number of layers is split between
% them first, and then the dealing process happens for each codeword group.
%
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

    % --- Bước 1: Chuẩn hóa input ---
    if ~iscell(in)
        cws = {in};        % Nếu chỉ có 1 codeword, cho vào cell
    else
        cws = in;          % Nếu có 2 codeword, giữ nguyên
    end

    ncw = numel(cws);      % Số lượng codeword (1 hoặc 2)

    % --- Bước 2: Tính số layer cho từng codeword ---
    % Ví dụ: nlayers = 7, ncw = 2  →  nLayers = [3,4]
    nLayers = floor((nlayers + (0:ncw-1)) / ncw);

    % --- Bước 3: Tính số symbol trên mỗi layer ---
    M = length(cws{1}) / nLayers(1);

    % --- Bước 4: Khởi tạo ma trận đầu ra ---
    out = zeros(M, nlayers);

    % --- Bước 5: Mapping cho codeword 1 ---
    for i = 1:nLayers(1)
        out(:, i) = cws{1}(i:nLayers(1):end);
    end

    % --- Bước 6: Nếu có codeword 2 ---
    if ncw == 2
        for j = 1:nLayers(2)
            out(:, nLayers(1) + j) = cws{2}(j:nLayers(2):end);
        end
    end
end
