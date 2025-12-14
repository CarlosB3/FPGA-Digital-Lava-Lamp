FPGA-Digital-Lava-Lamp
Designed a VHDL-based LED pattern generator on the Xilinx ZedBoard. Implemented a synchronous FSM with 4 modes (Sparkle, Sweep, Fade, Ember) driven by 8-bit PWM. Features include a Sine Wave LUT for smooth gamma-corrected fading, an LFSR for stochastic "Ember" effects, and input synchronizers to resolve metastability. Runs on 100 MHz logic. A pure VHDL hardware implementation of organic, stochastic LED pattern generation on the Xilinx ZedBoard.

📌 Overview This project demonstrates advanced digital logic design by creating a dynamic, multi-mode LED controller without the use of soft processors (MicroBlaze/ARM). It implements a synchronous Finite State Machine (FSM) to drive 8 onboard LEDs with fluid, organic behaviors.

Key engineering features include Pulse Width Modulation (PWM) for 256-level brightness control, Linear Feedback Shift Registers (LFSR) for pseudo-random number generation, and Gamma Correction via Look-Up Tables (LUTs) for natural lighting effects .

⚙️ Key Features

Pure Hardware Logic: Runs entirely on programmable logic (PL) at 100 MHz.

4 Visual Modes:

✨ Sparkle: High-speed random noise visualization.

☄️ Sweep: Deterministic "comet" trail with bidirectional control.

🌊 Fade: Smooth "breathing" effect using a pre-calculated Sine Wave LUT.

🔥 Ember: Stochastic state machine simulating a dying fire with independent LED decay.

Advanced Timing: Uses a synchronous "tick" strobe to derive 10ms animation frames from a 100 MHz clock.

Input Synchronization: Dual-rank flip-flop synchronizers on all switch inputs to prevent metastability and debounce mechanical noise.

🏗️ System Architecture The design follows a modular, hierarchical architecture for scalability:

top_lava_lamp.vhd: Top-level wrapper handling I/O buffers and input synchronization.

lava_core.vhd: Central FSM containing the mode logic, animation timers, and the Sine LUT.

lfsr_core.vhd: 16-bit Linear Feedback Shift Register using a primitive polynomial (x 16 +x 14 +x 13 +x 11 +1).

pwm_bank.vhd: Parameterized driver generating 8-bit PWM signals for the LED array.

🧪 Visual Modes Detail

Sparkle Mode Visualizes raw digital noise. The system takes snapshots of the 100 MHz LFSR at 10ms intervals, mapping random 8-bit values directly to LED brightness.

Fade Mode (Gamma Corrected) Standard linear fading (triangle wave) appears "jerky" to the human eye due to logarithmic brightness perception. This mode uses a Sine Wave Look-Up Table (LUT) to map linear time steps to a non-linear brightness curve, creating a smooth, organic pulse.

Ember Mode (Stochastic FSM) Simulates thermal decay. Each LED acts as an independent agent:

Ignition: If dark, the LED checks two uncorrelated bits from the LFSR. A bitwise AND operation creates a 25% probability of ignition.

Decay: If lit, the LED subtracts a fixed value every tick, simulating the linear cooling of a hot coal.

🚀 How to Run Prerequisites Xilinx Vivado (2020.x or later recommended).

Digilent ZedBoard (Zynq-7000).

Implementation Steps Create a new RTL Project in Vivado targeting the ZedBoard.

Import all .vhd source files located in /src.

Import the Constraints file (ZedPins.xdc) to map the LEDs and Switches.

Run Synthesis, Implementation, and Generate Bitstream.

Program the device via JTAG.

Simulation To simulate the visual patterns in ModelSim or Vivado Simulator without waiting for millions of clock cycles:

Open lava_core.vhd.

Change the constant TICK_MAX from 10,000,000 to 10.

Run the testbench tb_lava_core.vhd.

📂 File Structure ├── src/ │ ├── top_lava_lamp.vhd # Top Level Wrapper │ ├── lava_core.vhd # Main FSM & LUT Logic │ ├── lfsr_core.vhd # Random Number Generator │ ├── pwm_bank.vhd # LED Driver │ └── tb_lava_core.vhd # Testbench ├── constraints/ │ └── ZedPins.xdc # Pin Mappings └── README.md 📝 Design Challenges Metastability: Initial tests showed state skipping due to switch bounce. This was resolved by implementing a dual-rank synchronizer circuit on the inputs.

Perceptual Tuning: Replaced linear arithmetic with memory-based look-up tables (LUTs) to correct for the human eye's logarithmic sensitivity to light .

👤 Author Carlos Bautista

Computer Engineering MS Candidate, CSU Northridge
