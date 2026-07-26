// Transaction:
// Đại diện cho một "gói thông tin" của một thao tác ở mức trừu tượng cao,
// ví dụ: write/read và dữ liệu cần truyền.
// Transaction được các khối như Generator, Driver, Monitor trao đổi với nhau.
class fifo_transaction #(
    parameter DATA_WIDTH = 8
);
    rand bit                  wr_en;
    rand bit                  rd_en;
    rand bit [DATA_WIDTH-1:0] din; 
    logic    [DATA_WIDTH-1:0] dout; 
    // Ở đây bit ~ logic, nhưng bit {0, 1} còn logic {0, 1, X, Z} nên ta chọn random kiểu dữ liệu bit.

    function void print();
        if(wr_en)  
            $display("[WRITE] | wr_en = %0b | rd_en = %0b | din = 0x%0h", wr_en, rd_en, din);
        
        if (rd_en)
            $display("[READ] | wr_en = %0b | rd_en = %0b | dout = 0x%0h", wr_en, rd_en, dout);
    endfunction
    // Đây là bước đặt tên để mốt gọi display cho dễ, ko cần phải viết lại lệnh, chỉ cần: tr.print();
endclass