# 🔢 Advanced 4-Bit ALU  
### **Booth Multiplier + Non-Restoring Divider + Adder/Subtractor**  
**Fully designed, simulated, and implemented on the Altera DE2-115 FPGA**

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
- FSM (Finite-State Machine) design  
- Control/Datapath separation  
- Signed arithmetic handling  
- FPGA implementation and waveform debugging  
- Booth algorithm hardware implementation  
- Non-restoring division using left-shift + add/sub cycles  

---

## 🧩 Architecture

### ✅ **1. Datapath Components**

** screenshot of the compenent**
The datapath is composed of:

- **4-bit Arithmetic Left Shift Register (Q)**  
- **4-bit Remainder Register (R)**  
- **4-bit Divisor Register (D)**  
- **Sign logic (magnitude extraction + final sign correction)**  
- **Adder/Subtractor**  
- **Multiplexers for selecting Add / Sub / Load / Clear**  
- **Down-counter for iteration control**  

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
Implements **signed Booth’s algorithm** using:

- Q and Q(-1) pair detection  
- Add/Sub/Shift logic  
- 4 cycles for a 4-bit operation  
- Handles negative operands via Booth’s encoding  

### 🔹 **Non-Restoring Division**
Implements signed division:

- Initialize registers (Q, R, D)  
- Shift-left → Add/Sub → Decision → Correct  
- Final correction for negative remainder  

### 🔹 **4-Bit Signed Addition/Subtraction**
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
│
├── simulation/ # Testbenches and waveforms
├── output_files/ # Quartus build outputs
├── incremental_db/ # Compilation database
└── db/ # Quartus internal files



---

## 🧪 Simulation & Testing

### ✅ **Waveform Verification**
All operations were verified in ModelSim/Quartus simulation:

- Multiplication cycles (Booth encoding visible)
- Division cycles (R add/sub + decision)
- Final correction applied correctly
- Signed edge cases tested:
  - `−8 × −3`
  - `5 × −3`
  - `−7 ÷ 3`
  - `6 ÷ −2`

### ✅ **FPGA Testing (DE2-115)**
The ALU was synthesized and implemented on the Altera DE2-115 board.  
Switches were used for inputs, and LEDs for result display.

---

## ✅ Example Test Cases

### 🔸 Booth Multiplication
| A (4-bit) | B (4-bit) | Expected |
|-----------|-----------|----------|
| 0101 (5)  | 0011 (3)  | 1111 1111 (15) |
| 1101 (-3) | 0011 (3)  | 1110 1111 (-9) |
| 1001 (-7) | 1010 (-6) | 0010 1010 (42) |

### 🔸 Non-Restoring Division
| Dividend | Divisor | Quotient | Remainder |
|----------|----------|----------|-----------|
| 0101 (5) | 0011 (3) | 0001     | 0010      |
| 1101 (-3)| 0011 (3) | 1111     | 0000      |
| 0110 (6) | 1110 (-2)| 1101     | 0000      |

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

