// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

`default_nettype none

module controller (
`ifdef USE_POWER_PINS
	inout vccd1,	// User area 1 1.8V supply
	inout vssd1,	// User area 1 digital ground
`endif

	// // Wishbone Slave ports (WB MI A)
	input wb_clk_i,
	input wb_rst_i,

	// Logic Analyzer Signals
	input  [127:0] la_data_in,
	output reg [127:0] la_data_out,
	input  [127:0] la_oenb,
	
	// Interconnection bus of BEC
	output reg slv_enable,					// Enable BEC starts encryption
	output load_data,						// Enable BEC loads config data
	output reg [2:0] load_status,			// Indicate the status of loading data into BEC
	output reg [162:0] data_out,			// Config data bus to BEC
	output reg trigLoad,					// Indicate the MSBs or LSBs bit of configuration data
	output ki,								// LSB of Key			
	input next_key,							// Request the next bit of key

	input [3:0] becStatus,					// Indicate the status of BEC
	input slv_done,							// Indicate BEC completed encryption
	input [162:0] data_in					// Input Data Bus from BEC
);
	wire clk;
	wire rst;
	reg  enable_proc, enable_write, updateRegs, master_ena_proc;
	reg mode_exec;					// Determine the mode of encryption: 1- Multiple Execution; 0- Single Execution
	reg [162:0] reg_w1, reg_z1, reg_w2, reg_z2, reg_d, reg_inv_w0, reg_key;
	reg [162:0] buf_w1, buf_z1, buf_w2, buf_z2, buf_d, buf_inv_w0, buf_key;
	reg [162:0] reg_wout, reg_zout;
	reg [2:0] counterControl;
	// FSM Definition
	reg [1:0] current_state, next_state;
	parameter idle=2'b00, write_mode=2'b01,  proc=2'b11, read_mode=2'b10;
	assign ki = (current_state == proc) ? reg_key[0] : 1'b0;
	// assign trigLoad = (enable_write == 1'b1) ? ~la_data_out[122] : 1'b0;
	assign load_data = enable_write;
	// Assuming LA probes [65:64] are for controlling the count clk & reset  
	assign clk = wb_clk_i;
	assign rst = wb_rst_i;
	
	// assign slv_done = (current_state == 2'b11) ? 1'b1 : 1'b0;

	/*
	Nơi khai báo tên instantaneous và nối các chân của khối BEC.
	*/

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			current_state <= idle;
			mode_exec <= 1'b0;
		end else begin
			current_state <= next_state;
			if (la_data_in[95:0] == 96'h00000000FD30) begin
				mode_exec <= 1'b1;
			end else if (la_data_in[95:0] == 96'h00000000FC30) begin
				mode_exec <= 1'b0;
			end
		end
	end

	always @(*) begin
		case (current_state)
			idle: begin
				if (enable_write == 1'b1) begin
					next_state = write_mode;
				end else begin 
					next_state = idle;
				end
			end

			write_mode: begin
				if (enable_proc == 1'b1) begin
					next_state = proc;
				end else begin 
					next_state = write_mode;
				end
			end

			proc: begin
				if (slv_done) begin
					next_state <= read_mode;
				end else begin 
					next_state <= proc;
				end
			end

			read_mode: begin
				if (updateRegs == 1'b1) begin
					next_state <= idle;
				end else begin
					next_state <= read_mode;
				end
			end

			default:
			next_state <= idle;
		endcase
	end

	always @(*) begin
		case (current_state)
			idle: begin
				enable_proc <= 1'b0;
				updateRegs <= 1'b0;
				if (mode_exec == 1'b1) begin				// Enable BEC run Multiple Encryption mode
					if (la_data_in[15:0] != 16'h0000) 
						master_ena_proc <= 1'b1;
					else
						master_ena_proc <= 1'b0;
				end

				if ((la_data_in[31:16] == 16'hAB30) & (la_data_in[95:82] == 14'b0000000000)) begin	// Processors request to go forward the next state
					if (la_data_in[15:0] == 16'h0000) begin
						enable_write <= 1'b1;				// Run Single Encryption Mode (force to next state)
					end else if ((mode_exec == 1'b1) & (becStatus == 4'h8)) begin
						enable_write <= 1'b1;				// Run Multi Encryption Mode (wait the BEC complete to next state)
					end else
						enable_write <= 1'b0;
				end else 
					enable_write <= 1'b0;
			end 

			write_mode: begin
				updateRegs <= 1'b0;
				if (mode_exec == 1'b1) begin				// Enable BEC run Multiple Encryption mode
					if (la_data_in[15:0] != 16'h0000) 
						master_ena_proc <= 1'b1;
					else
						master_ena_proc <= 1'b0;
				end

				if ((la_data_in[31:16] == 16'hAB41) & (la_data_in[95:82] == 14'b0000000000)) begin	// Processors request to go forward the next state
					if (la_data_in[15:0] == 16'h0000) begin
						enable_proc <= 1'b1;				// Run Single Encryption Mode (force to next state)
					end else if ((mode_exec == 1'b1) & (becStatus == 4'h8)) begin
						enable_proc <= 1'b1;				// Run Multi Encryption Mode (wait the BEC complete to next state)
					end else
						enable_proc <= 1'b0;
				end else 
					enable_proc <= 1'b0;
			end

			proc: begin
				enable_write <= 1'b0;
				if (~slv_done)
					master_ena_proc <= 1'b1;
				else
					master_ena_proc <= 1'b0;
			end

			read_mode: begin
				
				if (mode_exec == 1'b1) begin				// Enable BEC run Multiple Encryption mode
					if (la_data_in[15:0] != 16'h0000) 
						master_ena_proc <= 1'b1;
					else
						master_ena_proc <= 1'b0;
				end else
					master_ena_proc <= 1'b0;

				if ((la_data_in[32:16] == 16'hAB50) ) begin
					if (la_data_in[15:0] == 16'h0000) begin
						updateRegs <= 1'b1;				// Run Single Encryption Mode (force to next state)
					end else if ((mode_exec == 1'b1) & (becStatus == 4'h8)) begin
						updateRegs <= 1'b1;				// Run Multi Encryption Mode (wait the BEC complete to next state)
					end else
						updateRegs <= 1'b1;
				end else
					updateRegs <= 1'b0;
			end
			default: begin
				master_ena_proc <= 1'b0;
				enable_write <= 1'b0;
				enable_proc <= 1'b0;
				updateRegs <= 1'b0;
			end
		endcase
	end

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			load_status   	<= 0;
			trigLoad	  	<= 0;
			la_data_out 	<= {(128){1'b0}};

			reg_w1			<= 0; 	
			reg_z1 			<= 0;
			reg_w2 			<= 0;
			reg_z2 			<= 0;
			reg_d 			<= 0;
			reg_inv_w0		<= 0;
			reg_key			<= 0;

			buf_w1			<= 0; 	
			buf_z1 			<= 0;
			buf_w2 			<= 0;
			buf_z2 			<= 0;
			buf_d 			<= 0;
			buf_inv_w0		<= 0;
			buf_key			<= 0;
			data_out		<= 0;
			
			counterControl  <= 0;
		end else begin
			case (current_state)
				idle: begin
					la_data_out[127:122] <= 6'b000000; 
				end 

				write_mode: begin
					if (la_data_in[95:82] == 14'b00000000000001) begin
						buf_w1[162:82] 	<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b0001; 	//0x04
					end else if (la_data_in[95:82] == 14'b00000000000011) begin
						buf_w1[81:0] 		<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b0010;	//0x08
						trigLoad			<= 1'b1;
						load_status <= 3'b000;				// Pushing w1 to the BEC

					end else if (la_data_in[95:82] == 14'b00000000000111) begin
						buf_z1[162:82] 	<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b0011;	//0x0C
						trigLoad			<= 1'b0;
					end else if (la_data_in[95:82] == 14'b00000000001111) begin
						buf_z1[81:0] 		<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b0100; 	//0x10
						trigLoad			<= 1'b1;
						load_status <= 3'b001;				// Pushing z1 to the BEC
					end else if (la_data_in[95:82] == 14'b00000000011111) begin
						buf_w2[162:82] 	<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b0101;	//0x14
						trigLoad			<= 1'b0;
					end else if (la_data_in[95:82] == 14'b00000000111111) begin
						buf_w2[81:0] 		<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b0110;	//0x18
						trigLoad			<= 1'b1;
						load_status <= 3'b010;				// Pushing w2 to the BEC
					end else if (la_data_in[95:82] == 14'b00000001111111) begin
						buf_z2[162:82] 	<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b0111;	//0x1C
						trigLoad			<= 1'b0;
					end else if (la_data_in[95:82] == 14'b00000011111111) begin
						buf_z2[81:0] 		<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b1000;	//0x20
						trigLoad			<= 1'b1;
						load_status <= 3'b011;				// Pushing z2 to the BEC
					end else if (la_data_in[95:82] == 14'b00000111111111) begin
						buf_inv_w0[162:82] 	<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b1001;	//0x24
						trigLoad			<= 1'b0;
					end else if (la_data_in[95:82] == 14'b00001111111111) begin
						buf_inv_w0[81:0] 		<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b1010;	//0x28
						trigLoad			<= 1'b1;
						load_status <= 3'b100;				// Pushing inv_w0 to the BEC
					end else if (la_data_in[95:82] == 14'b00011111111111) begin
						buf_d[162:82] 	<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b1011;	// 0x2C in
						trigLoad			<= 1'b0;
					end else if (la_data_in[95:82] == 14'b00111111111111) begin
						buf_d[81:0] 		<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b1100; 	//0x30
						trigLoad			<= 1'b1;
						load_status <= 3'b101;				// Pushing d to the BEC
					end else if (la_data_in[95:82] == 14'b01111111111111) begin
						buf_key[162:82] 	<= la_data_in[80:0];
						trigLoad			<= 1'b0;
						la_data_out[125:122] <= 4'b1101;	//0x34
					end else if (la_data_in[95:82] == 14'b11111111111111) begin
						buf_key[81:0] 		<= la_data_in[81:0];
						la_data_out[127:122] <= 6'b011110;	//0x78
					end

					if (enable_proc) begin
						reg_w1 	<= 	buf_w1;
						reg_z1 	<= 	buf_z1;
						reg_w2 	<= 	buf_w2;
						reg_z2 	<= 	buf_z1;
						reg_d 		<= 	buf_d;
						reg_inv_w0	<= 	buf_inv_w0;
						reg_key	<= 	buf_key;
					end
				end

				proc: begin
					la_data_out[127:122] <= 6'b100111;
					la_data_out[121:0] <= {(122){1'b0}};
					if (next_key) begin
						reg_key <= {reg_key[0], reg_key[162:1]};
					end
				end

				read_mode: begin
					case (counterControl)
						3'b000: reg_wout <= data_in;
						3'b001: reg_zout <= data_in;
						default: reg_zout <= data_in;
					endcase
					if (la_data_in[31:24] == 8'hAB) begin
						case (la_data_in[23:16]) 
							8'h04: begin
								la_data_out[113:32] 	<= reg_wout[81:0]; 
								la_data_out[127:114]	<= 14'b11001000000000;		// 0xC8
							end

							8'h08: begin
								load_status <= 3'b001;
								la_data_out[112:32] 	<= reg_zout[162:82]; 
								la_data_out[127:114]	<= 14'b11001100000000;		// 0xCC
							end

							8'h0C: begin
								load_status <= 3'b001;
								la_data_out[113:32] 	<= reg_zout[81:0]; 
								la_data_out[127:114]	<= 14'b11010000000000;		// 0xD0
							end

							default: begin
								la_data_out[112:32] 	<= reg_wout[162:82]; 		// 0xC4
								la_data_out[127:114]	<= 14'b11000100000000;
							end
						endcase
					end
				end
				
				default: begin
					load_status <= 0;
					
					
					la_data_out[127:122] <= 6'b001100; 
				end
			endcase

			if ((counterControl < 6) & (master_ena_proc == 1'b1)) begin
				counterControl <= counterControl + 1;
				case (counterControl)
					3'b000: begin
						data_out 	<= reg_w1;
						slv_enable  <= 0;
					end
					3'b001: data_out 	<= reg_z1;
					3'b010: data_out 	<= reg_w2;
					3'b011: data_out 	<= reg_z2;
					3'b100: data_out 	<= reg_inv_w0;
					3'b101: data_out 	<= reg_d;
					3'b110: slv_enable <= 1'b1;
					default: data_out <= 0;
				endcase
			end else if (slv_done) begin
				counterControl <= 3'b001;
			end else if (becStatus == 4'h8) begin
				counterControl <= 3'b000;
			end
		end
	end
endmodule

`default_nettype wire