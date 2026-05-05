# Traffic-Light-Controller-FPGA

## Project Overview

This project implements a Traffic Light Controller with a pedestrian request system and countdown timer on the DE10-Lite FPGA using Verilog.

The system controls a standard traffic light sequence using Green, Yellow, and Red phases. It also allows a pedestrian request to be made using a push button input. When a pedestrian request is detected, the system safely stores the request and activates the pedestrian crossing during the appropriate Red phase.

## Features

- Automatic Green, Yellow, and Red traffic light sequencing
- 5-second Green phase, 2-second Yellow phase, and 5-second Red phase
- Real-time countdown displayed on HEX0
- Pedestrian request input using KEY1
- Request queuing behavior for safe pedestrian crossing
- Extended 9-second Red phase during pedestrian crossing
- Blinking pedestrian walk signal using LEDR3
- Full reset functionality

## Hardware Used

- DE10-Lite FPGA Board
- Verilog HDL
- Quartus Prime
- LEDR0-LEDR2 for traffic light outputs
- LEDR3 for pedestrian walk indicator
- HEX0 for countdown display
- KEY1 for pedestrian request input

## Design Description

The controller operates as a finite state machine that cycles through the normal Green to Yellow to Red traffic light sequence.

A pedestrian request can be made at any time by pressing KEY1. If the request is made during the Green or Yellow phase, the request is stored and activates during the next Red phase. If the request is made during the Red phase, the crossing request is deferred to the following Red phase.

During the pedestrian phase, the Red light is extended to 9 seconds, LEDR3 blinks at 1 Hz, and HEX0 displays a countdown timer. After the pedestrian phase is complete, the request is cleared and the controller returns to the normal traffic light cycle.

## Project Files

- `TrafficController.v` - Main Verilog module for the traffic light controller
- `DE10_LITE_Golden_Top.v` - Top-level DE10-Lite FPGA module
- `TrafficController.qpf` - Quartus project file
- `TrafficController.qsf` - Quartus settings file
- `EECS_3201_F_Project_Report.pdf` - Final project report
- `simulation/` - Simulation-related files

## Testable Functionality

The project was designed to test the following components:

- Finite state machine state transitions
- Accurate Green, Yellow, and Red timing
- Seven-segment display countdown output
- Pedestrian request detection
- Queued pedestrian crossing behavior
- Extended Red phase timing
- Blinking pedestrian walk indicator
- Reset behavior

## Reference

This project was inspired by a YouTube tutorial on traffic light controller FSM design, which helped with understanding FSM structure and timing logic before adapting the concepts to this Verilog implementation.

YouTube: "Counters (Part 7) - Traffic Light Controller FSM (.vhd)"  
https://www.youtube.com/watch?v=S8UvMZuBy8c
