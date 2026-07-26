# Parameterization Notes for Synchronous FIFO

Tài liệu ghi chú nhanh về cách tham số hóa module trong SystemVerilog, dùng trực tiếp cho project `Synchronous FIFO Verification`.

## 1. Mục tiêu

Thay vì viết FIFO cố định:

- Depth = 16
- Data width = 8 bit

Ta sẽ viết FIFO có thể tái sử dụng:

```systemverilog
module sync_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
)(
    // ports
);
```

Cấu hình mặc định vẫn là FIFO **16 x 8**:

- `DEPTH = 16`: có 16 vị trí lưu dữ liệu.
- `DATA_WIDTH = 8`: mỗi vị trí lưu 8 bit.
- Tổng dung lượng lưu dữ liệu: `16 x 8 = 128 bit`.

---

## 2. `parameter` là gì?

`parameter` là một hằng số có thể thay đổi khi module được instantiate.

```systemverilog
module sync_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
)(
    input logic clk
);
```

Ở đây `DATA_WIDTH = 8` và `DEPTH = 16` là giá trị mặc định.

Có thể override khi instantiate:

```systemverilog
sync_fifo #(
    .DATA_WIDTH(16),
    .DEPTH(32)
) dut (
    .clk(clk)
);
```

Khi đó FIFO có 32 vị trí nhớ, mỗi vị trí 16 bit.

---

## 3. Cú pháp `#(...)`

Phần:

```systemverilog
#(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
)
```

là **parameter list** của module.

Cấu trúc tổng quát:

```systemverilog
module module_name #(
    parameter int PARAMETER_1 = default_value,
    parameter int PARAMETER_2 = default_value
)(
    // port list
);
```

Ví dụ:

```systemverilog
module sync_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  wr_en,
    input  logic                  rd_en,
    input  logic [DATA_WIDTH-1:0] din,
    output logic [DATA_WIDTH-1:0] dout,
    output logic                  full,
    output logic                  empty
);
```

Nếu `DATA_WIDTH = 8`:

```systemverilog
logic [7:0] din;
```

Nếu `DATA_WIDTH = 16`:

```systemverilog
logic [15:0] din;
```

---

## 4. `localparam` là gì?



`localparam` là hằng số nội bộ của module và không được override từ bên ngoài.

Ví dụ:

```systemverilog
localparam int ADDR_WIDTH = $clog2(DEPTH);
```

Nếu:

```text
DEPTH = 16
```

thì:

```text
ADDR_WIDTH = 4
```

và pointer có thể khai báo:

```systemverilog
logic [ADDR_WIDTH-1:0] wr_ptr;
logic [ADDR_WIDTH-1:0] rd_ptr;
```

---

## 5. `$clog2()` là gì?

`$clog2(N)` cho số bit cần thiết để đánh địa chỉ theo kích thước tương ứng.

Ví dụ:

```systemverilog
$clog2(16) = 4
$clog2(8)  = 3
$clog2(32) = 5
```

Trong FIFO:

```systemverilog
localparam int ADDR_WIDTH = $clog2(DEPTH);
```

giúp độ rộng pointer tự thay đổi theo `DEPTH`.

---

## 6. Tham số hóa memory

FIFO cố định:

```systemverilog
logic [7:0] mem [0:15];
```

FIFO tham số hóa:

```systemverilog
logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
```

Với cấu hình mặc định:

```text
DATA_WIDTH = 8
DEPTH = 16
```

nó tương đương:

```systemverilog
logic [7:0] mem [0:15];
```

---

## 7. Khung RTL FIFO tham số hóa ban đầu

Đây chỉ là **khung khai báo**, chưa phải RTL hoàn chỉnh:

```systemverilog
module sync_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  wr_en,
    input  logic                  rd_en,

    input  logic [DATA_WIDTH-1:0] din,
    output logic [DATA_WIDTH-1:0] dout,

    output logic                  full,
    output logic                  empty
);

    localparam int ADDR_WIDTH = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    logic [ADDR_WIDTH-1:0] wr_ptr;
    logic [ADDR_WIDTH-1:0] rd_ptr;

    // Tiếp theo sẽ thêm:
    // - count
    // - full / empty logic
    // - write logic
    // - read logic

endmodule
```

---

## 8. Cách instantiate FIFO

### Dùng cấu hình mặc định 16 x 8

```systemverilog
sync_fifo dut (
    .clk   (clk),
    .rst_n (rst_n),
    .wr_en (wr_en),
    .rd_en (rd_en),
    .din   (din),
    .dout  (dout),
    .full  (full),
    .empty (empty)
);
```

Không ghi `#(...)` thì dùng cấu hình mặc định.

### Override cấu hình

Ví dụ FIFO 32 x 16:

```systemverilog
sync_fifo #(
    .DATA_WIDTH(16),
    .DEPTH(32)
) dut (
    .clk   (clk),
    .rst_n (rst_n),
    .wr_en (wr_en),
    .rd_en (rd_en),
    .din   (din),
    .dout  (dout),
    .full  (full),
    .empty (empty)
);
```

---

## 9. `parameter` và `localparam`

| Loại | Có thể override từ bên ngoài? | Dùng cho |
|---|---|---|
| `parameter` | Có | Cấu hình module |
| `localparam` | Không | Hằng số nội bộ được suy ra |

Trong FIFO:

```systemverilog
parameter int DATA_WIDTH = 8;
parameter int DEPTH      = 16;
```

là cấu hình người dùng có thể chọn.

Còn:

```systemverilog
localparam int ADDR_WIDTH = $clog2(DEPTH);
```

là giá trị nội bộ được FIFO tự tính.

---

## 10. Cấu hình project hiện tại

```text
Type       : Synchronous FIFO
DATA_WIDTH : 8 bits
DEPTH      : 16 entries
Reset      : Active-low asynchronous reset
Read       : Synchronous
Write      : Synchronous
```

Mục tiêu RTL:

```text
Parameterized Synchronous FIFO
        |
        +-- DATA_WIDTH
        +-- DEPTH
        +-- auto-calculated ADDR_WIDTH
        +-- parameterized memory
        +-- write pointer
        +-- read pointer
        +-- count
        +-- full / empty
```

Sau khi RTL ổn định, trọng tâm project chuyển sang:

```text
Scoreboard
Random Test
Assertions
Corner Cases
```

---

## 11. Ghi nhớ nhanh

```systemverilog
parameter
```

→ cấu hình từ bên ngoài.

```systemverilog
localparam
```

→ hằng số nội bộ.

```systemverilog
#(...)
```

→ nơi khai báo hoặc truyền parameter.

```systemverilog
$clog2()
```

→ tính số bit cần thiết.

Ví dụ cốt lõi:

```systemverilog
module sync_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
);

    localparam int ADDR_WIDTH = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

endmodule
```