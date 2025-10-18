% =========================
% ⚙️  Test LDPC Encode
% =========================

% 1️⃣ Chọn Base Graph
bgn = 1;  % 1 hoặc 2 (BG1 hoặc BG2)

% 2️⃣ Sinh dữ liệu đầu vào ngẫu nhiên
% Số bit đầu vào tùy theo base graph
if bgn == 1
    K = 8448;  % ví dụ cho BG1
else
    K = 3840;  % ví dụ cho BG2
end

in = randi([0 1], K, 1);  % vector bit ngẫu nhiên

% 3️⃣ Gọi hàm LDPC encoder của bạn
out_my = LDPCencode(in, bgn);

% 4️⃣ Gọi hàm MATLAB chuẩn
out_matlab = nrLDPCEncode(in, bgn);

% 5️⃣ So sánh kết quả
isEqual = isequal(out_my, out_matlab);

if isEqual
    disp("✅ Kết quả đúng: hai mã giống nhau hoàn toàn!");
else
    disp("❌ Kết quả KHÁC!");
    % Hiển thị vị trí khác nhau
    diff_idx = find(out_my ~= out_matlab);
    disp("Số bit khác nhau: " + numel(diff_idx));
    disp("Một vài vị trí khác nhau:");
    disp(diff_idx(1:min(10,end)));  % chỉ hiển thị 10 vị trí đầu
end
