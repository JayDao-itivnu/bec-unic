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

`default_nettype none
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
// `include "../../../verilog/rtl/sm_bec_v3.v"
// `include "../../../verilog/rtl/counter.v"
module user_proj_example (
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
	
	// Status output of BEC
	input [3:0] becStatus,
	input next_key,

	output reg master_ena_proc,
	output ki,

	output w1,
	output z1,
	output w2,
	output z2,
	output inv_w0,
	output d,
	output load_data,

	input wout,
	input zout
);
	wire clk;
	wire rst;
	reg master_enable, master_load, enable_proc, enable_write, updateRegs;
	reg reg_cnt;
	parameter DELAY = 2000;

	reg [162:0] reg_key, reg_w1, reg_z1, reg_w2, reg_z2, reg_inv_w0, reg_d;
	reg [162:0] reg_wout, reg_zout;

	// FSM Definition
	reg [1:0]current_state, next_state;
	parameter idle=3'b000, write_mode=3'b001, upload=3'b010,  proc=3'b011, download=3'b100, read_mode=3'b101;

	assign ki = reg_key[0];
	assign w1 = reg_w1[162];
	assign z1 = reg_z1[162];
	assign w2 = reg_w2[162];
	assign z2 = reg_z2[162];
	assign inv_w0 = reg_inv_w0[162];
	assign d = reg_d[162];
	// Assuming LA probes [65:64] are for controlling the count clk & reset  
	assign clk = wb_clk_i;
	assign rst = wb_rst_i;
	
	// assign slv_done = (current_state == 2'b11) ? 1'b1 : 1'b0;

	/*
	Nơi khai báo tên instantaneous và nối các chân của khối BEC.
	*/

	always @(posedge clk or posedge rst) begin
		if (rst) 
			current_state <= idle;
		else
			current_state <= next_state;
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
					next_state = upload;
				end else begin 
					next_state = write_mode;
				end
			end

			upload: begin
				if (becStatus[2]!== 0) 
					next_state = proc;
				else
					next_state = upload;
			end

			proc: begin
				if (slv_done == 1'b1) begin
					next_state <= download;
				end else begin 
					next_state <= proc;
				end
			end

			download: begin
				if (becStatus[0]!== 0)
					next_state = read_mode;
				else
					next_state = download;
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
				if (la_data_in[31:16] == 16'hAB30) begin
					enable_write <= 1'b1;
				end else 
					enable_write <= 1'b0;
			end 

			write_mode: begin
				updateRegs <= 1'b0;
				if (la_data_in[31:16] == 16'hAB41) begin
					enable_proc <= 1'b1;
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
				master_ena_proc <= 1'b0;
				if (la_data_in[32:16] == 16'hAB50)
					updateRegs <= 1'b1;
				else
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
			w1      <= 0;
			z1      <= 0;
			w2      <= 0;
			z2      <= 0;
			inv_w0  <= 0;
			d       <= 0;
			reg_key     <= 0;
			la_data_out <= {(128){1'b0}};
	
		end else begin
			case (current_state)
				idle: begin
					la_data_out[127:122] <= 6'b000000; 
				end 

				write_mode: begin
					if (la_data_in[95:82] == 14'b00000000000001) begin
						w1[162:82] 	<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b0001; 	//0x04
					end else if (la_data_in[95:82] == 14'b00000000000011) begin
						w1[81:0] 		<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b0010;	//0x08

					end else if (la_data_in[95:82] == 14'b00000000000111) begin
						z1[162:82] 	<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b0011;	//0x0C
					end else if (la_data_in[95:82] == 14'b00000000001111) begin
						z1[81:0] 		<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b0100; 	//0x10

					end else if (la_data_in[95:82] == 14'b00000000011111) begin
						w2[162:82] 	<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b0101;	//0x14
					end else if (la_data_in[95:82] == 14'b00000000111111) begin
						w2[81:0] 		<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b0110;	//0x18

					end else if (la_data_in[95:82] == 14'b00000001111111) begin
						z2[162:82] 	<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b0111;	//0x1C
					end else if (la_data_in[95:82] == 14'b00000011111111) begin
						z2[81:0] 		<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b1000;	//0x20

					end else if (la_data_in[95:82] == 14'b00000111111111) begin
						inv_w0[162:82] 	<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b1001;	//0x24
					end else if (la_data_in[95:82] == 14'b00001111111111) begin
						inv_w0[81:0] 		<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b1010;	//0x28

					end else if (la_data_in[95:82] == 14'b00011111111111) begin
						d[162:82] 	<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b1011;	//0x2C
					end else if (la_data_in[95:82] == 14'b00111111111111) begin
						d[81:0] 		<= la_data_in[81:0];
						la_data_out[125:122] <= 4'b1100; 	//0x30

					end else if (la_data_in[95:82] == 14'b01111111111111) begin
						reg_key[162:82] 	<= la_data_in[80:0];
						la_data_out[125:122] <= 4'b1101;	//0x34
					end else if (la_data_in[95:82] == 14'b11111111111111) begin
						reg_key[81:0] 		<= la_data_in[81:0];
						la_data_out[127:122] <= 6'b011110;	//0x78
					end
				end
				
				upload: begin
					if (load_data) begin
						reg_w1 		<= reg_w1 << 1;
						reg_z1 		<= reg_z1 << 1;
						reg_w2 		<= reg_w2 << 1;
						reg_z2 		<= reg_z2 << 1;
						reg_inv_w0 	<= reg_inv_w0 << 1;
						reg_d 		<= reg_d << 1;
					end
				end

				proc: begin
					la_data_out[127:122] <= 6'b100111;
					la_data_out[121:0] <= {(122){1'b0}};
					if (next_key) begin
						reg_key <= reg_key >> 1;
					end
					// if (slv_done) begin
					// 	dlding <= 1'b1;
					// end	else begin
					// 	dlding <= 1'b0;
					// end
				end
				
				download: begin
					reg_wout <= (reg_wout << 1) ^ wout;
					reg_zout <= (reg_zout << 1) ^ zout;
				end

				read_mode: begin
					// enable_write <= 1'h0;
					if (la_data_in[31:24] == 8'hAB) begin
						case (la_data_in[23:16]) 
							8'h04: begin
								la_data_out[113:32] 	<= reg_wout[81:0]; 
								la_data_out[127:114]	<= 14'b11001000000000;		// 0xC8
							end

							8'h08: begin
								la_data_out[112:32] 	<= reg_zout[162:82]; 
								la_data_out[127:114]	<= 14'b11001100000000;		// 0xCC
							end

							8'h0C: begin
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
					w1      <= 0;
					z1      <= 0;
					w2      <= 0;
					z2      <= 0;
					inv_w0  <= 0;
					d       <= 0;
					reg_key     <= 0;
					
					reg_wout    <= 0;
					reg_zout    <= 0;
					
					la_data_out[127:122] <= 6'b001100; 
				end
			endcase
		end
	end
endmodule

`default_nettype wire