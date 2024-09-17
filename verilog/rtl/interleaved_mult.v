/*--------------------------------------------------------------------------
-- Interleaved Multiplier (interleaved_mult.v)
--
-- LSB first
-- 
-- Computes the polynomial multiplication mod f in GF(2**m)
-- Implements a sequential cincuit

-- Defines 2 entities (interleaved_data_path and interleaved_mult)
-- 
----------------------------------------------------------------------------

-----------------------------------
-- Interleaved MSB-first multipication data_path
-----------------------------------*/


module shift_reg #(
   parameter M = 163,
   parameter F = 163'h00000000000000000000000000000000000000C9
) (

   input  [M-1:0] A,
   input  clk,
   input  load,
   input  shift_r,
   input  rst,
   output reg [M-1:0] Z
); 
   reg [M-1:0] aa;
   

   always @(posedge clk or posedge rst) begin
       if (rst)
           aa <= {M{1'b0}};
       else if (load)
           aa <= A;
       else if (shift_r) begin
          if (aa[M-1] == 1'b1)
             aa <= {aa[M-2:0], 1'b0} ^ F;
          else 
             aa <= {aa[M-2:0], 1'b0};
        end
        Z <= aa;
    end
endmodule

//---------------------------------
// interleaved_mult
//---------------------------------

module interleaved_mult #(
    parameter M = 163,
    parameter logM = 7,
    parameter F = 163'h00000000000000000000000000000000000000C9
) (
    input  [M-1:0] A,
    input  [M-1:0] B,
    input  clk,
    input  rst,
    input  start,
    output reg [M-1:0] Z,
    output reg done
);
    reg load_done, shift_r;
    reg [logM:0] count;
    reg [M-1:0]  regB, regC;
    wire [M-1:0] regA;
    reg count_done;

    reg [1:0] current_state, next_state;
    parameter IDLE = 2'b00, LOAD = 2'b01, SHIFT = 2'b10, ST_DONE =2'b11;

    shift_reg #(
        .M(M),
        .F(F)
    ) u_shift_reg (
        .A(A),
        .clk(clk),
        .load(load_done),
        .shift_r(shift_r),
        .rst(rst),
        .Z(regA)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= {logM+1{1'b0}};
            count_done <= 1'b0;
            regC <= {M{1'b0}};
            regB <= {M{1'b0}};
        end else if (current_state == SHIFT) begin
            if (count == M) begin
                count <= {logM+1{1'b0}};
                count_done <= 1'b1;
            end else begin
                regB <= {1'b0, regB[M-1:1]};
                count <= count + 1;
                count_done <= 1'b0;
                if (regB[0] == 1'b1)
                    regC <= regC ^ regA;
                else
                    regC <= regC;
            end
        end else if (current_state == LOAD) begin
            regB <= B;
            regC <= {M{1'b0}};
            count <= {logM+1{1'b0}};
            count_done <= 1'b0;
        end 
    end

    //FSM process
    always @(*) begin
        case (current_state)
            IDLE: begin
                done <= 1'b0;
                shift_r <= 1'b0;
                load_done <= 1'b0;
            end
            LOAD: begin
                load_done <= 1'b1;
                shift_r <= 1'b0;
            end
            SHIFT: begin
                load_done <= 1'b0;
                shift_r <= 1'b1;
            end
            ST_DONE: begin
                done <= 1'b1;
                shift_r <= 1'b0;
            end
            default: begin
                load_done <= 1'b0;
                shift_r <= 1'b0;
                done <= 1'b0;
            end
        endcase
    end
    

    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
        end  

    always @(start or load_done or count_done) begin
        case (current_state)
            IDLE: begin
                if (start && !count_done)
                    next_state <= LOAD;
                else
                    next_state <= IDLE;
            end
            LOAD: begin
                if (load_done) 
                    next_state <= SHIFT;
                else
                    next_state <= LOAD;
            end
            SHIFT: begin
                if (count_done && start)
                    next_state <= ST_DONE;
                else 
                    next_state <= SHIFT;
            end
            ST_DONE: begin
                next_state <= IDLE;
            end
            default: next_state <= IDLE;
        endcase
    end

endmodule





