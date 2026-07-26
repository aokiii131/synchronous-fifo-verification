// Driver:
// Nhận thông tin trừu tượng từ Transaction,
// rồi chuyển thành tín hiệu cụ thể trên interface để đưa vào DUT.
class fifo_driver #(
    parameter DATA_WIDTH = 8
);
    // Handle để Driver truy cập interface thật
    virtual fifo_if #(DATA_WIDTH) vif;

    // Constructor: nhận interface từ bên ngoài
    // và lưu nó vào vif của Driver (tạo kết nối dây cho Driver và interface)
    function new (virtual fifo_if #(DATA_WIDTH) vif);
        this.vif = vif;                                 // vif (Phải) là if được truyền vào trong khối constructor (function new(..))
                                                        // vif (Trái) là vif giữ trong driver
    endfunction

    // Nhận transaction và drive dữ liệu ra interface
    task drive (fifo_transaction #(DATA_WIDTH) tr);
        @(vif.cb);

        vif.cb.wr_en <= tr.wr_en;
        vif.cb.rd_en <= tr.rd_en;
        vif.cb.din   <= tr.din;
    endtask

endclass