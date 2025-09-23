function c = PresudoGenerator(c_init, N)
    % PresudoGenerator  Sinh chuỗi giả ngẫu nhiên (Gold sequence) theo 3GPP
    %
    %   c_init : seed (thường được tính từ CellID, RNTI, subframe,...)
    %   N      : số bit đầu ra cần tạo
    
    %-----------------------------------------
    % 1. Khởi tạo 2 thanh ghi dịch dài 31 bits
    %    x1 luôn khởi tạo với '1' ở bit đầu
    %    x2 khởi tạo từ seed c_init
    %-----------------------------------------
    x1 = zeros(1, 31); 
    x2 = zeros(1, 31);
    x1(1) = 1;
    
    % c_init biểu diễn thành 31 bit nhị phân để nạp vào x2
    for i = 1:31
        x2(i) = bitget(c_init, i); % lấy bit thứ i của c_init
    end
    
    %-----------------------------------------
    % 2. Số bit phải sinh = N + 1600
    %    (theo chuẩn 3GPP: bỏ qua 1600 bit đầu tiên)
    %-----------------------------------------
    L = N + 1600;
    seq = zeros(L,1);
    
    %-----------------------------------------
    % 3. Vòng lặp sinh dãy
    %    - Output tại bước n = x1(1) XOR x2(1)
    %    - Cập nhật x1: new_x1 = x1(1) XOR x1(4)
    %    - Cập nhật x2: new_x2 = x2(1) XOR x2(2) XOR x2(3) XOR x2(4)
    %-----------------------------------------
    for n = 1:L
        % Chuỗi Gold = XOR của 2 LFSR
        seq(n) = xor(x1(1), x2(1));
        
        % Feedback tính theo đa thức quy định
        new_x1 = xor(x1(1), x1(4));                          
        new_x2 = xor(xor(x2(1), x2(2)), xor(x2(3), x2(4)));  
        
        % Dịch sang phải, thêm bit mới vào cuối
        x1 = [x1(2:end), new_x1];
        x2 = [x2(2:end), new_x2];
    end
    
    %-----------------------------------------
    % 4. Bỏ 1600 bit đầu → lấy N bit kế tiếp
    %-----------------------------------------
    c = logical(seq(1601:end));
end
