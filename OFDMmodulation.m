function [waveform, info] = OFDMmodulation(carrier, grid)
% nrOFDMModulateSimple  Phiên bản đơn giản: IFFT + CP (không validate, không window)
%  [WAVEFORM,INFO] = nrOFDMModulateSimple(CARRIER, GRID)
%  - CARRIER: struct/object có fields:
%        .NSizeGrid (RB)
%        .SubcarrierSpacing (kHz) - tùy chọn, mặc định 15 kHz
%        .SymbolsPerSlot
%        .NSlot (tùy chọn)
%  - GRID: K x L x P (complex)
%
%  Trả về:
%   WAVEFORM : T x P  (time-domain samples)
%   INFO     : struct đơn giản chứa Nfft, SampleRate, CyclicPrefixLengths,...
%
%  LƯU Ý: đơn giản hóa mạnh — không theo đầy đủ TS 38.211.

    % --- lấy kích thước ---
    K = double(carrier.NSizeGrid) * 12;    % số subcarriers
    [Kgrid, L, P] = size(grid);
    if Kgrid ~= K
        % không validate to, chỉ cảnh báo nhẹ
        warning('K from carrier and grid mismatch. Using grid size.');
        K = Kgrid;
    end

    % --- tham số OFDM cơ bản ---
    Nfft = K;  % FFT points = số subcarriers (không zero-padding)
    if isfield(carrier,'SubcarrierSpacing')
        SCS = carrier.SubcarrierSpacing; % in kHz
    else
        SCS = 15; % default 15 kHz
    end
    SampleRate = Nfft * SCS * 1e3; % samples/sec (simple)

    % Chọn cyclic prefix length (đơn giản: 1/8 của Nfft)
    cpLen = floor(Nfft/8);
    cpLens = repmat(cpLen, L, 1);

    % Preallocate waveform: mỗi symbol dài (Nfft + cpLen)
    symLen = Nfft + cpLen;
    T = symLen * L;
    waveform = zeros(T, P);

    % Nếu grid là real double/single -> đảm bảo complex
    grid = complex(grid);

    % --- IFFT + thêm CP cho mỗi symbol và mỗi anten ---
    for p = 1:P
        outPos = 1;
        for l = 1:L
            % Lấy symbol miền tần số (col)
            F = grid(:, l, p);

            % Chuẩn bị cho IFFT: dịch tần số (ifftshift) rồi ifft
            tSym = ifft(ifftshift(F), Nfft);

            % Thêm cyclic prefix
            cp = tSym(end-cpLen+1:end);
            txSym = [cp; tSym];

            % Gán vào waveform
            waveform(outPos:outPos+symLen-1, p) = txSym;
            outPos = outPos + symLen;
        end
    end

    % --- Tạo cấu trúc info (đơn giản) ---
    info.Nfft = Nfft;
    info.SampleRate = SampleRate;
    info.CyclicPrefixLengths = cpLens;
    info.SymbolLengths = repmat(symLen, L, 1);
    info.Windowing = 0;
    info.SymbolPhases = zeros(L,1);
    info.SymbolsPerSlot = L;
    % giữ giá trị mặc định đơn giản cho slots
    info.SlotsPerSubframe = 1;
    info.SlotsPerFrame = 10;
    if isfield(carrier,'NSlot')
        info.InitialSlot = carrier.NSlot;
    end
end
