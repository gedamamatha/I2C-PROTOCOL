`timescale 1ns / 1ps

module ma(
	input wire clk,
	input wire rst,
	input wire [6:0] addr,
	input wire [7:0] data_write_master,
	input wire enable,
	input wire rw,

	output reg [7:0] data_read_master,
	output wire ready,

	inout wire i2c_sda,
	inout wire i2c_scl
	);
    // Estados
	localparam STATE_IDLE = 0;
	localparam STATE_START = 1;
	localparam STATE_ADDRESS = 2;
	localparam STATE_READ_ACK = 3;
	localparam STATE_WRITE_DATA = 4;
	localparam STATE_WRITE_ACK = 5;
	localparam STATE_READ_DATA = 6;
	localparam STATE_READ_ACK2 = 7;
	localparam STATE_STOP = 8;
	
	localparam DIVIDE_BY = 4;

	reg [7:0] state;
	reg [7:0] save_addr;
	reg [7:0] save_data;
	reg [7:0] counter;
	reg [7:0] counter2 = 0;
	reg write_enable;
	reg sda_out;
	reg i2c_scl_enable = 0; 
	reg i2c_clk = 1;

	assign ready = ((rst == 0) && (state == STATE_IDLE)) ? 1 : 0;
	assign i2c_scl = (i2c_scl_enable == 0 ) ? 1 : i2c_clk;
	assign i2c_sda = (write_enable == 1) ? sda_out : 'bz;
	
	always @(posedge clk) begin
		if (counter2 == (DIVIDE_BY/2) - 1) begin
			i2c_clk <= ~i2c_clk;
			counter2 <= 0;
		end
		else counter2 <= counter2 + 1;
	end 
	
	always @(negedge i2c_clk, posedge rst) begin
		if(rst == 1) begin
			i2c_scl_enable <= 0;
		end else begin
			if ((state == STATE_IDLE) || (state == STATE_START) || (state == STATE_STOP)) begin
				i2c_scl_enable <= 0;
			end else begin
				i2c_scl_enable <= 1; 
			end
		end
	
	end

    //LOGIC STATE MACHINE
	always @(posedge i2c_clk, posedge rst) begin
		if(rst == 1) begin
			state <= STATE_IDLE; 
		end		
		else begin
			case(state)
			
				STATE_IDLE: begin 
					if (enable) begin
						state <= STATE_START;
						save_addr <= {addr, rw};
						save_data <= data_write_master; 
					end
					else state <= STATE_IDLE;
				end

				STATE_START: begin  
					counter <= 7;
					state <= STATE_ADDRESS;
				end

				STATE_ADDRESS: begin 
					if (counter == 0) begin 
						state <= STATE_READ_ACK;
					end else counter <= counter - 1;
				end

				STATE_READ_ACK: begin
					if (i2c_sda == 0) begin
						counter <= 7;
						if(save_addr[0] == 0) state <= STATE_WRITE_DATA;
						else state <= STATE_READ_DATA;
					end else state <= STATE_STOP; //EXCEPTION HANDLING
				end

				STATE_WRITE_DATA: begin 
					if(counter == 0) begin
						state <= STATE_READ_ACK2; 
					end else counter <= counter - 1;
				end
				
				STATE_READ_ACK2: begin 
					if ((i2c_sda == 0) && (enable == 1)) state <= STATE_IDLE;
					else state <= STATE_STOP;
				end

				STATE_READ_DATA: begin 
					data_read_master[counter] <= i2c_sda;
					if (counter == 0) state <= STATE_WRITE_ACK;
					else counter <= counter - 1;
				end
				
				STATE_WRITE_ACK: begin 
					state <= STATE_STOP;
				end

				STATE_STOP: begin 
					state <= STATE_IDLE;
				end
			endcase
		end
	end
	//OUTPUT GENERATION
	always @(negedge i2c_clk, posedge rst) begin
		if(rst == 1) begin
			write_enable <= 1;
			sda_out <= 1;
		end else begin
			case(state)
				
				STATE_START: begin 
					write_enable <= 1;
					sda_out <= 0;//BEGIN COND
				end
				
				STATE_ADDRESS: begin
					write_enable <= 1;					
					sda_out <= save_addr[counter]; 
				end
				
				STATE_READ_ACK: begin 
					write_enable <= 0;
				end
				
				STATE_WRITE_DATA: begin 
					write_enable <= 1;
					sda_out <= save_data[counter];
				end
				
				STATE_WRITE_ACK: begin 
					write_enable <= 1;
					sda_out <= 0;
				end
				
				STATE_READ_DATA: begin 
					write_enable <= 0;				
				end
				
				STATE_STOP: begin 
					write_enable <= 1;		
					sda_out <= 1;
				end
			endcase
		end
	end

endmodule