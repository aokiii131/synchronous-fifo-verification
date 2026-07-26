
module sync_fifo #(
    parameter int DATA_WIDTH = 8,                       // Tùy chỉnh độ rộng data  (8/16/32/64-bit)
    parameter int DEPTH      = 16                       // Tùy chỉnh số lượng ô nhớ của FIFO, có thể override.
)(
    input  logic                            clk,        
    input  logic                            rst_n,

    input  logic                            wr_en,
    input  logic                            rd_en,

    input  logic    [DATA_WIDTH-1:0]        din,
    output logic    [DATA_WIDTH-1:0]        dout,

    output logic                            full,
    output logic                            empty
);
    localparam int ADDR_WIDTH = $clog2(DEPTH);          // Là hằng số nội bộ của module
                                                        // Không thể ghi đè (override) từ bên ngoài
                                                        // Ở đây nó chỉ số lượng bit cần để biểu diễn địa chỉ các ô nhớ của FIFO

    logic   [DATA_WIDTH-1:0] mem [0:DEPTH-1];           // Khai báo bộ ô nhớ

    logic   [ADDR_WIDTH:0]                  count;      // Theo dõi số lượng phần tử hiện đang có trong FIFO
    logic   [ADDR_WIDTH-1:0]                wr_ptr;
    logic   [ADDR_WIDTH-1:0]                rd_ptr;

    logic                                   wr_fire; 
    logic                                   rd_fire;

    assign wr_fire = wr_en && !full;                    // 1 Lần WRITE thực sự được chấp nhận
    assign rd_fire = rd_en && !empty;                   // 1 Lần  READ thực sự được chấp nhận

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin                                // Reset các biến nội bộ module và chỉ output dout
            wr_ptr <= 0;
            rd_ptr <= 0;
            dout   <= 0;
            count  <= 0;
        end

        else begin
            case({wr_fire, rd_fire})     // Điều khiển biến đếm count
                2'b10:      count <= count + 1;         // Write không Read
                2'b01:      count <= count - 1;         // Read không Write
                default:    count <= count;             // Vừa Read vừa Write hoặc không làm gì cả
            endcase
            
            if (wr_fire) begin
                mem[wr_ptr] <= din;
                wr_ptr      <= wr_ptr + 1;
            end

            if(rd_fire) begin
                dout        <= mem[rd_ptr];
                rd_ptr      <= rd_ptr + 1;
            end 
        end
    end

    assign full  = (count == DEPTH);                    // Báo full khi FIFO đang chứa đủ DEPTH phần tử
    assign empty = (count == 0);                        // Báo empty khi count giảm về 0 (Không còn gì để đọc)

endmodule