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

`include "../../../verilog/rtl/acb.v"
module sm_bec_v3 (
	input clk,
	input rst, 
	input enable,

	input [162:0] w1, 
	input [162:0] z1,
	input [162:0] w2,
	input [162:0] z2,

	input ki,
	input [162:0] d,
	input [162:0] inv_w0,

	output wire next_key,
	output wire done,
	output wire [162:0] wout,
	output wire[162:0] zout
);
	// FSM Definition
	reg [2:0] current_state, next_state;
	parameter idle=3'b000, st1=3'b001, st2=3'b010, st3=3'b011, st4=3'b100, st5=3'b101, st6=3'b110, st_done=3'b111;

	reg [162:0] regA, regB, regC, regD;
	reg [7:0] reg_key_iter;
	reg configuration, local_enable;
	reg [162:0] inACB_1, inACB_2;
	wire [162:0] outACB;
	wire done_loop, next_round;

	assign next_key = done_loop;
	assign done_loop = (current_state == st_done) ? 1'b1 : 1'b0;
	assign wout = ((reg_key_iter == 162)&(current_state == st_done)) ? regA : 0;
	assign zout = ((reg_key_iter == 162)&(current_state == st_done)) ? regB : 0;
	assign done = ((reg_key_iter == 162)&(current_state == st_done)) ? 1'b1 : 1'b0;
	// assign configuration = ((current_state == st3) ^ (current_state == st6)) ? 1'b1 : 1'b0;

	acb u1(
		.clk(clk),
		.rst(rst),
		.enable(local_enable),
		.A(inACB_1),
		.B(inACB_2),
		.C(outACB),
		.configuration(configuration),
		.done(next_round)
	);

	always @(posedge clk or rst) begin
		if (rst)
			current_state <= idle;
		else 
			current_state <= next_state;
	end

	always @(*) begin
		if (enable) begin
			case (current_state)
				idle:   if (next_round) 
							next_state <= st1;
						else
							next_state <= idle;

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
							next_state <= st_done;
						else
							next_state <= st6;
				st_done: next_state <= idle;
				default: next_state <= idle;
			endcase
		end else
			next_state <= idle;
	end

	always @(posedge clk or rst) begin
		if (rst) begin
			regA <= 0;
			regB <= 0;
			regC <= 0;
			regD <= 0;

			inACB_1 <= 0;
			inACB_2 <= 0;

			reg_key_iter <= 0;
            local_enable <= 1'b0;
		end else begin
			if (next_round) begin
				case (current_state)
					idle: begin
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

			if (local_enable) begin
				case (current_state)
					idle: begin
						configuration <= 1'b0;
						if (reg_key_iter == 0) begin
							if (ki) begin
								inACB_1 <= w1;
								inACB_2 <= z2;
							end else begin
								inACB_1 <= w2;
                                inACB_2 <= z1;
							end
						end else begin
							if (ki) begin
                                inACB_1 <= regA;
                                inACB_2 <= regD;
							end else begin
                                inACB_1 <= regC;
                                inACB_2 <= regB;
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
			end else begin
				inACB_1 <= 0;
                inACB_2 <= 0;
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
			end else begin
				local_enable <= 0;
                reg_key_iter <= 0;
			end
		end
	end
endmodule