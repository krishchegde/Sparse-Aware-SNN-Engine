`timescale 1ns/1ps

module csr_snn_engine #(
    parameter NUM_ROWS = 4,
    parameter NNZ = 7,
    parameter signed [31:0] THRESHOLD = 6,
    parameter signed [31:0] LEAK = 1
)(
    input wire clk,
    input wire rst,
    input wire start,

    // Four input spikes
    input wire [3:0] spike_vector,

    // Learning enable
    input wire learn_en,

    // Output neuron spikes
    output reg [3:0] neuron_spikes,

    // Membrane potentials
    output reg signed [31:0] v0,
    output reg signed [31:0] v1,
    output reg signed [31:0] v2,
    output reg signed [31:0] v3,

    output reg done,
    output wire busy
);

    // ============================================
    // CSR CONFIGURATION
    // ============================================

    reg signed [15:0] values [0:NNZ-1];
    reg [1:0] col_index [0:NNZ-1];
    reg [2:0] row_ptr [0:NUM_ROWS];

    // Row ownership of each nonzero weight
    reg [1:0] row_of_entry [0:NNZ-1];

    // ============================================
    // NEURON MEMORY
    // ============================================

    reg signed [31:0] membrane [0:NUM_ROWS-1];

    reg [3:0] spike_out_reg;

    // ============================================
    // FSM STATES
    // ============================================

    localparam IDLE     = 4'd0;
    localparam LOAD_ROW = 4'd1;
    localparam CHECK    = 4'd2;
    localparam ACCUM    = 4'd3;
    localparam ADVANCE  = 4'd4;
    localparam STORE    = 4'd5;
    localparam NEXT_ROW = 4'd6;
    localparam UPDATE   = 4'd7;
    localparam FINISH   = 4'd8;

    reg [3:0] state;

    // ============================================
    // CONTROLLER REGISTERS
    // ============================================

    reg [2:0] row_idx;
    reg [3:0] idx;
    reg [3:0] row_end;

    reg signed [31:0] accumulator;
    reg signed [31:0] next_mem;

    reg [3:0] update_idx;

    integer i;

    // ============================================
    // CSR INITIALIZATION
    // ============================================

    initial begin

        // Synaptic weights
        values[0] = 16'sd1;
        values[1] = 16'sd2;
        values[2] = 16'sd3;
        values[3] = 16'sd4;
        values[4] = 16'sd5;
        values[5] = 16'sd6;
        values[6] = 16'sd7;

        // Column indices
        col_index[0] = 2'd0;
        col_index[1] = 2'd2;
        col_index[2] = 2'd1;
        col_index[3] = 2'd3;
        col_index[4] = 2'd0;
        col_index[5] = 2'd1;
        col_index[6] = 2'd2;

        // Row pointers
        row_ptr[0] = 3'd0;
        row_ptr[1] = 3'd2;
        row_ptr[2] = 3'd4;
        row_ptr[3] = 3'd5;
        row_ptr[4] = 3'd7;

        // Row ownership
        row_of_entry[0] = 2'd0;
        row_of_entry[1] = 2'd0;

        row_of_entry[2] = 2'd1;
        row_of_entry[3] = 2'd1;

        row_of_entry[4] = 2'd2;

        row_of_entry[5] = 2'd3;
        row_of_entry[6] = 2'd3;

    end

    // ============================================
    // BUSY
    // ============================================

    assign busy = (state != IDLE);

    // ============================================
    // MAIN FSM
    // ============================================

    always @(posedge clk) begin

        if (rst) begin

            state <= IDLE;

            row_idx <= 0;
            idx <= 0;
            row_end <= 0;

            accumulator <= 0;
            next_mem <= 0;

            update_idx <= 0;

            neuron_spikes <= 0;
            spike_out_reg <= 0;

            v0 <= 0;
            v1 <= 0;
            v2 <= 0;
            v3 <= 0;

            for (i = 0; i < NUM_ROWS; i = i + 1)
                membrane[i] <= 0;

            done <= 0;

        end

        else begin

            // Default completion pulse
            done <= 0;

            case (state)

                // =================================
                // IDLE
                // =================================

                IDLE: begin

                    if (start) begin

                        row_idx <= 0;
                        spike_out_reg <= 0;

                        state <= LOAD_ROW;

                    end

                end

                // =================================
                // LOAD ROW
                // =================================

                LOAD_ROW: begin

                    idx <= row_ptr[row_idx];
                    row_end <= row_ptr[row_idx + 1'b1];

                    accumulator <= 0;

                    state <= CHECK;

                end

                // =================================
                // CHECK INPUT SPIKE
                // =================================

                CHECK: begin

                    if (idx >= row_end) begin

                        state <= STORE;

                    end

                    else if (spike_vector[col_index[idx]]) begin

                        state <= ACCUM;

                    end

                    else begin

                        state <= ADVANCE;

                    end

                end

                // =================================
                // ACCUMULATE WEIGHT
                // =================================

                ACCUM: begin

                    accumulator <= accumulator +
                        {{16{values[idx][15]}}, values[idx]};

                    state <= ADVANCE;

                end

                // =================================
                // ADVANCE CSR INDEX
                // =================================

                ADVANCE: begin

                    idx <= idx + 1'b1;

                    state <= CHECK;

                end

                // =================================
                // LIF NEURON UPDATE
                // =================================

                STORE: begin

                    // Apply leak
                    if (membrane[row_idx] > LEAK)
                        next_mem = membrane[row_idx] - LEAK;
                    else
                        next_mem = 0;

                    // Integrate synaptic input
                    next_mem = next_mem + accumulator;

                    // Threshold detection
                    if (next_mem >= THRESHOLD) begin

                        membrane[row_idx] <= 0;

                        spike_out_reg[row_idx] <= 1'b1;

                    end

                    else begin

                        membrane[row_idx] <= next_mem;

                        spike_out_reg[row_idx] <= 1'b0;

                    end

                    state <= NEXT_ROW;

                end

                // =================================
                // NEXT ROW
                // =================================

                NEXT_ROW: begin

                    if (row_idx == NUM_ROWS - 1) begin

                        update_idx <= 0;

                        state <= UPDATE;

                    end

                    else begin

                        row_idx <= row_idx + 1'b1;

                        state <= LOAD_ROW;

                    end

                end

                // =================================
                // LEARNING ENGINE
                // =================================

                UPDATE: begin

                    if (learn_en && update_idx < NNZ) begin

                        // Pre-synaptic and post-synaptic
                        // spike coincidence strengthens weight.

                        if (spike_vector[col_index[update_idx]] &&
                            spike_out_reg[row_of_entry[update_idx]]) begin

                            if (values[update_idx] < 16'sd32767)
                                values[update_idx] <=
                                    values[update_idx] + 1'b1;

                        end

                        // Active input without output spike
                        // weakens the weight.

                        else if (spike_vector[col_index[update_idx]] &&
                            !spike_out_reg[row_of_entry[update_idx]]) begin

                            if (values[update_idx] > -17'sd32768)
                                values[update_idx] <=
                                    values[update_idx] - 1'b1;

                        end

                        update_idx <= update_idx + 1'b1;

                    end

                    else begin

                        state <= FINISH;

                    end

                end

                // =================================
                // FINISH
                // =================================

                FINISH: begin

                    neuron_spikes <= spike_out_reg;

                    v0 <= membrane[0];
                    v1 <= membrane[1];
                    v2 <= membrane[2];
                    v3 <= membrane[3];

                    done <= 1'b1;

                    state <= IDLE;

                end

                default: begin

                    state <= IDLE;

                end

            endcase

        end

    end

endmodule
