// Interface:
// Gom các tín hiệu liên quan lại để dễ kết nối,
// quản lý và truy xuất giữa DUT và testbench.

interface fifo_if #(
    parameter DATA_WIDTH = 8
)(
    input logic clk
);

    logic rst_n;

    logic wr_en;
    logic rd_en;

    logic [DATA_WIDTH-1:0] din;
    logic [DATA_WIDTH-1:0] dout;

    logic full;
    logic empty;

    logic wr_fire;
    logic rd_fire;


    // Một thao tác WRITE thực sự được FIFO chấp nhận
    assign wr_fire = wr_en && !full;

    // Một thao tác READ thực sự được FIFO chấp nhận
    assign rd_fire = rd_en && !empty;


    // Clocking block dùng cho Driver
    clocking cb @(posedge clk);

        // Testbench drive vào DUT
        output wr_en;
        output rd_en;
        output din;

        // Testbench quan sát từ DUT
        input full;
        input empty;
        input dout;

        // Tín hiệu trạng thái được tính toán
        input wr_fire;
        input rd_fire;

    endclocking

endinterface