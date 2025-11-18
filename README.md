# 🔢 Advanced 4-Bit ALU  
### **Booth Multiplier + Non-Restoring Divider + Adder/Subtractor**  
**Fully designed, simulated, and implemented on the Altera DE2-115 FPGA**
⭐ Why This Project Matters (For ASIC/FPGA Roles)
This project demonstrates industry-level RTL design skills directly relevant to:
Key strengths of this ALU:
✔️ Full RTL datapath + controller architecture
✔️ Synthesizable, multi-cycle arithmetic units
✔️ Hierarchical VHDL modules (adder, multiplier, divider, shift registers…)
✔️ FSM sequencing, one-hot encoding for control
✔️ Signed arithmetic handling (magnitude extraction, recombination)
✔️ Testbench-driven verification with ModelSim/Quartus
✔️ Hardware bring-up on DE2-115 FPGA
✔️ Waveform debugging for corner cases
✔️ Algorithmic hardware design (Booth & Non-restoring)
---

## 🚀 Overview
This project implements a **4-bit signed Arithmetic Logic Unit (ALU)** featuring:

✅ **Signed Booth Multiplication**  
✅ **Signed Non-Restoring Division**  
✅ **4-bit Signed Addition & Subtraction**  
✅ **Control/Datapath architecture**  
✅ **Cycle-accurate operation through finite-state machines**  
✅ **Hardware-tested on the Altera DE2-115 FPGA**  

This ALU was built as part of the digital design/FPGA development curriculum and demonstrates mastery in:

- VHDL RTL coding  
- ASM design  
- Control/Datapath separation  
- Signed arithmetic handling  
- FPGA implementation and waveform debugging  
- Booth algorithm hardware implementation  
- Non-restoring division using left-shift + add/sub cycles  

---

**🧩 Architecture**
✅ 1. Datapath Components
The ALU datapath is composed of:
2-to-1 Multiplexers — select the arithmetic operation based on control bits (00 → Addition, 01 → Subtraction, 10 → Multiplication, 11 → Division).
Full Adder/Subtractor — designed using a ripple-carry chain with a carry-in signal. The operation mode is determined by Cin:
Cin = 0 → Addition
Cin = 1 → Subtraction (performs two’s complement on operand B via B XOR Cin)
Booth Multiplier — implemented using the Arithmetic Booth’s Algorithm for signed multiplication. The design was developed by first studying the algorithm, building a graph representation, then creating the datapath and control logic. The algorithm performs arithmetic shifts based on the current and previous least-significant bits of the multiplier to handle signed numbers efficiently.
Non-Restoring Divider — chosen for its efficiency in signed division. It performs left shifts and makes decisions based on the sign of the remainder after each iteration. The algorithm was analyzed and translated into a structural datapath and control logic diagram before implementation.
Registers and Logic Units:
Q: 4-bit Arithmetic Left-Shift Register (Multiplier/Quotient)
R: 4-bit Remainder Register
D: 4-bit Divisor Register
Sign Logic: Handles magnitude extraction and final sign correction after unsigned operations.
Down Counter: Controls iteration cycles for multiplication/division.

<img width="996" height="504" alt="ALU_TopEntity" src="https://github.com/user-attachments/assets/65f13aad-0124-4e2c-822d-f67e43c26559" />




**⚙️ Design Methodology**
To demonstrate proficiency in both structural and behavioral VHDL:
Structural VHDL was used for the Booth multiplier and Adder/Subtractor, showcasing detailed understanding of hardware architecture and signal-level design.
Behavioral VHDL was used for the Non-Restoring Divider, since it required more complex sign handling. The algorithm itself works on unsigned magnitudes, so signs were separated, magnitudes processed, and results re-signed at the end.

### ✅ **2. Controller (FSM)**
A dedicated finite-state machine orchestrates:

- Load sequence  
- Magnitude conversion for signed numbers  
- Add/Sub cycles  
- Shift operations  
- Decision phases (R ≥ 0 or R < 0)  
- Final correction of quotient and remainder  

---

## ✳️ Features

### 🔹 **Booth Multiplication**


<img width="996" height="504" alt="Capture d’écran 2025-11-12 à 15 11 04" src="https://github.com/user-attachments/assets/a139c040-0cb5-4b7b-bb86-a56cfe47f525" />

implemented both data path and control logic in vhdl 

Implements **signed Booth’s algorithm** using:

- Q and Q(-1) pair detection ( current and previous bit ) 
- Add/Sub/Shift logic  
- 4 cycles for a 4-bit operation  
- Handles negative operands via Booth’s encoding  

### 🔹 **Non-Restoring Division**
<img width="997" height="503" alt="Capture d’écran 2025-11-12 à 15 14 32" src="https://github.com/user-attachments/assets/521ec23f-9a65-45ce-9095-5ff663e8a68b" />

Implements signed division:

- Initialize registers (Q, R, D)  
- Shift-left → Add/Sub → Decision → Correct  
- Final correction for negative remainder  

### 🔹 **4-Bit Signed Addition/Subtraction**

<img width="247" height="171" alt="Capture d’écran 2025-11-12 à 15 16 25" src="https://github.com/user-attachments/assets/59867543-6e70-4705-8ab0-caa727fb839f" />


