/*--------------------------------------------------------------------------
-- Classic squarer (classic_squarer.v)
--
-- Computes the polynomial multiplication A.A mod f in GF(2**m)
-- The hardware is genenerate for a specific f.
--
-- Its is based on classic modular multiplier, but use the fact that
-- Squaring a polinomial is simplier than multiply.
--
-- Defines 2 entities:
-- poly_reducer: reduces a (2*m-1)- bit polynomial by f to an m-bit polinomial
-- classic_multiplication: instantiates the poly_reducer and squares the A polinomial
-- and a Package (classic_multiplier_parameterse)
-- 
----------------------------------------------------------------------------

------------------------------------------------------------
-- poly_reducer
------------------------------------------------------------*/

module poly_reducer #(
	parameter integer M = 163,
	parameter [M-1:0] F = 163'h00000000000000000000000000000000000000C9
) (
	input [2*M-2:0] d,
	output reg [M-1:0] c
);

	reg [M-2:0] R [0:M-1];

	integer i, j;
	initial begin
		for(j = 0; j < M; j=j+1) begin
			for(i = 0; i < M; i=i+1) begin
				R[j][i] <=  0;
			end
		end

		for(j = 0; j < M; j=j+1) begin
			R[j][0] <=  F[j];
		end
		
		for(i = 1; i < M-1; i=i+1) begin
			for(j = 0; j < M; j=j+1) begin
				if (j == 0) begin
					R[j][i] <= R[M-1][i-1] & R[j][0];
				end else begin
					R[j][i] <= R[j-1][i-1] ^ (R[M-1][i-1] & R[j][0]);
				end
			end
		end
	end

// Generate XOR
	generate
		genvar k;
		for (k = 0; k < M; k=k+1) begin
			reg aux;
			integer i;
			always @(*) begin
				aux = d[k];
				for (i = 0; i < M-1; i=i+1) begin
					aux <= aux ^ (d[M+i] & R[k][i]);
				end
				c[k] <= aux;
			end
		end
	endgenerate

endmodule

//----------------------------------------------------------
// Classic Squaring
//----------------------------------------------------------

module classic_squarer #(
	parameter integer M = 163,
	parameter [M-1:0] F = 163'h00000000000000000000000000000000000000C9
)(
	input  [M-1:0] a,
	output [M-1:0] c
);

  wire [2*M-2:0] d;

  
  assign d[0] = a[0];
  generate
	genvar i;
	for (i = 1; i < M; i=i+1) begin 
	  assign d[2*i-1] = 1'b0;
	  assign d[2*i] = a[i];
	end
  endgenerate

  poly_reducer #(.M(M), .F(F)) inst_reduc (
	.d(d),
	.c(c)
  );

endmodule

			


