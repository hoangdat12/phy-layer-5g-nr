% Test script so sánh layerMapping tự viết với nrLayerMap

clc; clear;

% --- Tạo dữ liệu test ---
in = (1:24).';        % Codeword đầu vào (vector cột)
nlayers = 4;          % Số lượng layer

% --- Hàm tự viết ---
out_custom = layerMapping(in, nlayers);

% --- Hàm chuẩn 5G NR ---
out_nr = nrLayerMap(in, nlayers);

% --- In kết quả ---
disp('--- Input ---');
disp(in.');

disp('--- Output (custom) ---');
disp(out_custom);

disp('--- Output (nrLayerMap) ---');
disp(out_nr);

% --- So sánh ---
if isequal(out_custom, out_nr)
    disp('✅ Kết quả trùng khớp với nrLayerMap!');
else
    disp('❌ KHÔNG trùng khớp với nrLayerMap!');
    disp('Hiệu số:');
    disp(out_custom - out_nr);
end
