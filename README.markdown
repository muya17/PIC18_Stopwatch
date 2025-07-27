# PIC18 Stopwatch

## Project Description
The **PIC18 Stopwatch** is a microcontroller-based stopwatch built on the PIC18F4520, designed to display time on a 4-digit 7-segment display in seconds and milliseconds (up to 99.99 seconds) using BCD encoding. It features two pushbuttons for control: start/stop (RB0) and reset (RB1). The system uses a 4 MHz external crystal oscillator for accurate 10ms interrupts via Timer0, high-priority interrupts for button inputs, and low-priority interrupts for timer updates, with multiplexed display output for efficient pin usage. Developed using MPLAB IDE v8.92 or higher and programmed with PICkit 3, this project demonstrates embedded systems programming, real-time interrupt handling, and hardware interfacing, tailored to showcase skills for applications requiring precise timing, such as financial technology systems.

## Features
- **4-Digit 7-Segment Display**: Displays time in SS.MM format (seconds and milliseconds).
- **Button Controls**: Start/stop on RB0, reset on RB1.
- **Accurate Timing**: 4 MHz external crystal with Timer0 (1:64 prescaler) for 10ms interrupts.
- **Interrupt-Driven Design**: High-priority interrupts for buttons, low-priority for timer updates.
- **Multiplexed Display**: Drives four digits efficiently using PORTC and PORTD.
- **BCD Encoding**: Time stored and displayed in binary-coded decimal for simplicity.

## Getting Started

### Prerequisites
- **Hardware**:
  - PIC18F4520 microcontroller
  - 4-digit 7-segment display (common cathode or anode, adjust code if needed)
  - Two pushbuttons (with 10kΩ pull-down resistors)
  - 4 MHz crystal oscillator
  - Two 22 pF ceramic capacitors (for crystal stability)
  - Breadboard, resistors (e.g., 220Ω for segments, 10kΩ for pull-downs), jumper wires
  - PICkit 3 for programming
- **Software**:
  - MPLAB IDE v8.92 or higher
  - MPASM assembler (included with MPLAB IDE)

### Installation
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/PIC18-Stopwatch.git
   ```
2. **Set Up MPLAB IDE Project**:
   - Open MPLAB IDE v8.92 or higher.
   - Create a new project: File > New Project > Standalone Project > Select Device: PIC18F4520 > Select Tool: PICkit 3 > Select Compiler: MPASM.
   - Add the source file (`stopwatch.asm`) from the `src/` directory to your project.
3. **Copy the Code**:
   - Open `stopwatch.asm` from the `src/` directory in MPLAB IDE.
   - Copy the entire code into the MPLAB IDE editor for your project’s .asm file.
4. **Simulate the Code**:
   - Select Debugger: Debugger > Select Tool > MPLAB SIM.
   - Build the project: Project > Build All.
   - Run the simulation: Debugger > Run.
   - Use MPLAB SIM’s stimulus feature to toggle RB0 (start/stop) and RB1 (reset) pins and observe PORTC/PORTD outputs to verify functionality.
5. **Hardware Connections**:
   - Connect 7-segment display segments (a-g, dp) to PORTD (RD0-RD7).
   - Connect digit select lines to PORTC (RC0-RC3 for digits 0-3).
   - Connect start/stop button to RB0 and reset button to RB1 (with 10kΩ pull-down resistors).
   - Connect a 4 MHz crystal to OSC1 (pin 13) and OSC2 (pin 14), with 22 pF capacitors from each pin to ground.
   - Connect VDD (pins 11, 32) to 5V and VSS (pins 12, 31) to ground.
6. **Program the Microcontroller**:
   - Select Programmer: Programmer > Select Programmer choke> PICkit 3.
   - Connect PICkit 3 to the PIC18F4520 (MCLR, VDD, VSS, PGD, PGC pins).
   - Build the project: Project > Build All.
   - Program the device: Programmer > Program.
7. **Operation**:
   - Power on the circuit (5V supply).
   - Press the start/stop button (RB0) to toggle timing.
   - Press the reset button (RB1) when stopped to reset to 00.00.
   - The display shows time in SS.MM format, updating every 10ms.

## Usage
- Power on the circuit; the display initializes to 00.00.
- Press the start/stop button (RB0) to start or pause the stopwatch.
- Press the reset button (RB1) when stopped to reset the time to 00.00.
- The stopwatch counts up to 99.99 seconds, rolling over to 00.00 upon overflow.

## File Structure
- `src/` - Source code files (`stopwatch.asm`)
- `docs/` - Documentation and schematics (optional, add if needed)
- `README.md` - This file
- `.gitignore` - Git ignore file

## Contributing
Contributions are welcome! Please fork the repository and submit a pull request with your changes.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments
- Built with MPLAB IDE v8.92 or higher and MPASM assembler.
- Designed to showcase embedded systems skills for real-time applications, such as those in financial technology.