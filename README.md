# ALS-benchmark-circuits

A Benchmark set of 28 circuits for ALS applications.

This benchmarks are a compilation of some benchmarks circuits included in AxBench, EPFL, AxLS sets and other sources. Each Benchmark is written in verilog with a source and a testbench. Both testbench and datasets are generated using "tb_generator.py".

## AxBench:

### 1. Brent-Kung-16b
**Description:** A 16 bit Brent Kung adder.
**Application/Type:** Arithmetic, Combinational.
**Inputs:** Two inputs of 16 bits.
**Outputs:** An output of 17 bits concatenating carry out bit and sum result as: {Carry out, Sum}.
**Tag:** BK_16b

### 2. Brent-Kung-32b
**Description:** A 32 bit Brent Kung adder.
**Application/Type:**  Arithmetic, Combinational.
**Inputs:** Two inputs of 32 bits.
**Outputs:** An output of 33 bits concatenating carry out bit and sum result as: {Carry out, Sum}.
**Tag:** BK_32b

### 3. Kogge-Stone-16b
**Description:** A 16 bit Kogge Stone adder.
**Application/Type:**  Arithmetic, Combinational.
**Inputs:** Two inputs of 16 bits.
**Outputs:** An output of 17 bits concatenating carry out bit and sum result as: {Carry out, Sum}.
**Tag:** KS_16b

### 4. Kogge-Stone-32b
**Description:** A 32 bit Kogge Stone adder.
**Application/Type:**  Arithmetic, Combinational.
**Inputs:** Two inputs of 32 bits.
**Outputs:** An output of 33 bits concatenating carry out bit and sum result as: {Carry out, Sum}.
**Tag:** KS_32b

### 5. Multiplier-16b
**Description:** A 16 bit Multiplier.
**Application/Type:**  Arithmetic, Combinational.
**Inputs:** Two inputs of 16 bits.
**Outputs:** An output of 32 bits.
**Tag:** mul_16b

### 6. Multiplier-32b
**Description:** A 32 bit Multiplier.
**Application/Type:**  Arithmetic, Combinational.
**Inputs:** Two inputs of 32 bits.
**Outputs:** An output of 64 bits.
**Tag:** mul_32b

### 7. Forward Kinematics
**Description:** Forward Kinematics for a 2-joint arm.
**Application/Type:**  Robotics, Combinational.
**Inputs:** Two inputs of 32 bits.
**Outputs:** Two outputs of 32 bits.
**Tag:** fwrdk2j

### 8. Inverse Kinematics
**Description:** Inverse Kinematics for a 2-joint arm.
**Application/Type:**  Robotics, Sequential (Since it uses a sequential division, benchmark was divided in combinational modules, for approximation purposes, and a sequential division+top module). **Partial approximation not tested yet**.
**Inputs:** Two inputs of 32 bits.
**Outputs:** Two output of 32 bits.
**Tag:** invk2j

### 9. Sobel
**Description:** Sobel edge detector.
**Application/Type:**  Machine Learning/Image Processing, Combinational
**Inputs:** 9 inputs of 9 bits.
**Outputs:** An output of 8 bits.
**Tag:** sobel

### 10. FIR
**Description:** Finite Impulse Response filter.
**Application/Type:**  Digital Signal Processing, Sequential (Divided in a combinational shift module for approximation and a sequential top module). **Partial Approximation not tested yet**.
**Inputs:** An inputs of 8 bits, clock and reset.
**Outputs:** An output of 10 bits.
**Tag:** fir

## EPFL Benchmarks:

### 11. Adder-128b
**Description:** A 128 bits Adder.
**Application/Type:**  Arithmetic, Combinational.
**Inputs:** Two inputs of 128 bits.
**Outputs:** An output of 128 bits, and a carry out bit.
**Tag:** adder_128b

### 12. Barrel Shifter
**Description:** 7 bits left Barrel Shifter for 128 bits inputs.
**Application/Type:**  Logical, Combinational.
**Inputs:** An input of 128 bits and shift count of 7 bits.
**Outputs:** An output of 128 bits.
**Tag:** barshift_128b

### 13. Division
**Description:** A 64 bits Divider.
**Application/Type:**  Arithmetic, Combinational.
**Inputs:** Two inputs of 64 bits (Dividend and Divisor respectively).
**Outputs:** Two outputs of 64 bits (Quotient and remainder respectively).
**Tag:** div_64b

### 14. Hypotenuse
**Description:** Calculates the hypotenuse of right triangle given two legs 128 bits.
**Application/Type:**  Arithmetic, Combinational.
**Inputs:** Two inputs of 128 bits.
**Outputs:** An output of 128 bits.
**Tag:** hyp_128b

