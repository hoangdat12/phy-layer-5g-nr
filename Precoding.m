function W = Precoding(nlayers,nports,TPMI,varargin)

    persistent matrixTables;
    if isempty(matrixTables)
        matrixTables = initializeMatrixTables();
    end

    if nargin>3
        transformPrecode = varargin{1};
    else
        transformPrecode = false;
    end

    if nlayers==1
        if nports==1
            allW = 1;
        elseif nports==2
            allW = matrixTables.W12;
        else
            if transformPrecode
                allW = matrixTables.W14_tp;
            else
                allW = matrixTables.W14_notp;
            end
        end

    elseif nlayers==2
        if nports==2
            allW = matrixTables.W22;
        else
            allW = matrixTables.W24;
        end

    elseif nlayers==3
        allW = matrixTables.W34;

    else
        allW = matrixTables.W44;
    end

    maxTPMI = (size(allW,1) / nlayers) - 1;
    W = allW(TPMI*nlayers + (1:nlayers),:);

end

function matrixTables = initializeMatrixTables()
    matrixTables.W12 = initializeW12();
    matrixTables.W14_tp = initializeW14_tp();
    matrixTables.W14_notp = initializeW14_notp();
    matrixTables.W22 = initializeW22();
    matrixTables.W24 = initializeW24();
    matrixTables.W34 = initializeW34();
    matrixTables.W44 = initializeW44();
end

function W12 = initializeW12()
    W12 = [1   0;
           0   1;
           1   1;
           1  -1;
           1   1j;
           1  -1j];
    W12 = W12 / sqrt(2);
end

function W14_tp = initializeW14_tp()
    W14_tp = [1   0   0   0;
              0   1   0   0;
              0   0   1   0;
              0   0   0   1;
              1   0   1   0;
              1   0  -1   0;
              1   0  1j   0;
              1   0 -1j   0;
              0   1   0   1;
              0   1   0  -1;
              0   1   0  1j;
              0   1   0 -1j;
              1   1   1  -1;
              1   1  1j  1j;
              1   1  -1   1;
              1   1 -1j -1j;
              1  1j   1  1j;
              1  1j  1j   1;
              1  1j  -1 -1j;
              1  1j -1j  -1;
              1  -1   1   1;
              1  -1  1j -1j;
              1  -1  -1  -1;
              1  -1 -1j  1j;
              1 -1j   1 -1j;
              1 -1j  1j  -1;
              1 -1j  -1  1j;
              1 -1j -1j   1];
    W14_tp = W14_tp / 2;
end

function W14_notp = initializeW14_notp()
    W14_notp = [1   0   0   0;
                0   1   0   0;
                0   0   1   0;
                0   0   0   1;
                1   0   1   0;
                1   0  -1   0;
                1   0  1j   0;
                1   0 -1j   0;
                0   1   0   1;
                0   1   0  -1;
                0   1   0  1j;
                0   1   0 -1j;
                1   1   1   1;
                1   1  1j  1j;
                1   1  -1  -1;
                1   1 -1j -1j;
                1  1j   1  1j;
                1  1j  1j  -1;
                1  1j  -1 -1j;
                1  1j -1j   1;
                1  -1   1  -1;
                1  -1  1j -1j;
                1  -1  -1   1;
                1  -1 -1j  1j;
                1 -1j   1 -1j;
                1 -1j  1j   1;
                1 -1j  -1  1j;
                1 -1j -1j  -1];
    W14_notp = W14_notp / 2;
end

function W22 = initializeW22()
    W22 = [1   0;
           0   1;
           1   1;
           1  -1;
           1   1j;
           1  -1j];
    W22(1:2,:) = W22(1:2,:) / sqrt(2);
    W22(3:end,:) = W22(3:end,:) / 2;
end

function W24 = initializeW24()
    W24 = [1   0   0   0;
           0   1   0   0;
           1   0   0   0;
           0   0   1   0;
           1   0   0   0;
           0   0   0   1;
           0   1   0   0;
           0   0   1   0;
           0   1   0   0;
           0   0   0   1;
           0   0   1   0;
           0   0   0   1;
           1   0   1   0;
           0   1   0 -1j;
           1   0   1   0;
           0   1   0  1j;
           1   0 -1j   0;
           0   1   0   1;
           1   0 -1j   0;
           0   1   0  -1;
           1   0  -1   0;
           0   1   0 -1j;
           1   0  -1   0;
           0   1   0  1j;
           1   0  1j   0;
           0   1   0   1;
           1   0  1j   0;
           0   1   0  -1;
           1   1   1   1;
           1   1  -1  -1;
           1   1  1j  1j;
           1   1 -1j -1j;
           1  1j   1  1j;
           1  1j  -1 -1j;
           1  1j  1j  -1;
           1  1j -1j   1;
           1  -1   1  -1;
           1  -1  -1   1;
           1  -1  1j -1j;
           1  -1 -1j  1j;
           1 -1j   1 -1j;
           1 -1j  -1  1j;
           1 -1j  1j   1;
           1 -1j -1j  -1];
    W24(1:28,:) = W24(1:28,:) / 2;
    W24(29:end,:) = W24(29:end,:) / (2*sqrt(2));
end

function W34 = initializeW34()
    W34 = [1   0   0   0;
           0   1   0   0;
           0   0   1   0;
           1   0   1   0;
           0   1   0   0;
           0   0   0   1;
           1   0  -1   0;
           0   1   0   0;
           0   0   0   1;
           1   1   1   1;
           1  -1   1  -1;
           1   1  -1  -1;
           1   1  1j  1j;
           1  -1  1j -1j;
           1   1 -1j -1j;
           1  -1   1  -1;
           1   1   1   1;
           1  -1  -1   1;
           1  -1  1j -1j;
           1   1  1j  1j;
           1  -1 -1j  1j];
    W34(1:9,:) = W34(1:9,:) / 2;
    W34(10:end,:) = W34(10:end,:) / (2*sqrt(3));
end

function W44 = initializeW44()
    W44 = [1   0   0   0;
           0   1   0   0;
           0   0   1   0;
           0   0   0   1;
           1   0   1   0;
           1   0  -1   0;
           0   1   0   1;
           0   1   0  -1;
           1   0  1j   0;
           1   0 -1j   0;
           0   1   0  1j;
           0   1   0 -1j;
           1   1   1   1;
           1  -1   1  -1;
           1   1  -1  -1;
           1  -1  -1   1;
           1   1  1j  1j;
           1  -1  1j -1j;
           1   1 -1j -1j;
           1  -1 -1j  1j];
    W44(1:4,:) = W44(1:4,:) / 2;
    W44(5:12,:) = W44(5:12,:) / (2*sqrt(2));
    W44(13:end,:) = W44(13:end,:) / 4;
end
