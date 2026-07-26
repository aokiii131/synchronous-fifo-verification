`timescale 1ns/1ps

module queue_test(fifo_if vif);
    logic [7:0] ref_queue[$];
    logic [7:0] expected;


    always @(posedge vif.clk) begin
        
        if(vif.wr_fire) begin
            ref_queue.push_back(vif.din);
            $display("WRITE: %d | queue = %p", vif.din, ref_queue);
        end

        if(vif.rd_fire) begin
                expected = ref_queue.pop_front();

                #1; // wait for vif.dout to update

                if (expected !== vif.dout) 
                    $error("FAIL: expected = %d | vif.dout = %d", expected, vif.dout);
                else
                    $display("PASS: expected = vif.dout = %0d", vif.dout);
        end
        $display("------------------------");

    end
endmodule