### 15. Logarithm base 2
**Description:** Calculates base 2 logarithm of a 32 bits number.
**Application/Type:**  Arithmetic, Combinational
**Inputs:** An input of 32bits.
**Outputs:** An output of 32 bits.
**Tag:** log2_32b

### 16. Square Root
**Description:** Calculates the square root of a 128 bits number.
**Application/Type:**  Arithmetic, Combinational
**Inputs:** And input of 128 bits.
**Outputs:** An output of 64 bits.
**Tag:** sqrt_128b

### 17. Square Power
**Description:** Calculates the square (power of 2) of a 64 bits number.
**Application/Type:**  Arithmetic, Combinational
**Inputs:** And input of 64 bits.
**Outputs:** An output of 128 bits.
**Tag:** square_64b

### 18. Max
**Description:** Returns the maximum of four given numbers of 128 bits.
**Application/Type:**  Arithmetic, Combinational
**Inputs:** 4 input of 128 bits.
**Outputs:** An output of 128 bits, and 2 bits indicating argmax (which of input has the greatest value).
**Tag:** max_128b

### 19. Multiplier
**Description:** A 64 bits Multiplier.
**Application/Type:**  Arithmetic, Combinational
**Inputs:** Two input of 64 bits.
**Outputs:** An output of 128 bits.
**Tag:** mul_64b

### 20. Sine
**Description:** Calculates the sine of a 24 bits number.
**Application/Type:**  Arithmetic, Combinational
**Inputs:** An input of 24 bits.
**Outputs:** An output of 25 bits.
**Tag:** sin_24b

### 21. Voter
**Description:** Returns the majority of values in the inputs (1 if most of the inputs are 1, 0 otherwise).
**Application/Type:**  Control, Combinational
**Inputs:** 1 input of 1001 bits.
**Outputs:** A single bit output.
**Tag:** voter

### 22. Integer to Float
**Description:** Convert  11 bit integers to a 4M+3E bits float.
**Application/Type:**  Control, Combinational
**Inputs:** An input of 11 bits.
**Outputs:** An output of 4 bits for Mantissa + 3 bits for the Exponent.
**Tag:** int2float

### 23. Decoder
**Description:** A 8 bits decoder.
**Application/Type:**  Arithmetic, Combinational
**Inputs:** An input of 8 bits.
**Outputs:** Two outputs of 128 bits.
**Tag:** dec

## Benchmarks from AxLS tool

### 24. Carry Look-Ahead Adder
**Description:** A 16 bits carry look-ahead adder.
**Application/Type:**  Arithmetic, Combinational
**Inputs:** Two inputs of 16 bits, and a carry in bit.
**Outputs:** An output of 17 bits concatenating carry out bit and sum result as: {Carry out, Sum}.
**Tag:** CLA_16b

### 25. Carry Skip Adder
**Description:** A 16 bits carry skip adder.
**Application/Type:**  Arithmetic, Combinational
**Inputs:** Two inputs of 16 bits.
**Outputs:** An output of 17 bits concatenating carry out bit and sum result as: {Carry out, Sum}.
**Tag:** CSkipA_16b

### 26. Ladner Fischer Adder
**Description:** A 16 bits Ladner Fischer adder.
**Application/Type:**  Arithmetic, Combinational
**Inputs:** Two inputs of 16 bits.
**Outputs:** An output of 17 bits concatenating carry out bit and sum result as: {Carry out, Sum}.
**Tag:** LFA_16b

### 27. Ripple Carry Adder
**Description:** A 4 bits carry look-ahead adder.
**Application/Type:**  Arithmetic, Combinational
**Inputs:** Two inputs of 4 bits, and a carry in bit.
**Outputs:** An output of 5 bits concatenating carry out bit and sum result as: {Carry out, Sum}.
**Tag:** RCA_16b

### 28. Wallace-Tree Multiplier
**Description:** A 8 bits Wallace Tree multiplier.
**Application/Type:**  Arithmetic, Combinational
**Inputs:** Two inputs of 8 bits.
**Outputs:** An output of 16 bits.
**Tag:** WT_8b

## Benchmarks from other sources

### 29. Decision Tree
**Description:** A trained Decision Tree circuit.
**Application/Type:**  ML, Combinational
**Inputs:** 30 inputs of 10 bits.
**Outputs:** An output of 5 bits.
**Tag:** DTree

### 30. Random Forest
**Description:** A trained Random Forest circuit.
**Application/Type:**  ML, Combinational
**Inputs:** 52 inputs of 10 bits.
**Outputs:** An output of 5 bits.
**Tag:** RForest

