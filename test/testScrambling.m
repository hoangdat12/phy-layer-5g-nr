clc; clear; close all;

% Dữ liệu đầu vào (bit đã mã hoá LDPC)
inBits = randi([0 1], 100, 1);
cinit = 39827;  % ví dụ (giá trị seed)

% Kết quả từ hàm tự viết
out_custom = Scrambling(inBits, cinit);

disp('Kết quả scrambling (10 bit đầu):');
disp(out_custom(1:10).');
