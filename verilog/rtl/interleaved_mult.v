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


module shift_reg (
   input  [162:0] A,
   input  clk,
   input  load,
   input  shift_r,
   input  rst,
   output reg [162:0] Z
); 
   reg [162:0] aa;
   

   always @(posedge clk or posedge rst) begin
       if (rst)
           aa <= 0;
       else if (load)
           aa <= A;
       else if (shift_r) begin
          if (aa[162]) begin
            aa <= (aa << 1) ^ 8'hC9;
          end else begin
            aa <= aa << 1;
          end
        end
        Z <= aa;
    end
endmodule

//---------------------------------
// interleaved_mult
//---------------------------------

module interleaved_mult #(
    parameter M = 163
    // parameter logM = 7,
    // parameter F = 163'h00000000000000000000000000000000000000C9
) (
    input  [162:0] A,
    input  [162:0] B,
    input  clk,
    input  rst,
    input  start,
    output reg [162:0] Z,
    output wire done
);
    reg load_done, shift_r;
    reg [7:0] count;
    reg [162:0]  regB, regC;
    wire [162:0] regA;
    reg count_done;

    reg [1:0] current_state, next_state;
    parameter IDLE = 2'b00, LOAD = 2'b01, SHIFT = 2'b10, ST_DONE =2'b11;
    assign done = (current_state == ST_DONE) ? 1'b1 : 1'b0;
    shift_reg u_shift_reg (
        .A(A),
        .clk(clk),
        .load(load_done),
        .shift_r(shift_r),
        .rst(rst),
        .Z(regA)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            count_done <= 1'b0;
            regC <= 0;
            regB <= 0;
        end else if (current_state == SHIFT) begin
            if (count == M) begin
                count <= 0;
                count_done <= 1'b1;
            end else begin
                regB <= 0;
                count <= count + 1;
                count_done <= 1'b0;
                if (regB[0] == 1'b1)
                    regC <= regC ^ regA;
                else
                    regC <= regC;
            end
        end else if (current_state == LOAD) begin
            regB <= B;
            regC <= 0;
            count <= 0;
            count_done <= 1'b0;
        end 
    end

    //FSM process
    always @(*) begin
        case (current_state)
            IDLE: begin
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
                shift_r <= 1'b0;
            end
            default: begin
                load_done <= 1'b0;
                shift_r <= 1'b0;
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




