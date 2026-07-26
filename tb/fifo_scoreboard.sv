class fifo_scoreboard #(
    parameter DATA_WIDTH = 8
);

    mailbox #(fifo_transaction #(DATA_WIDTH)) mon2scb;

    logic [DATA_WIDTH-1:0] ref_queue[$];
    logic [DATA_WIDTH-1:0] expected;
    
    int mismatch_count = 0;
    int write_count    = 0;
    int read_count       = 0;
    int pass_count     = 0; 
    
    function new(
        mailbox #(fifo_transaction #(DATA_WIDTH)) mon2scb
    );
        this.mon2scb = mon2scb;
    endfunction

    function void reset_model();
        ref_queue.delete();
    endfunction

    task run();
        fifo_transaction #(DATA_WIDTH) tr;

        forever begin

            mon2scb.get(tr);

            if (tr.wr_en) begin
                write_count++;

                ref_queue.push_back(tr.din);
                $display(
                    "[WRITE] time=%0t | data = 0x%0h | queue_size = %0d",
                    $time,
                    tr.din,
                    ref_queue.size()
                );
                $display("-----------------------------------------");
            end

            if (tr.rd_en) begin

                read_count++;
                // Phát hiện ScoreBoard mất đồng bộ với DUT
                if (ref_queue.size() == 0) begin
                    $error("[ERROR] time=%0t | Valid read detected but reference queue is empty!", $time);
                end
                else begin

                    expected = ref_queue.pop_front();

                    if (expected !== tr.dout) begin
                        mismatch_count++;
                        $error(
                            "[FAIL] time=%0t | expected = 0x%0h | actual = 0x%0h",
                            $time,
                            expected,
                            tr.dout
                        );
                        $display("-----------------------------------------");
                    end

                    else begin
                        pass_count++;

                        $display(
                            "[PASS] time=%0t | expected = 0x%0h | actual = 0x%0h",
                            $time,
                            expected,
                            tr.dout
                        );
                        $display("-----------------------------------------");
                    end
                end
            end

        end
    endtask

    function void report();

        $display("");
        $display("============================================================");
        $display("                    TEST SUMMARY");
        $display("============================================================");
        $display("Writes      : %0d", write_count);
        $display("Reads       : %0d", read_count);
        $display("Passed      : %0d", pass_count);
        $display("Mismatches  : %0d", mismatch_count);
        $display("Queue.size  : %0d", ref_queue.size());
        $display("Ref Queue   : %p", ref_queue);
        $display("------------------------------------------------------------");

        if (mismatch_count == 0)
            $display("RESULT      : TEST PASSED");
        else
            $display("RESULT      : TEST FAILED");

        $display("============================================================");

    endfunction
endclass