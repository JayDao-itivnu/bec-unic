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
	inout vccd2,	// User area 2 1.8v supply
	inout vssd1,	// User area 1 digital ground
	inout vssd2,	// User area 2 digital ground
`endif

	// // Wishbone Slave ports (WB MI A)
	input wb_clk_i,
	input wb_rst_i,

	// Logic Analyzer Signals
	input  	[127:0] 	la_data_in,
	output 	reg [127:0] la_data_out,
	input  	[127:0] 	la_oenb,
	
	input 	slv_done,

	// Control Slave Signals
	output reg master_ena_proc,
	output enable_write,
	output updateRegs

);
	wire clk;
	wire rst;
	reg master_enable, master_load, enable_proc, enable_write, updateRegs;

	// FSM Definition
	reg [1:0]current_state, next_state;
	parameter idle=2'b00, write_mode=2'b01, proc=2'b11, read_mode=2'b10;

	
	
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

	always @(enable_write or enable_proc or updateRegs or slv_done) begin
		case (current_state)
			idle: begin
				if (enable_write == 1'b1) begin
					next_state <= write_mode;
				end else begin 
					next_state <= idle;
				end
			end

			write_mode: begin
				if (enable_proc == 1'b1) begin
					next_state <= proc;
				end else begin 
					next_state <= write_mode;
				end
			end

			proc: begin
				if (slv_done == 1'b1) begin
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

endmodule

`default_nettype wire
