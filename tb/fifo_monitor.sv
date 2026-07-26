// Monitor:
// Quan sát sự thay đổi các tín hiệu trong khối DUT thông qua interface
// Thu thập và ghi lại các hoạt động của DUT và chuyển chúng thành thông tin (dưới dạng Transaction)
// để gửi sang Scoreboard kiểm tra.
class fifo_monitor#(
    parameter DATA_WIDTH = 8
);
    // Handle để Monitor truy cập vào if
    virtual fifo_if #(DATA_WIDTH) vif;
    
    mailbox #(fifo_transaction #(DATA_WIDTH)) mon2scb;            // Monitor to Scoreboard mailbox

    // Khối Constructor: Nhận if từ bên ngoài
    function new(
        virtual fifo_if #(DATA_WIDTH) vif,
        mailbox #(fifo_transaction #(DATA_WIDTH)) mon2scb
    );
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction

    task run();
        fifo_transaction #(DATA_WIDTH) tr;

        forever begin

            @(vif.cb);

            tr = new();

            tr.wr_en = 0;
            tr.rd_en = 0;

            // WRITE thực sự được DUT chấp nhận
            if (vif.cb.wr_fire) begin
                tr.wr_en = 1;
                tr.din   = vif.din;
            end

            // READ thực sự được DUT chấp nhận
            if (vif.cb.rd_fire) begin
                tr.rd_en = 1;

                // Chờ DUT cập nhật dout
                @(negedge vif.clk);
                tr.dout = vif.dout;
            end

            if (tr.wr_en || tr.rd_en) begin
                tr.print();
                mon2scb.put(tr);
            end

        end
endtask
endclass