function out = layerMapping(in, nlayers)
% layerMappingSimple - Thực hiện layer mapping (theo 3GPP TS 38.211)
% Input:
%   in       : vector (1 codeword) hoặc cell {cw1, cw2}
%   nlayers  : số layer (1–8)
% Output:
%   out      : ma trận (M x nlayers), mỗi cột là 1 layer

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
