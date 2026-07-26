`timescale 1ns/1ps

module fifo_tb #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
);
    // ============= DUT + Interface ===============
    logic clk;

    fifo_if #(DATA_WIDTH) vif(clk);

    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk   (clk),
        .rst_n (vif.rst_n),
        .wr_en (vif.wr_en),
        .rd_en (vif.rd_en),
        .din   (vif.din),
        .dout  (vif.dout),
        .full  (vif.full),
        .empty (vif.empty)
    );
    // =====================================================


    // ========== Verification Components ==================
    fifo_monitor    #(DATA_WIDTH) mon;
    fifo_scoreboard #(DATA_WIDTH) scb;

    mailbox #(fifo_transaction #(DATA_WIDTH)) mon2scb;
    // =====================================================


    // ========= Verification Environment Setup ============
    initial begin
        mon2scb = new();

        mon = new(vif, mon2scb);
        scb = new(mon2scb);

        fork
            mon.run();
            scb.run();
        join_none
    end
    // =====================================================


    // ================== Clocking Initial =================
    initial begin
        clk = 0;
    end
    always #5 clk = ~clk;
    // =====================================================


    // ================== Common Tasks =====================
    // -------------------- RESETING -----------------------
    task automatic reset_dut();
        @(negedge vif.clk); 
        vif.rst_n = 0;
        vif.wr_en = 0;
        vif.rd_en = 0;
        vif.din   = 0;

        repeat(2) @(negedge vif.clk);
        vif.rst_n = 1;

        scb.reset_model();
    endtask
    // -----------------------------------------------------

    // -------------------- WRITE --------------------------
    task automatic write_data(
        input logic [DATA_WIDTH-1:0] data
    );
        @(negedge vif.clk);
        vif.wr_en = 1;
        vif.din   = data;

        @(negedge vif.clk);
        vif.wr_en = 0;
    endtask
    // -----------------------------------------------------

    // --------------------- READ --------------------------
    task automatic read_data();
        
        @(negedge vif.clk);
        vif.rd_en  = 1;
        
        @(negedge vif.clk);
        vif.rd_en  = 0;
    endtask
    // -----------------------------------------------------
    // =====================================================
 
    // ==================== Test Cases =====================
    
    task automatic tc1_basic_write_read(); 
        $display("------------------------------------------------------------");
        $display("             TEST CASE 1: BASIC WRITE & READ");
        $display("------------------------------------------------------------");    
        
        reset_dut();
        
        write_data(8'hBB);
        write_data(8'hAA);
        write_data(8'hCC);

        read_data();
        read_data();
        read_data();
    endtask

    task automatic tc2_empty_read();
        $display("------------------------------------------------------------");
        $display("             TEST CASE 2: EMPTY READ");
        $display("------------------------------------------------------------"); 

        reset_dut();

        write_data(8'hAA);

        read_data();
        read_data();
        
    endtask

    task automatic tc3_full_write();
        $display("------------------------------------------------------------");
        $display("             TEST CASE 3: FULL WRITE");
        $display("------------------------------------------------------------"); 

        reset_dut();

        for(int i = 0; i < 20; i++) begin
            $display("i = %0d", i);
            write_data($urandom);
        end
        
    endtask

    task automatic tc4_wrap_around();
    // Khi test độc lập thì chỉnh DEPTH = 4 cho test nhanh
        $display("------------------------------------------------------------");
        $display("             TEST CASE 4: WRAP AROUND");
        $display("------------------------------------------------------------"); 

        reset_dut();

        write_data("A");
        write_data("B");
        write_data("C");
        write_data("D");

        read_data();
        read_data();

        write_data("E");
        write_data("F");

        read_data();
        read_data();
        read_data();
        read_data();
    endtask

    task automatic tc5_simultaneous_rw();
        $display("------------------------------------------------------------");
        $display("             TEST CASE 5: Simultaneous READ / WRITE");
        $display("------------------------------------------------------------"); 

        reset_dut();

        @(negedge vif.clk);
        write_data(8'hAA);
        write_data(8'hBB);
        write_data(8'hCC);

        @(negedge vif.clk);         // Drive trực tiếp wr_en và rd_en thì mới có xung cùng lúc
        vif.din = 8'hDD;
        vif.wr_en = 1;
        vif.rd_en = 1;

        @(negedge vif.clk);
        vif.wr_en = 0;
        vif.rd_en = 0;

        @(negedge vif.clk);
        write_data(8'hDD);
        read_data();

    endtask

    task automatic tc6_async_rst();
        $display("------------------------------------------------------------");
        $display("             TEST CASE 6: ASYNCHRONOUS RESET");
        $display("------------------------------------------------------------"); 

        reset_dut();

        for(int i = 0; i < 20; i++) begin
            
           if (i % 3 == 0) begin
            $display("%0d.", i);
                read_data();
           end else begin
                write_data($urandom);
           end
           if (i == 13) begin
                #3;
                vif.rst_n = 0;
                scb.reset_model();

                #1;
                
                if(vif.empty && !vif.full)
                    $display("[PASS] ASYNC RESET: FIFO cleared immediately");
                else
                    $error("[FAIL] ASYNC RESET");

                #3;
                vif.rst_n = 1;
           end
        end
    endtask
    // =====================================================



    // ================= Test Execution =======================
    initial begin
        $display("");
        $display("============================================================");
        $display("                  SYNC FIFO VERIFICATION");
        $display("============================================================");
        $display("DATA_WIDTH = %0d", DATA_WIDTH);
        $display("DEPTH = %0d", DEPTH);
        $display("------------------------------------------------------------");
        $display("");
        #1;

        //tc1_basic_write_read();
        tc2_empty_read();
        //tc3_full_write();
        //tc4_wrap_around();
        //tc5_simultaneous_rw();
        //tc6_async_rst();

        @(negedge vif.clk);
        scb.report();
        $finish;
    end
    // ========================================================
endmodule