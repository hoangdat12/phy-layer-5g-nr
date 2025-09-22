## Simulation of Rate Matching for LDPC Codes in 5G NR

This project simulates two key steps in the **5G NR physical layer (PHY) processing chain**:

# Processing Steps

1. **CRC (Cyclic Redundancy Check) Calculation** for error detection.
    - A cyclic redundancy check (CRC) is added to the transport block for error detection.
    - The CRC polynomial type (e.g. 24A or 24B) is chosen depending on system configuration.
2.  **Segmentation into Code Blocks**
    - If the transport block is larger than the maximum input size of the LDPC encoder, the block is divided into multiple code blocks (CBs).
    - Each code block also has its own CRC appended to allow detection of errors in each segment.
3. **LDPC Encoding** 
    - Each code block is encoded using Low-Density Parity-Check (LDPC) coding.
    - The appropriate base graph (Base Graph 1 or Base Graph 2) is selected.
    - Base graph expansion (lifting) is performed using the parameter Zc
4. **Rate Matching for LDPC-encoded code blocks** to fit the allocated physical resources.
    - The encoded bits are punctured, repeated, or otherwise adjusted to match a required output length.
    - The selection of redundancy version (RV), modulation order (Qm), number of layers, etc., is considered.
.
---


## 1. CRC (Cyclic Redundancy Check)

### Purpose
CRC is a technique used for **error detection** during data transmission.  
A CRC sequence is computed from the original data and appended before transmission.  
The receiver recomputes the CRC and compares results to detect errors.

### Supported CRC Types
- **CRC-24A**  
- **CRC-24B**  
- **CRC-24C**  
- **CRC-16**  
- **CRC-11**  
- **CRC-6**

### Implementation (`CRCadd.m`)

**Function prototype:**
```matlab
out = CRCadd(in_bits, type)
```

**Inputs:**
- `in_bits`: Row vector of bits (0 or 1).  
- `type`: CRC standard (`'24A'`, `'24B'`, `'24C'`, `'16'`, `'11'`, `'6'`).  

**Outputs:**
- `out`: Input bit stream with the CRC bits appended.  

**Algorithm:**
1. Selects the generator polynomial for the chosen CRC type.  
2. Pads the input data with zeros of CRC length.  
3. Performs polynomial division using XOR.  
4. Extracts the remainder (CRC bits).  
5. Appends CRC bits to the input sequence.  

**Example:**
```matlab
% Input bit stream
input_bits = [1 0 1 1 0 1 0 0];

% Compute CRC-16
output_bits = CRCadd(input_bits, '16');

% output_bits = original 8 bits + 16 CRC bits
```

---
# LDPC Encoding (3GPP TS 38.212)

## Purpose
LDPC encoding is the core channel coding step defined in **3GPP TS 38.212**.  
It takes segmented code blocks and adds **parity bits**, creating a longer, more robust codeword.  
This process provides the **Forward Error Correction (FEC)** capability of **5G NR**.

The encoder is **systematic**, meaning:
- The original information bits are placed at the beginning of the output codeword.
- The calculated parity bits follow.

---

## Key Parameters

- **`in`**: Input matrix of size `K × C`, where each column is a code block from the segmentation stage.  
- **`bg`**: Base Graph index (`1` or `2`).  
- **`K`**: Size of each input code block (number of rows in `in`).  
- **`C`**: Number of code blocks (columns in `in`).  
- **`Zc`**: Lifting size, derived from `K` and `bg`. Determines the expansion factor of the base graph.  
- **`V`**: Lifting Value Matrix selected from `baseGraph.mat` based on `bg` and `Zc`. Defines the circular shifts for constructing the parity-check matrix.  
- **`N`**: Encoded codeword length per block.  
  - `N = Zc × 66` for **BG1**  
  - `N = Zc × 50` for **BG2**  
- **`out`**: Output matrix of size `N × C`, where each column is an encoded LDPC codeword.  

---

## 🛠 Implementation: `LDPCencode.m`

### Inputs
- **`in`**: `K × C` matrix of code blocks (output of **LDPCsegmentation**).  
  - Filler bits must be represented as `-1`.  
- **`bg`**: Base Graph index (`1` or `2`).  

### Outputs
- **`out`**: `N × C` matrix, where each column is a fully encoded LDPC codeword.  

### Dependencies
- **`baseGraph.mat`** must exist in the same directory.  
- Contains predefined **lifting value matrices** for all base graph and lifting set combinations (`BG1S1`, `BG2S3`, etc.).  

---

## Algorithm Steps

1. **Handle Filler Bits**  
   - Replace all filler bits (`-1`) with `0`.  

2. **Calculate Lifting Size (`Zc`)**  
   - For **BG1**: `Zc = K / 22`  
   - For **BG2**: `Zc = K / 10`  
   - Ensure `Zc` is valid and standard-compliant.  

3. **Select Parity-Check Matrix**  
   - Identify the correct **lifting set index**.  
   - Load the corresponding lifting matrix `V` from **baseGraph.mat**.  

4. **Perform Encoding**  
   - For each code block (column of `in`), compute parity bits using the systematic encoding algorithm.  

5. **Form Final Codeword**  
   - Append parity bits to the original information bits (with fillers removed).  
   - Repeat for all `C` blocks.  

---

## Example

