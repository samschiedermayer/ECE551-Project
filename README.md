# ECE551-Project
This project is systemverilog code to run on a cyclone iv fpga to control a robot through an obstacle course.

## How to build the code

Prerequisites for building the code include questasim installation.

Run the command `make` to build the code.

## How to run automated testing of the code

Prerequisites for building the code include *questasim* installation.

Run the command `make test` to run the automated testing suite.

A message of *"Yahoo! All tests passed :)"* indicates a successful test run.

## How to synthesize the code to hardware

Prerequisites for synthesis include *design_vision* installation.

Run the command `make synth` to synthesize the systemverilog into hardware.

Outputs can be found in the `synthesis/` directory.
