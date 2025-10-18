function out = LDPCencode(in, bg)
    % LDPCencode - Mã hóa LDPC theo 3GPP 38.212
    %
    % in : ma trận đầu vào (K x C) chứa bit thông tin (có thể có filler bit = -1)
    % bg : base graph (1 hoặc 2)
    % out: ma trận kết quả (N x C), mỗi cột là 1 codeword LDPC
    
    %-------------------%
    % 1. Xác định kích thước và tham số cơ bản
    %-------------------%
    [K, C] = size(in);
    if (bg == 1)
        numCol = 22;
        numRow = 66;
    else 
        numCol = 10;
        numRow = 50;
    end

    % Tính lifting factor Zc
    Zc = K / numCol;
    
    disp(Zc);

    % Danh sách giá trị Zc hợp lệ theo tiêu chuẩn 3GPP
    ZcVec = [2:16 18:2:32 36:4:64 72:8:128 144:16:256 288:32:384];
    if ~any(Zc == ZcVec)
        error("Invalid Zc value for LDPC encoding");
    end

    % Số bit đầu ra sau khi mã hóa (bao gồm parity bits)
    N = Zc * numRow;

    %-------------------%
    % 2. Xử lý filler bit (-1 -> 0)
    %-------------------%
    fillerPos = (in(:,1) == -1);
    in(fillerPos, :) = 0;

    %-------------------%
    % 3. Xác định tập lifting tương ứng với Zc
    %-------------------%
    ZcTable = { [2 4 8 16 32 64 128 256], ...
                [3 6 12 24 48 96 192 384], ...
                [5 10 20 40 80 160 320], ...
                [7 14 28 56 112 224], ...
                [9 18 36 72 144 288], ...
                [11 22 44 88 176 352], ...
                [13 26 52 104 208], ...
                [15 30 60 120 240] };
    for ZcIdx = 1:8
        if any(Zc == ZcTable{ZcIdx})
            break;
        end
    end

    %-------------------%
    % 4. Nạp base graph tương ứng từ file .mat
    %-------------------%
    persistent bgs
    if isempty(bgs)
        bgs = coder.load('./baseGraph.mat');
    end

    switch bg
        case 1
            switch ZcIdx
                case 1, V = bgs.BG1S1;
                case 2, V = bgs.BG1S2;
                case 3, V = bgs.BG1S3;
                case 4, V = bgs.BG1S4;
                case 5, V = bgs.BG1S5;
                case 6, V = bgs.BG1S6;
                case 7, V = bgs.BG1S7;
                otherwise, V = bgs.BG1S8;
            end
            Nplus2Zc = Zc * (66 + 2);
        otherwise % bg = 2
            switch ZcIdx
                case 1, V = bgs.BG2S1;
                case 2, V = bgs.BG2S2;
                case 3, V = bgs.BG2S3;
                case 4, V = bgs.BG2S4;
                case 5, V = bgs.BG2S5;
                case 6, V = bgs.BG2S6;
                case 7, V = bgs.BG2S7;
                otherwise, V = bgs.BG2S8;
            end
            Nplus2Zc = Zc * (50 + 2);
    end

    %-------------------%
    % 5. Xác định loại ma trận H cho từng BG và tập lifting
    %-------------------%
    Htype = {3, 3, 3, 3, 3, 3, 2, 3;
             4, 4, 4, 1, 4, 4, 4, 1};

    %-------------------%
    % 6. Tạo ma trận chỉ số dịch vòng P từ V
    %-------------------%
    P = zeros(size(V));
    for i = 1:size(V,1)
        for j = 1:size(V,2)
            if V(i,j) == -1
                P(i,j) = -1;
            else
                P(i,j) = mod(V(i,j), Zc);
            end
        end
    end

    % Xác định số cột thông tin (bằng tổng số cột trừ tổng số hàng của P)
    numInfoCols = size(P, 2) - size(P, 1);

    % Trích ra ma trận con P1 gồm các cột thông tin từ ma trận P
    P1 = P(:, 1:numInfoCols);


    % Khởi tạo ma trận chứa toàn bộ codewords
    codewords = zeros(Nplus2Zc, C);

    %-------------------%
    % 7. Mã hóa từng khối dữ liệu (cột)
    %-------------------%
    for r = 1:C
        % Lấy cột dữ liệu thứ r
        colData = in(:, r);

        % Chia thành các khối Zc bit
        infoVec = reshape(colData, Zc, []);

        % Mở rộng H1 để nhân với thông tin
        d = expandBaseMatrix(P1, infoVec);

        % Lấy 4 cột đầu để giải parity phần đầu
        d0 = d(:, 1:4);

        %-------------------%
        % 8. Giải hệ phương trình để tìm m1, m2, m3, m4
        %-------------------%
        switch Htype{bg, ZcIdx}
            case 1
                m1 = sum(d0, 2);
                m2 = d0(:,1) + m1([2:end 1]);
                m3 = d0(:,2) + m2;
                m4 = d0(:,3) + m1 + m3;
            case 2
                m1 = sum(d0, 2);
                shift = mod(105, Zc);
                if shift > 0
                    m1 = m1([(end-shift+1):end 1:(end-shift)]);
                end
                m2 = d0(:,1) + m1;
                m4 = d0(:,4) + m1;
                m3 = d0(:,3) + m4;
            case 3
                m1 = sum(d0, 2);
                m2 = d0(:,1) + m1([2:end 1]);
                m3 = d0(:,2) + m1 + m2;
                m4 = d0(:,3) + m3;
            otherwise % case 4
                m1 = sum(d0, 2);
                m1 = m1([end 1:(end-1)]);
                m2 = d0(:,1) + m1;
                m3 = d0(:,2) + m2;
                m4 = d0(:,4) + m1;
        end

        %-------------------%
        % 9. Tính các parity bit còn lại
        %-------------------%
        numCols_P1 = size(P1, 2);
        P3 = P(5:end, numCols_P1 + (1:4));
        expanded_P3 = expandBaseMatrix(P3, [m1, m2, m3, m4]);
        p = expanded_P3 + d(:, 5:end);

        %-------------------%
        % 10. Kết hợp tất cả thành codeword hoàn chỉnh
        %-------------------%
        combined_bits = [m1; m2; m3; m4; p(:)];
        final_codeword = mod(combined_bits, 2);
        codewords(:, r) = [in(:, r); final_codeword];
    end

    %-------------------%
    % 11. Phục hồi filler bit
    %-------------------%
    codewords(fillerPos,:) = -1;

    %-------------------%
    % 12. Puncture 2*Zc bit đầu (systematic bits)
    %-------------------%
    out = zeros(N, C, class(in));
    out(:,:) = cast(codewords(2*Zc+1:end,:), class(in));
end

%====================================================================%
% expandBaseMatrix - Mở rộng ma trận cơ sở (base matrix expansion)
%====================================================================%
function C = expandBaseMatrix(A, B)
    % A: ma trận base (chứa chỉ số dịch vòng hoặc -1)
    % B: ma trận đầu vào (Zc x số cột)
    % C: kết quả mở rộng (Zc x số hàng của A)

    C = zeros(size(B,1), size(A,1));

    for i = 1:size(A,1)
        for j = 1:size(A,2)
            if A(i,j) ~= -1
                shift = A(i,j);
                shiftedColumn = B([(shift+1):end, 1:shift], j);
                C(:, i) = C(:, i) + shiftedColumn;
            end
        end
    end
end