```matlab
% --- Example: Segmentation + LDPC Encoding ---

% 1. Transport block size
B = 10000;       % > Kcb for BG1
transport_block = randi([0 1], 1, B);
bg = 1;

% 2. Perform segmentation (output must yield a valid K)
K = 5632;        % Valid size for BG1 (K = 256 * 22)
C = 2;           % Number of code blocks
input_blocks = randi([0 1], K, C);

% Simulate filler bits in first block
input_blocks(1:1200, 1) = -1;

% 3. Perform LDPC encoding
encoded_blocks = LDPCencode(input_blocks, bg);

% 4. Display output size
disp('Size of encoded blocks:');
disp(size(encoded_blocks));

% --- Expected Output ---
% Zc = K / 22 = 5632 / 22 = 256
% N  = Zc * 66 = 256 * 66 = 16896
% Size(encoded_blocks) = [16896, 2]
```
---

# LDPC Rate Matching (3GPP TS 38.212)

## Purpose
**Rate Matching** is a critical process in the 5G NR physical layer, defined in **3GPP TS 38.212, Section 5.4.2**.  
Its primary function is to adapt the fixed-size output of the LDPC encoder (the codeword) to the exact number of bits that can be transmitted over the physical channel in a given time slot.

It involves two main operations:
- **Puncturing** → Remove bits if the codeword is larger than the available capacity.  
- **Repetition** → Repeat bits if the codeword is smaller.  

The process uses a **circular buffer** and is controlled by the **Redundancy Version (RV)**, which enables the transmitter to send different sets of parity bits in successive retransmissions (**HARQ**).

---

## Key Parameters

- **`in`**: `N × C` matrix of LDPC-encoded codewords.  
- **`outlen (E)`**: Target number of output bits after rate matching.  
- **`rv`**: Redundancy Version (`0, 1, 2, 3`), determines the starting point `k0`.  
- **`modulation`**: Modulation scheme (`QPSK`, `16QAM`, `64QAM`, etc.), defines bits per symbol `Qm`.  
- **`nlayers`**: Number of MIMO layers.  
- **`N`**: Length of each input codeword.  
- **`C`**: Number of code blocks.  
- **`Ncb`**: Circular buffer size (limited by `Nref`).  
- **`k0`**: Starting offset for circular buffer readout, derived from `rv`.  
- **`out`**: Final output vector of length `outlen`.  

---

## Implementation: `LDPCrateMatching.m`

### Inputs
- **`in`**: `N × C` LDPC-encoded bits.  
- **`outlen`**: Target output length `E`.  
- **`rv`**: Redundancy Version (`0–3`).  
- **`modulation`**: Modulation scheme (e.g., `'64QAM'`).  
- **`nlayers`**: Number of MIMO layers.  
- **`Nref`** *(optional)*: Limited soft buffer size.  

### Outputs
- **`out`**: Column vector of length `outlen` (rate-matched codeword).  

---

## Algorithm Steps

1. **Parameter Derivation**  
   - Determine `bg`, `Zc`, and modulation order `Qm`.  
   - Compute circular buffer size `Ncb = min(N, Nref)` (if provided).  

2. **Calculate Starting Position (`k0`)**  
   - Use `rv` to look up standard-defined values.  
   - Compute `k0`, the starting index in the circular buffer.  

3. **Bit Distribution**  
   - Distribute the target length `E` among `C` code blocks.  
   - Some blocks provide `E_floor` bits, others `E_ceil`.  

4. **Bit Selection & Interleaving (per block)**  
   - Select bits from the circular buffer:  
     `output(j) = in(mod(k0 + j, Ncb))`  
   - Skip filler bits (`-1`).  
   - Perform interleaving by reshaping into `Qm` columns, transposing, then reading column-wise.  

5. **Concatenation**  
   - Combine outputs from all code blocks → final vector `out`.  

---

## Example

```matlab
% --- Parameters ---
E = 9000;          % Target output length
rv = 0;            % Redundancy version
modScheme = '64QAM';
numLayers = 2;

% --- LDPC Encoding (Simplified Example) ---
% In practice, these come from an LDPC encoder
N = 8448;          % Example codeword length (BG1, Zc=128)
C = 2;             % Number of code blocks
ldpcEncodedBits = randi([0 1], N, C);  % Two blocks

% --- Perform Rate Matching ---
rateMatchedBits = LDPCrateMatching(ldpcEncodedBits, E, rv, ...
                                   modScheme, numLayers);

% --- Display Results ---
disp(['Length of rate-matched output: ', num2str(length(rateMatchedBits))]);

% --- Expected ---
% Length of rate-matched output: 9000
```
---

## Example Usage (MATLAB)

```matlab
% --- 1. Define Parameters ---
tbs          = 3824;        % Transport block size (bits)
modulation   = '16QAM';     % Modulation scheme
nlayers      = 1;           % Number of layers
targetCodeRate = 490/1024;  % Target code rate
rv           = 0;           % Redundancy Version

% Calculate the desired output length
outlen = round(tbs / targetCodeRate);

% --- 2. Generate Input Matrix 'in' ---
tb = randi([0 1], tbs, 1);             % Random transport block
cbs = nrCodeBlockSegmentLDPC(tb, 1);   % LDPC segmentation
encodedBlocks = nrLDPCEncode(cbs, 1);  % LDPC encoding
in = cell2mat(encodedBlocks');         % Concatenate into matrix 'in'

% --- 3. Call Rate Matching Function ---
ratematched_output = rateMatchingLDPC(in, outlen, rv, modulation, nlayers);

% --- 4. Verify Results ---
fprintf('Input ''in'' size: %d x %d\n', size(in, 1), size(in, 2));
fprintf('Output size: %d\n', length(ratematched_output));
fprintf('Desired output length: %d\n', outlen);

if length(ratematched_output) == outlen
    fprintf('=> SUCCESS: Output length matches.\n');
else
    fprintf('=> FAILED: Output length mismatch.\n');
end
```
