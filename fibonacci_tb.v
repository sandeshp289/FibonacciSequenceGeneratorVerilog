`timescale 1 ns / 100 ps

/////////////////////////////////////////////////////////////////////////////////////
// File       : fibonacci_tb.v
// Language   : Verilog
// Description: Test bench for Fibonacci sequence generator
// Author     : Sandesh Prabhakar
// Created    : October 6, 2007
// Modified   : August 19, 2026
// Version    : 1.0
//
// Copyright (c) 2026 Sandesh Prabhakar
// All rights reserved
//////////////////////////////////////////////////////////////////////////////////////

module test_fibonacci;
    
wire [31:0] fib; // Fibonacci number
wire done;       // goes high when the last
                 // Fibonacci number is produced
reg clock;       // positive-edge triggered clock
reg start;       // active-high, synchronous reset

fibonacci dut(fib, done, clock, start);

initial begin    // clock generator
   clock = 0;
   forever #10 clock = !clock;
end
  
initial	begin    // test stimulus
   start = 0;
   #20 start = 1;   //start asserted, fibonacci sequence generation begins
   #20 start = 0;   //start deasserted
   #1200 start = 1; //start reasserted to begin fibonacci sequence generation again
   #20 start = 0;   //start deasserted
end

endmodule 
