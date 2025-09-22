function out = LDPCencode(in, bg)
    % Find Zc
    [K, C] = size(in);
    if (bg == 1)
        numCol = 22;
        numRow = 66;
    else 
        numCol = 10;
        numRow = 50;
    end

    % Lifting factor
    Zc = K / numCol;
    % Validate Lifting Factor
    ZcVec = [2:16 18:2:32 36:4:64 72:8:128 144:16:256 288:32:384];
    if ~any(Zc==ZcVec)
        error("Invalid");
    end;

    % Number of output bit
    N = Zc*ncwnodes;

    % Replace filler bit
    % Find -1 in the first code block
    fillerPos = (in(:,1) == -1);
    % Replace -1 with 0
    in(fillerPos, :) = 0;

    % Encode for all code block
    persistent bgs
    if isempty(bgs)
        bgs = coder.load('./baseGraph.mat');
    end

    % Get lifting set number
    ZcTable = {[2  4  8  16  32  64 128 256],... % Set 1
             [3  6 12  24  48  96 192 384],... % Set 2
             [5 10 20  40  80 160 320],...     % Set 3
             [7 14 28  56 112 224],...         % Set 4
             [9 18 36  72 144 288],...         % Set 5
             [11 22 44  88 176 352],...        % Set 6
             [13 26 52 104 208],...            % Set 7
             [15 30 60 120 240]};              % Set 8
    for ZcIdx = 1:8    % LDPC lifting size set index
        if any(Zc==ZcTable{ZcIdx})
            break;
        end
    end

    switch bgn
        case 1
            switch ZcIdx
                case 1
                    V = bgs.BG1S1;
                case 2
                    V = bgs.BG1S2;
                case 3
                    V = bgs.BG1S3;
                case 4
                    V = bgs.BG1S4;
                case 5
                    V = bgs.BG1S5;
                case 6
                    V = bgs.BG1S6;
                case 7
                    V = bgs.BG1S7;
                otherwise % 8
                    V = bgs.BG1S8;
            end
            Nplus2Zc = Zc*(66+2);
        otherwise % bgn = 2
            switch ZcIdx
                case 1
                    V = bgs.BG2S1;
                case 2
                    V = bgs.BG2S2;
                case 3
                    V = bgs.BG2S3;
                case 4
                    V = bgs.BG2S4;
                case 5
                    V = bgs.BG2S5;
                case 6
                    V = bgs.BG2S6;
                case 7
                    V = bgs.BG2S7;
                otherwise % 8
                    V = bgs.BG2S8;
            end
            Nplus2Zc = Zc*(50+2);
    end
end