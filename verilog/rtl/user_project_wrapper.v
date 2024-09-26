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
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
	parameter BITS = 32
) (
`ifdef USE_POWER_PINS
	inout vdda1,	// User area 1 3.3V supply
	inout vdda2,	// User area 2 3.3V supply
	inout vssa1,	// User area 1 analog ground
	inout vssa2,	// User area 2 analog ground
	inout vccd1,	// User area 1 1.8V supply
	inout vccd2,	// User area 2 1.8v supply
	inout vssd1,	// User area 1 digital ground
	inout vssd2,	// User area 2 digital ground
`endif

	// Wishbone Slave ports (WB MI A)
	input wb_clk_i,
	input wb_rst_i,
	input wbs_stb_i,
	input wbs_cyc_i,
	input wbs_we_i,
	input [3:0] wbs_sel_i,
	input [31:0] wbs_dat_i,
	input [31:0] wbs_adr_i,
	output wbs_ack_o,
	output [31:0] wbs_dat_o,

	// Logic Analyzer Signals
	input  [127:0] la_data_in,
	output [127:0] la_data_out,
	input  [127:0] la_oenb,

	// IOs
	input  [`MPRJ_IO_PADS-1:0] io_in,
	output [`MPRJ_IO_PADS-1:0] io_out,
	output [`MPRJ_IO_PADS-1:0] io_oeb,

	// Analog (direct connection to GPIO pad---use with caution)
	// Note that analog I/O is not available on the 7 lowest-numbered
	// GPIO pads, and so the analog_io indexing is offset from the
	// GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
	inout [`MPRJ_IO_PADS-10:0] analog_io,

	// Independent clock (on independent integer divider)
	input   user_clock2,

	// User maskable interrupt signals
	output [2:0] user_irq
);

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/
	reg [162:0] reg_w1, reg_z1, reg_w2, reg_z2, reg_inv_w0, reg_d, reg_key;
	reg [162:0] reg_wout, reg_zout;
	wire [162:0] wout, zout;
	reg [127:0] reg_la_out;
	reg reg_ki;
	wire master_ena_proc, enable_write, updateRegs, next_key, slv_done;

	assign la_data_out = reg_la_out;

	always @(posedge wb_clk_i or posedge wb_rst_i) begin
		if (wb_rst_i) begin
			reg_w1      <= 0;
			reg_z1      <= 0;
			reg_w2      <= 0;
			reg_z2      <= 0;
			reg_inv_w0  <= 0;
			reg_d       <= 0;
			reg_key     <= 0;
			reg_la_out <= {(128){1'b0}};

		end else begin
			if (enable_write == 1'b1 & updateRegs == 1'b0 & master_ena_proc == 1'b0) begin
				if (la_data_in [95:82] == 14'b00000000000011) begin
					reg_w1[81:0] 		<= la_data_in[81:0];
					reg_la_out[125:122] <= 4'b0010;	//0x08

				end else if (la_data_in [95:82] == 14'b00000000000111) begin
					reg_z1[162:82] 	<= la_data_in[80:0];
					reg_la_out[125:122] <= 4'b0011;	//0x0C

				end else if (la_data_in [95:82] == 14'b00000000001111) begin
					reg_z1[81:0] 		<= la_data_in[81:0];
					reg_la_out[125:122] <= 4'b0100; 	//0x10

				end else if (la_data_in [95:82] == 14'b00000000011111) begin
					reg_w2[162:82] 	<= la_data_in[80:0];
					reg_la_out[125:122] <= 4'b0101;	//0x14

				end else if (la_data_in [95:82] == 14'b00000000111111) begin
					reg_w2[81:0] 		<= la_data_in[81:0];
					reg_la_out[125:122] <= 4'b0110;	//0x18

				end else if (la_data_in [95:82] == 14'b00000001111111) begin
					reg_z2[162:82] 	<= la_data_in[80:0];
					reg_la_out[125:122] <= 4'b0111;	//0x1C

				end else if (la_data_in [95:82] == 14'b00000011111111) begin
					reg_z2[81:0] 		<= la_data_in[81:0];
					reg_la_out[125:122] <= 4'b1000;	//0x20

				end else if (la_data_in [95:82] == 14'b00000111111111) begin
					reg_inv_w0[162:82] 	<= la_data_in[80:0];
					reg_la_out[125:122] <= 4'b1001;	//0x24

				end else if (la_data_in [95:82] == 14'b00001111111111) begin
					reg_inv_w0[81:0] 		<= la_data_in[81:0];
					reg_la_out[125:122] <= 4'b1010;	//0x28

				end else if (la_data_in [95:82] == 14'b00011111111111) begin
					reg_d[162:82] 	<= la_data_in[80:0];
					reg_la_out[125:122] <= 4'b1011;	//0x2C

				end else if (la_data_in [95:82] == 14'b00111111111111) begin
					reg_d[81:0] 		<= la_data_in[81:0];
					reg_la_out[125:122] <= 4'b1100; 	//0x30

				end else if (la_data_in [95:82] == 14'b01111111111111) begin
					reg_key[162:82] 	<= la_data_in[80:0];
					reg_la_out[125:122] <= 4'b1101;	//0x34
				end else if (la_data_in [95:82] == 14'b11111111111111) begin
					reg_key[81:0] 		<= la_data_in[81:0];
					reg_la_out[127:122] <= 6'b011110;	//0x78
				end else begin
					reg_w1[162:82] 		<= la_data_in[80:0];
					reg_la_out[125:122] <= 4'b0001; 	//0x04
				end
			end 
			if (enable_write == 1'b0 & master_ena_proc == 1'b1 & updateRegs == 1'b0) begin
				reg_la_out[127:122] <= 6'b100111;
				reg_la_out[121:0] <= {(122){1'b0}};
				if (next_key) begin
					reg_key <= reg_key >> 1;
				end

				if (slv_done) begin
					reg_wout <= wout;
					reg_zout <= zout;
				end	
			end 
			if (updateRegs == 1'b1) begin
				if (la_data_in[31:24] == 8'hAB) begin
					case (la_data_in[23:16]) 
						8'h04: begin
							reg_la_out[113:32] 	<= reg_wout[81:0]; 
							reg_la_out[127:114]	<= 14'b11001000000000;		// 0xC8
						end

						8'h08: begin
							reg_la_out[112:32] 	<= reg_zout[162:82]; 
							reg_la_out[127:114]	<= 14'b11001100000000;		// 0xCC
						end

						8'h0C: begin
							reg_la_out[113:32] 	<= reg_zout[81:0]; 
							reg_la_out[127:114]	<= 14'b11010000000000;		// 0xD0
						end

						default: begin
							reg_la_out[112:32] 	<= reg_wout[162:82]; 		// 0xC4
							reg_la_out[127:114]	<= 14'b11000100000000;
						end
					endcase
				end
			end else begin
				reg_la_out[127:122] <= 6'b000000; 
			end
		end
	end

	user_proj_example mprj (
	`ifdef USE_POWER_PINS
		.vccd1(vccd1),	// User area 1 1.8V power
		.vssd1(vssd1),	// User area 1 digital ground
	`endif

		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		
		// Logic Analyzer

		.la_data_in(la_data_in),
		.la_data_out(la_data_out),
		.la_oenb (la_oenb),
		
		// Control bus sm_bec_v3

		.master_ena_proc(master_ena_proc),
		.enable_write(enable_write),
		.updateRegs(updateRegs),
		.slv_done(slv_done)
	);

	sm_bec_v3 bec_core (
		`ifdef USE_POWER_PINS
			.vccd2(vccd2),  // User area 2 1.8V power
			.vssd2(vssd2),  // User area 2 digital ground
		`endif

		.clk(wb_clk_i),
		.rst(wb_rst_i),
		.enable(master_ena_proc),
		.w1(reg_w1),
		.z1(reg_z1),
		.w2(reg_w2),
		.z2(reg_z2),
		.ki(reg_ki),
		.d(reg_d),
		.inv_w0(reg_inv_w0),
		.next_key(next_key),
		.wout(wout),
		.zout(zout),
		.done(slv_done)
	);

endmodule	// user_project_wrapper

`default_nettype wire
