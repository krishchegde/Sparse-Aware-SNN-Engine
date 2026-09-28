`timescale 1ns/1ps

module tb_csr_snn_engine;

    reg clk;
    reg rst;
    reg start;

    reg [3:0] spike_vector;
    reg learn_en;

    wire [3:0] neuron_spikes;

    wire signed [31:0] v0;
    wire signed [31:0] v1;
    wire signed [31:0] v2;
    wire signed [31:0] v3;

    wire done;
    wire busy;

    integer errors;

    // ============================================
    // DUT
    // ============================================

    csr_snn_engine uut (

        .clk(clk),
        .rst(rst),
        .start(start),

        .spike_vector(spike_vector),
        .learn_en(learn_en),

        .neuron_spikes(neuron_spikes),

        .v0(v0),
        .v1(v1),
        .v2(v2),
        .v3(v3),

        .done(done),
        .busy(busy)

    );

    // ============================================
    // CLOCK
    // ============================================

    always #5 clk = ~clk;

    // ============================================
    // TASK: RUN ONE TIMESTEP
    // ============================================

    task run_step;
        input [3:0] input_spikes;

        begin

            @(negedge clk);

            spike_vector = input_spikes;
            start = 1'b1;

            @(negedge clk);

            start = 1'b0;

            wait(done == 1'b1);

            #1;

            $display("");
            $display("================================");
            $display("INPUT SPIKES  = %b", input_spikes);
            $display("OUTPUT SPIKES = %b", neuron_spikes);

            $display("V0 = %0d", v0);
            $display("V1 = %0d", v1);
            $display("V2 = %0d", v2);
            $display("V3 = %0d", v3);

            $display("================================");

            @(negedge clk);

        end

    endtask

    // ============================================
    // TASK: CHECK RESULTS
    // ============================================

    task check_results;
        input [3:0] expected_spikes;
        input integer expected_v0;
        input integer expected_v1;
        input integer expected_v2;
        input integer expected_v3;

        begin

            if (neuron_spikes !== expected_spikes ||
                v0 !== expected_v0 ||
                v1 !== expected_v1 ||
                v2 !== expected_v2 ||
                v3 !== expected_v3) begin

                $display("TEST FAILED");

                $display("Expected spikes = %b", expected_spikes);

                errors = errors + 1;

            end

            else begin

                $display("TEST PASSED");

            end

        end

    endtask

    // ============================================
    // MAIN TEST
    // ============================================

    initial begin

        clk = 0;
        rst = 1;

        start = 0;
        spike_vector = 0;

        learn_en = 0;
        errors = 0;

        // ----------------------------------------
        // RESET
        // ----------------------------------------

        repeat (2) @(negedge clk);

        rst = 0;

        // ----------------------------------------
        // STEP 1
        // ----------------------------------------

        $display("");
        $display("TEST 1: INITIAL SPIKE PROPAGATION");

        run_step(4'b0101);

        check_results(
            4'b1000,
            3,
            0,
            5,
            0
        );

        // ----------------------------------------
        // STEP 2
        // ----------------------------------------

        $display("");
        $display("TEST 2: MEMBRANE LEAK");

        run_step(4'b0000);

        check_results(
            4'b0000,
            2,
            0,
            4,
            0
        );

        // ----------------------------------------
        // STEP 3
        // ----------------------------------------

        $display("");
        $display("TEST 3: THRESHOLD CROSSING");

        run_step(4'b0101);

        check_results(
    4'b1100,
    4,
    0,
    0,
    0
);

        // ----------------------------------------
        // STEP 4
        // ----------------------------------------

        $display("");
        $display("TEST 4: NEURON RESET AFTER FIRING");

        run_step(4'b0000);

        check_results(
            4'b0000,
            3,
            0,
            0,
            0
        );

        // ----------------------------------------
        // STEP 5
        // ----------------------------------------

        $display("");
        $display("TEST 5: LEARNING ENABLED");

        learn_en = 1'b1;

        run_step(4'b0101);

        $display("Learning cycle completed.");

        // ----------------------------------------
        // FINAL RESULT
        // ----------------------------------------

        $display("");
        $display("================================");

        if (errors == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED: %0d", errors);

        $display("================================");

        $finish;

    end

endmodule
