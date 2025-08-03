`timescale 1ns / 1ps

module tb;
    
    	
	reg clk;
	reg rst;
	reg [6:0] addr;
	reg [7:0] data_write_master;
    	reg [7:0] data_write_slave;
	reg enable;
	reg rw;

	
	wire [7:0] data_read_master;
    	wire [7:0] data_read_slave;
	wire ready;
    
    	
	wire i2c_sda;
	wire i2c_scl;
    
    	wire data_read;
  
  	ma a(
  		.clk(clk), 
		.rst(rst), 
		.addr(addr), 
		.data_write_master(data_write_master), 
		.enable(enable), 
		.rw(rw), 
		.data_read_master(data_read_master), 
		.ready(ready), 
		.i2c_sda(i2c_sda), 
		.i2c_scl(i2c_scl)
  	);
    	sl b (
        	.sda(i2c_sda), 
        	.scl(i2c_scl),
        	.data_write_slave(data_write_slave),
        	.data_read_slave(data_read_slave)
    	);
  
  	initial begin
    	

		clk = 0;
		rst = 1;

		#100; 

		rst = 0;		
		addr = 7'b1010101; 
		data_write_master = 8'b10101010; 
		data_write_slave = 8'b00101001; 
		//rw = 0;	// write(0), read(1)
		rw = 1; 
		enable = 1;
		
		#100;
		enable = 0;
		
		#5000
		$finish;
    
 	end
  
  	always #5 clk = ~clk;
  
endmodule
