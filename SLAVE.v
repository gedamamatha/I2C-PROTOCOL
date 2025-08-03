`timescale 1ns / 1ps

//This module controls all I2C master communication


module sl(
	inout  wire sda,              
	inout  wire scl,               
    	input  wire [7:0] data_write_slave,  
    	output reg [7:0] data_read_slave    
	);
	
    localparam ADDRESS_SLAVE = 7'b1010101;      
    
	localparam STATE_READ_ADDR = 0; 
	localparam STATE_SEND_ACK = 1;
	localparam STATE_READ_DATA = 2;
	localparam STATE_WRITE_DATA = 3;
	localparam STATE_SEND_ACK2 = 4;
	
	reg [7:0] addr;
	reg [7:0] counter;
	reg [7:0] state = 0;
	reg sda_out = 0;
	reg sda_in = 0;
	reg start = 0;
	reg write_enable = 0;
	
	assign sda = (write_enable == 1) ? sda_out : 'bz;
	
	always @(negedge sda) begin
		if ((start == 0) && (scl == 1)) begin
			start <= 1;	
			counter <= 7;
		end
	end
	
	always @(posedge sda) begin 
		if ((start == 1) && (scl == 1)) begin
			state <= STATE_READ_ADDR;
			start <= 0;
			write_enable <= 0;
		end
	end
	
	always @(posedge scl) begin
		if (start == 1) begin
			case(state)
				STATE_READ_ADDR: begin  
					addr[counter] <= sda;
					if(counter == 0) state <= STATE_SEND_ACK;
					else counter <= counter - 1;					
				end
				
				STATE_SEND_ACK: begin  
					if(addr[7:1] == ADDRESS_SLAVE) begin
						counter <= 7;
						if(addr[0] == 0) begin 
							state <= STATE_READ_DATA;
						end
						else state <= STATE_WRITE_DATA;
					end
				end
				
				STATE_READ_DATA: begin 
					data_read_slave[counter] <= sda;
					if(counter == 0) begin
						state <= STATE_SEND_ACK2;
					end else counter <= counter - 1;
				end
				
				STATE_SEND_ACK2: begin 
					state <= STATE_READ_ADDR;					
				end
				
				STATE_WRITE_DATA: begin 
					if(counter == 0) state <= STATE_READ_ADDR;
					else counter <= counter - 1;		
				end
				
			endcase
		end
	end
	
	always @(negedge scl) begin
		case(state)
			
			STATE_READ_ADDR: begin 
				write_enable <= 0; 			
			end
			
			STATE_SEND_ACK: begin  
				sda_out <= 0;     
				write_enable <= 1;	
			end
			
			STATE_READ_DATA: begin 
				write_enable <= 0;
			end
			
			STATE_WRITE_DATA: begin 
				sda_out <= data_write_slave[counter];
				write_enable <= 1; 
			end
			
			STATE_SEND_ACK2: begin 
				sda_out <= 0;
				write_enable <= 1;
			end
		endcase
	end

endmodule
