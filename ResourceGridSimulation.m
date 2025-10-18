function grid = ResourceGridSimulation(carrier, P)
%nrResourceGrid Simplified version - create empty NR resource grid
%
%   GRID = ResourceGridSimulation(CARRIER, P)
%   CARRIER: carrier configuration object with fields:
%       - NSizeGrid: number of resource blocks (1...275)
%       - SymbolsPerSlot: number of OFDM symbols per slot
%   P: number of antennas
%
%   GRID is a complex K-by-L-by-P array of zeros, where:
%       K = 12 * NSizeGrid
%       L = SymbolsPerSlot
%
%   Example:
%       carrier.NSizeGrid = 106;
%       carrier.SymbolsPerSlot = 14;
%       grid = ResourceGridSimulation(carrier, 8);
%       size(grid)

    if nargin < 2
        P = 1; % default 1 antenna
    end

    K = double(carrier.NSizeGrid) * 12;   % Number of subcarriers
    L = carrier.SymbolsPerSlot;           % Number of OFDM symbols
    grid = complex(zeros(K, L, P));       % Create complex grid

end
