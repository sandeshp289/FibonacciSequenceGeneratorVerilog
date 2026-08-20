`timescale 1 ns / 100 ps

/////////////////////////////////////////////////////////////////////////////////////
// File       : fibonacci.v
// Language   : Verilog
// Description: Fibonacci sequence generator
// Author     : Sandesh Prabhakar
// Created    : October 6, 2007
// Modified   : August 19, 2026
// Version    : 1.0
//
// Copyright (c) 2026 Sandesh Prabhakar
// All rights reserved
//////////////////////////////////////////////////////////////////////////////////////

module fibonacci(fib, done, clock, start);
output reg [31:0] fib; // Fibonacci number
output done;           // goes high when the last
                       // Fibonacci number is produced
input clock;           // positive-edge triggered clock
input start;           // active-high, synchronous reset

wire [31:0] sum_next_fib;
wire cout_next_fib;
reg [31:0] a_previous;
reg [31:0] b_current;
reg [31:0] b_current_store;
reg done_net;

//F(0) = 0
//F(1) = 1
//F(n) = F(n-1) + F(n-2) for n > 1
cla_adder32 CLA1 (sum_next_fib, cout_next_fib, a_previous, b_current, 1'b0);

assign done = done_net;

specify

    //specify one delay only. Used for all rise and fall transitions.
    specparam t_delay = 1; //1 ns delay
    (clock => done) = t_delay;
    (start => done) = t_delay;
    (clock => fib)  = t_delay;
    (start => fib)  = t_delay; 
    
endspecify

 always @(posedge clock)

   begin
       
      if(start)
      
          begin
              
          //F(0) = 0    
          a_previous <= 32'd0;
          b_current <= 32'd0;
          done_net <= 1'd0; //when start is reasserted, done is assigned to '0' and fibonacci sequence generation starts again.
          b_current_store <= 32'd0;
          
          end
         
       else if(cout_next_fib) //32-bit overflow in cla_adder32
       
          begin
                        
          b_current_store <= b_current + 32'd1;
          a_previous <= 32'd0;
          b_current <= 32'd0;
          done_net <= 1'd1; //detection of 32-bit overflow (cout_next_fib = 1) asserts 'done'.
          
          end    
          
       else
       
          begin
              
          //F(n-1), F(n-2)    
          a_previous <= b_current + 32'd1;
          b_current <= sum_next_fib;
          
          end
          
    end
 
      
    always @(done_net)
 
      begin
           if(done_net) //Last fibonacci number is produced, fibonacci sequence generation stops.
      
              begin
                
              assign fib = b_current_store; //fib stores the largest value that can be represented as a 32-bit unsigned value.
                          
              end  
            
            else  
                     
              assign  fib = a_previous; //fib stores the fibonacci number F(n).
      end
  
  endmodule         



//32-bit Carry Lookahead adder

module cla_adder32(sum, cout, a, b, cin);
output [31:0] sum; // a + b + cin
output cout;       // carry out of (a + b + cin)
input [31:0] a;    // first addend
input [31:0] b;    // second addend
input cin;         // carry in

wire _cout;

cla_adder16 CLA1 (sum[15:0], _cout , a[15:0], b[15:0], cin);
cla_adder16 CLA2 (sum[31:16], cout, a[31:16], b[31:16], _cout);

endmodule

//16-bit Carry Lookahead adder

module cla_adder16(sum, cout, a, b, cin);
output [15:0] sum; // a + b + cin
output cout;       // carry out of (a + b + cin)
input [15:0] a;    // first addend
input [15:0] b;    // second addend
input cin;         // carry in

wire [3:0] ggen;
wire [3:0] gprop;
wire [4:1] _cout;

cla_adder4 CLA1 (ggen[0], gprop[0], sum[3:0], a[3:0], b[3:0], cin);
cla_adder4 CLA2 (ggen[1], gprop[1], sum[7:4], a[7:4], b[7:4], _cout[1]);
cla_adder4 CLA3 (ggen[2], gprop[2], sum[11:8], a[11:8], b[11:8], _cout[2]);
cla_adder4 CLA4 (ggen[3], gprop[3], sum[15:12], a[15:12], b[15:12], _cout[3]);

carry_lookahead CL1 (_cout, cin, ggen, gprop);

assign cout = _cout[4];

endmodule


//4-bit carry lookahead adder slice

module cla_adder4(ggen, gprop, sum, a, b, cin);
output ggen;       // 4-bit group carry generate
output gprop;      // 4-bit group carry propagate
output [3:0] sum;  // a + b + cin
input [3:0] a;     // first addend
input [3:0] b;     // second addend
input cin;         // carry in

wire [3:0] p;
wire [3:0] g;
wire [4:1] cout;

specify
    (a *> ggen) = 3;
    (b *> ggen) = 3;
    (a *> gprop) = 2;
    (b *> gprop) = 2;
    (a *> sum) = 2;
    (b *> sum) = 2;
    (cin *> sum) = 2;
endspecify

//delay of 1 ns for each logic level (cummulative delay provided in specify block above) 
assign  p[0] = a[0] ^ b[0];
assign  p[1] = a[1] ^ b[1];
assign  p[2] = a[2] ^ b[2];
assign  p[3] = a[3] ^ b[3];
       
assign  g[0] = a[0] & b[0];
assign  g[1] = a[1] & b[1];
assign  g[2] = a[2] & b[2];
assign  g[3] = a[3] & b[3];       

carry_lookahead CL (cout, cin, g, p );

//delay of 2 ns for a 2-level SOP expression (cummulative delay provided in specify block above)
assign  ggen = g[3] | (g[2] & p[3]) | (g[1] & p[3] & p[2]) | (g[0] & p[3] & p[2] & p[1]);

//delay of 1 ns for each logic level (cummulative delay provided in specify block above)
assign  gprop = p[0] & p[1] & p[2] & p[3];

assign  sum[0] = p[0] ^ cin;
assign  sum[1] = p[1] ^ cout[1];
assign  sum[2] = p[2] ^ cout[2];
assign  sum[3] = p[3] ^ cout[3];
       
endmodule

//carry lookahead module

module carry_lookahead(cout, cin, g, p);
output [4:1] cout; // carry outs
input cin;         // carry in
input [3:0] g;     // carry generate functions
input [3:0] p;     // carry propagate functions

//computation of carry look ahead

specify
    (g *> cout) = 2;
    (p *> cout) = 2;
    (cin *> cout) = 2;
endspecify

//delay of 2 ns for a 2-level SOP expression (provided in specify block above)
assign  cout[1] = g[0] | (p[0] & cin);
assign  cout[2] = g[1] | ((p[1] & g[0]) | (p[1] & p[0] & cin));
assign  cout[3] = g[2] | ((p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin));
assign  cout[4] = g[3] | ((p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin));

endmodule