- Ripple-carry design  
- Two’s complement handling  
- Zero, negative, overflow flags (optional extension)

---

## 📁 File Structure

ALU-Project/
│
├── ALU.bdf # Top-level block diagram
├── BoothCtrl_OneHot.vhd # Booth controller FSM
├── Booth_Datapath.vhd # Multiplication datapath
├── Arithmetic_Left_Shift_Q... # Q shift register
├── Non_Restoring_Controller.vhd # Division FSM
├── Non_Restoring_Datapath.vhd # Division datapath
├── Other smaller entities usedn in data path (other registers - multiplexer )
├── simulation/ # Testbenches and waveforms
├── output_files/ # Quartus build outputs
├── incremental_db/ # Compilation database
└── db/ # Quartus internal files



---

## 🧪 Simulation & Testing

### ✅ **Waveform Verification**
All operations were verified in ModelSim/Quartus simulation:

<img width="1440" height="587" alt="Capture d’écran 2025-11-12 à 15 25 49" src="https://github.com/user-attachments/assets/c0835190-ae84-423c-b557-0e13577472ca" />

As you can see :opsel=10 (multiplication)
               :OperandA=1011 (-5)
               :operandB=1101  (-3)
               :result =00001111 (15)

<img width="1440" height="587" alt="Capture d’écran 2025-11-12 à 15 29 57" src="https://github.com/user-attachments/assets/274f2b61-dca6-4b34-a1b9-eb1ae16f370d" />

As you can see :opsel=10 (multiplication)
               :OperandA=0101 (5)
               :operandB=1101  (-3)
               :result =11110001(-15)

<img width="1440" height="648" alt="Capture d’écran 2025-11-12 à 15 33 14" src="https://github.com/user-attachments/assets/c1d6dc54-236c-4bd1-8aeb-f3c8707c823c" />

As you can see :opsel=11 (division)
               :OperandA=0111 (7)
               :operandB=0010  (2)
               :result =00110001 (Q=0011=3 ,R=0001=1)

<img width="1440" height="648" alt="Capture d’écran 2025-11-12 à 15 40 52" src="https://github.com/user-attachments/assets/727b14ad-8912-4368-9dd6-d518cb3a2e70" />

As you can see :opsel=11 (division)
               :OperandA=1011 (-5)
               :operandB=1111  (-1)
               :result =01010000 (Q=0101=5,R=0000= 0 )

<img width="1440" height="648" alt="Capture d’écran 2025-11-12 à 15 48 40" src="https://github.com/user-attachments/assets/e66c6464-f758-4e97-bfa4-dbfe61e5e472" />

As you can see :opsel=00 (addition)
               :OperandA=1000 (-8)
               :operandB=1111  (-1)
               :result =000001111(Result is 111 but we have overflow=1 and carryout =1 )
               
<img width="1440" height="648" alt="Capture d’écran 2025-11-12 à 15 52 15" src="https://github.com/user-attachments/assets/8080fdfb-8377-469b-badb-b16899d9cda0" />

As you can see :opsel=01 (subtraction)
               :OperandA=0100 (4)
               :operandB=0001  (1)
               :result =000000011(Result is 1 but carryout =1 )

<img width="1440" height="585" alt="Capture d’écran 2025-11-12 à 16 07 14" src="https://github.com/user-attachments/assets/34f8a978-4075-4c0d-b335-f5812d2895cf" /> 

As you can see :opsel=00 (addition)
               :OperandA=1011 (-5)
               :operandB=0101  (5)
               :result =000000000(Result is 0 but Zeroout is 1  carryout is 1)


- Multiplication cycles (Booth encoding visible)
- Division cycles (R add/sub + decision)
- Final correction applied correctly
- Signed edge cases tested:
  - `−5 × −3`  (first picture)✅
  - `5 × −3`   (second picture)✅
  - `7 ÷ 2`    (third picture)✅
  - `-5 ÷ −1`(fourth picture)✅
  - -8-1     (fifth picture)
  - 4-1      (sixth picture)
  - -5+5     (seventh picture)

### ✅ **FPGA Testing (DE2-115)**
The ALU was synthesized and implemented on the Altera DE2-115 board.  
Switches were used for inputs, and LEDs for result display.

---



## 🛠️ Tools Used
- **Quartus II 13.0 / 18.1**
- **ModelSim / Quartus Waveform Simulator**
- **Altera DE2-115 FPGA Board**
- **VHDL RTL + Block Diagram Files (BDF)**

---

## 📌 What I Learned
This project developed strong FPGA & digital design skills, including:

- Implementing multi-cycle arithmetic hardware
- Designing FSM controllers
- Datapath/control separation
- Signed number handling in hardware
- Debugging FPGA timing & simulation waves
- Using Quartus block diagrams + VHDL modules together

These skills are directly applicable to:
- ✅ FPGA Development   
- ✅ Digital ASIC/CPU/GPU design  
- ✅ Hardware verification  
- ✅ Embedded systems  

---

## 📧 Contact
If you're a recruiter or engineer reviewing this project:  
Feel free to reach out — I love hardware, digital design, and FPGA development.

**GitHub:** https://github.com/hibaahan  
**Email:** hahan022@outlook.ca

---

