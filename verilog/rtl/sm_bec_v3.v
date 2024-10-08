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

//`include "../../../verilog/rtl/acb.v"

module sm_bec_v3 (
`ifdef USE_POWER_PINS
	inout vccd2,	// User area 2 1.8v supply
	inout vssd2,	// User area 2 digital ground
`endif

	input clk,
	input rst, 
	input enable,
	input load_data,

	input w1, 
	input z1,
	input w2,
	input z2,

	input ki,
	input d,
	input inv_w0,

	output wire next_key,
	output wire [3:0]  becStatus,

	output wire wout,
	output wire zout
);
	// FSM Definition
	reg [2:0] current_state, next_state;
	parameter idle= 4'h0, dload=4'h1, st0=4'h2, st1=4'h3, st2=4'h4, st3=4'h5, st4=4'h6, st5=4'h7, st6=4'h8, uload=4'h9;

	reg [162:0] regA, regB, regC, regD, reg_d, reg_inv_w0;

	reg [7:0] reg_key_iter;
	reg configuration, local_enable;
	reg [162:0] inACB_1, inACB_2;
	wire [162:0] outACB;
	
	wire done_loop, next_round, downloadSig, uploadSig, procSig, idleSig;
	
	assign becStatus = {idleSig, downloadSig, procSig, uploadSig};

	assign next_key = done_loop;
	assign done_loop = (current_state == st_done) ? 1'b1 : 1'b0;
	assign wout = ((reg_key_iter == 162)&(current_state == st_done)) ? regA : 0;
	assign zout = ((reg_key_iter == 162)&(current_state == st_done)) ? regB : 0;
	assign done = ((reg_key_iter == 162)&(current_state == st_done)) ? 1'b1 : 1'b0;

	assign download_done = ((reg_key_iter == 162) & (current_state == dload)) ? 1'b1 : 1'b0;
	assign upload_done = ((reg_key_iter == 162) & (current_state == uload)) ? 1'b1 : 1'b0;

	// assign configuration = ((current_state == st3) ^ (current_state == st6)) ? 1'b1 : 1'b0;

	acb u1(
		`ifdef USE_POWER_PINS
			.vccd2(vccd2),	// User area 2 1.8v supply
			.vssd2(vssd2),	// User area 2 digital ground
		`endif

		.clk(clk),
		.rst(rst),
		.enable(local_enable),
		.A(inACB_1),
		.B(inACB_2),
		.C(outACB),
		.configuration(configuration),
		.done(next_round)
	);

	always @(posedge clk or posedge rst) begin
		if (rst)
			current_state <= idle;
		else 
			current_state <= next_state;
	end

	always @(*) begin
		case (current_state)
			idle:	begin
				idleSig <= 1'b1;
				if (load)
					next_state <= dload;
				else
					next_state <= idle;
			end

			dload: 	begin
				idleSig 	<= 1'b0;
				downloadSig <= 1'b1;
				if (download_done)
					next_state <= st0;
				else
					next_state <= dload;
			end
			
			st0: begin
				downloadSig <= 1'b0;
				procSig 	<= 1'b1;
				if (next_round) 
					next_state <= st1;
				else
					next_state <= st0;
			end
			   	

			st1:    if (next_round)
						next_state <= st2;
					else
						next_state <= st1;

			st2:    if (next_round)
						next_state <= st3;
					else
						next_state <= st2;
			
			st3:    if (next_round)
					next_state <= st4;
				else
					next_state <= st3;

			st4:    if (next_round)
						next_state <= st5;
					else
						next_state <= st4;

			st5:    if (next_round)
						next_state <= st6;
					else
						next_state <= st5;

			st6:    if (next_round)
						next_state <= uload;
					else
						next_state <= st6;
			uload: begin
				procSig <= 1'b0;
				uploadSig <= 1'b1;
				if (upload_done)
					next_state <= idle;
				else
					next_state <= uload;
			end 
			default: next_state <= idle;
		endcase
	end

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			regA <= 0;
			regB <= 0;
			regC <= 0;
			regD <= 0;

			reg_inv_w0 <= 0;
			reg_d <= 0;

			inACB_1 <= 0;
			inACB_2 <= 0;

			reg_key_iter <= 0;
            local_enable <= 1'b0;
		end else begin
			if (downloadSig) begin
				if (ki) begin
					regB <= (regB << 1) ^ z1;
					regC <= (regC << 1) ^ w2;
					regD <= (regD << 1) ^ z2;
					reg_d <= (reg_d << 1) ^ d;
					reg_inv_w0 <= (reg_inv_w0 << 1) ^ inv_w0;
					inACB_1 <= (inACB_1 << 1) ^ w1;
				end else begin
					regB <= (regB << 1) ^ z1;
					regA <= (regA << 1) ^ w1;
					regD <= (regD << 1) ^ z2;
					reg_d <= (reg_d << 1) ^ d;
					reg_inv_w0 <= (reg_inv_w0 << 1) ^ inv_w0;
					inACB_1 <= (inACB_1 << 1) ^ w2;
				end
			end else if (procSig) begin
				if (next_round) begin
					case (current_state)
						st0: begin
							if (ki) begin
								regA <= outACB;
							end else begin
								regC <= outACB;
							end
						end 

						st1: begin
							if (ki) begin
								regA <= regA ^ outACB;
							end else begin
								regC <= regC ^ outACB;
							end
						end

						st2: begin
							if (ki) begin
								regB <= outACB;
							end else begin
								regD <= outACB;
							end
						end

						st3: begin
							if (ki) begin
								regA <= regA ^ outACB;
								regB <= regB ^ outACB;
							end else begin
								regC <= regC ^ outACB;
								regD <= regD ^ outACB;
							end
						end

						st4: begin
							if (ki) begin
								regC <= outACB;
							end else begin
								regA <= outACB;
							end
						end

						st5: begin
							if (ki) begin
								regD <= outACB;
							end else begin
								regB <= outACB;
							end
						end

						st6: begin
							if (ki) begin
								regD <= regC ^ outACB;
							end else begin
								regB <= regA ^ outACB;
							end
						end

						default: begin
							if (reg_key_iter == 0) begin
								if (ki) begin
									regA <= outACB;
									regB <= z1;
									regC <= w2;
									regD <= z2;
								end else begin
									regA <= w1;
									regB <= z1;
									regC <= outACB;
									regD <= z2;
								end
							end else begin
								if (ki) begin
									regA <= outACB;
								end else begin
									regC <= outACB;
								end
							end
						end
					endcase
				end
			end
			

			if (local_enable) begin
				case (current_state)
					st0: begin
						configuration <= 1'b0;
						if (ki) begin
							inACB_2 <= regD;
							if ((reg_key_iter !== 0)) begin
								inACB_1 <= regA;
							end
						end else begin
							inACB_2 <= regB;
							if ((reg_key_iter !== 0)) begin
								inACB_1 <= regC;
							end
						end						
					end 

					st1: begin
						if (ki) begin
                            inACB_1 <= regB;
                            inACB_2 <= regC;
						end else begin
                            inACB_1 <= regA;
                            inACB_2 <= regD;
                        end
					end

					st2: begin
						inACB_1 <= regB; 
                        inACB_2 <= regD;
					end

					st3: begin
						configuration <= 1'b1;
						inACB_1 <= inv_w0;
						if (ki) begin
                            inACB_2 <= regA;
						end else begin
                            inACB_2 <= regC;
                        end
					end

					st4: begin
						configuration <= 1'b0;
						if (ki) begin
                            inACB_1 <= regC;
                            inACB_2 <= regC ^ regD;    
						end else begin
                            inACB_1 <= regA;
                            inACB_2 <= regA ^ regB;
                        end
					end

					st5: begin
						if (ki) begin
                            inACB_1 <= regD;
                            inACB_2 <= regD;
						end else begin
                            inACB_1 <= regB;
                            inACB_2 <= regB;
                        end
					end

					st6: begin
						configuration <= 1'b1;
						inACB_1 <= d;
                        if (ki) begin
                            inACB_2 <= regD;
						end else begin
                            inACB_2 <= regB;
                        end
					end

					default: begin
						inACB_1 <= 0;
                        inACB_2 <= 0;
						configuration <= 1'b0;
					end 
				endcase
			end

			if (enable) begin
				local_enable <= ~(next_round);
				if (done_loop) begin
                    if (reg_key_iter < 163) begin
                        reg_key_iter <= reg_key_iter + 1;
					end else begin
                        reg_key_iter <= 0;
                    end
				end else begin
                    reg_key_iter <= reg_key_iter;
                end
			end else if (downloadSig || uploadSig) begin
				if (reg_key_iter < 163) begin
					reg_key_iter <= reg_key_iter + 1;
				end else begin
					reg_key_iter <= 0;
				end
			end
			
			begin
				local_enable <= 0;
                reg_key_iter <= 0;
			end
		end
	end
endmodule
