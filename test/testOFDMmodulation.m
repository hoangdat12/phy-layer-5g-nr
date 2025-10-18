% Test nrResourceGrid và nrOFDMModulate

% B1: Cấu hình carrier
carrier = nrCarrierConfig;
carrier.NSizeGrid = 52;      % Số RB (ví dụ 10 MHz)
carrier.SubcarrierSpacing = 30;  % kHz
carrier.CyclicPrefix = 'normal';

% B2: Tạo resource grid cho 2 anten
nTxAnt = 2;
grid = ResourceGridSimulation(carrier, nTxAnt);

% B3: Gán symbol giả lập (QPSK hoặc ngẫu nhiên) vào grid
%    Kích thước grid là: [K subcarrier x L OFDM symbol x P antenna]
%    => ta gán giá trị phức ngẫu nhiên để dễ quan sát
grid(:,:,:) = (randn(size(grid)) + 1i*randn(size(grid)))/sqrt(2);

% B4: Thực hiện OFDM Modulation
[waveform, info] = OFDMmodulation(carrier, grid);

% B5: Hiển thị thông tin và kết quả
disp('Thông tin OFDM:');
disp(info);

figure;
plot(real(waveform(:,1)));
title('Dạng sóng OFDM - anten 1 (phần thực)');
xlabel('Sample');
ylabel('Amplitude');
grid on;

figure;
plot(abs(waveform(:,1)));
title('Biên độ OFDM symbol - anten 1');
xlabel('Sample');
ylabel('|Amplitude|');
grid on;
