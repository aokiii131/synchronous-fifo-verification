# SystemVerilog Interface & Clocking Block Notes

Ghi chú bài học cho project **Synchronous FIFO Design & Verification**.

## 1. `interface` là gì?

Trong testbench truyền thống, ta thường khai báo từng tín hiệu riêng lẻ:

```systemverilog
logic clk;
logic rst_n;
logic wr_en;
logic rd_en;
logic [7:0] din;
logic [7:0] dout;
logic full;
logic empty;
```

Sau đó nối từng tín hiệu vào DUT.

Khi testbench lớn dần và có nhiều thành phần như Driver, Monitor, Scoreboard, Assertions, việc quản lý từng tín hiệu rời rạc sẽ khó đọc và khó bảo trì.

SystemVerilog cung cấp `interface` để gom một nhóm tín hiệu liên quan vào cùng một khối:

```systemverilog
interface fifo_if #(
    parameter int DATA_WIDTH = 8
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

endinterface
```

Có thể hình dung:

```text
fifo_if
├── clk
├── rst_n
├── wr_en
├── rd_en
├── din
├── dout
├── full
└── empty
```

Thay vì quản lý nhiều tín hiệu rời, testbench có thể quản lý chúng thông qua một interface.

## 2. `interface` có giống `struct` trong C không?

Có thể hình dung **gần giống `struct` trong C**, vì cả hai đều gom nhiều thành phần liên quan lại với nhau.

Tuy nhiên, SystemVerilog `interface` mạnh hơn `struct` vì ngoài tín hiệu, nó còn có thể chứa:

- `clocking block`
- `modport`
- `task`
- `function`
- `assertion`

Vì vậy, có thể hiểu `interface` như một **gói giao tiếp phần cứng dùng chung giữa các thành phần verification**.

## 3. `_if`, instance interface và `vif`

`_if` chủ yếu là quy ước đặt tên.

```systemverilog
interface fifo_if;
```

`fifo_if` là tên kiểu interface.

Trong testbench top, ta có thể tạo một instance thật:

```systemverilog
logic clk;

fifo_if fifo_bus (
    .clk(clk)
);
```

`fifo_bus` là instance interface thật.

Trong class verification, ta thường thấy:

```systemverilog
virtual fifo_if vif;
```

`vif` thường viết tắt của `virtual interface`.

Có thể nhớ:

```text
fifo_if
= kiểu interface

fifo_bus
= instance interface thật

vif
= handle trong class trỏ tới interface thật
```

## 4. Tại sao `clk` khai báo khác?

Trong interface:

```systemverilog
interface fifo_if #(
    parameter int DATA_WIDTH = 8
)(
    input logic clk
);
```

`clk` được đưa vào interface từ bên ngoài vì clock thường được tạo trong testbench top.

```systemverilog
module sync_fifo_tb;

    logic clk;

    always #5 clk = ~clk;

    fifo_if fifo_bus (
        .clk(clk)
    );

endmodule
```

Luồng hoạt động:

```text
Testbench Top
    │
    │ tạo clk
    ▼
fifo_if nhận clk
    │
    ▼
Driver / Monitor / Clocking Block
dùng chung clock đó
```

## 5. `clocking block` là gì?

Sau khi gom tín hiệu vào interface, ta có thể thêm `clocking block`:

```systemverilog
clocking cb @(posedge clk);

    output wr_en;
    output rd_en;
    output din;

    input dout;
    input full;
    input empty;

endclocking
```

Toàn bộ interface:

```systemverilog
interface fifo_if #(
    parameter int DATA_WIDTH = 8
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

    clocking cb @(posedge clk);

        output wr_en;
        output rd_en;
        output din;

        input dout;
        input full;
        input empty;

    endclocking

endinterface
```

## 6. Ý nghĩa `input` và `output` trong clocking block

Phải nhìn theo **góc nhìn của testbench**.

```systemverilog
output wr_en;
output rd_en;
output din;
```

nghĩa là testbench sẽ **drive** các tín hiệu này tới DUT.

```text
TESTBENCH
    │
    │ wr_en, rd_en, din
    ▼
   DUT
```

Còn:

```systemverilog
input dout;
input full;
input empty;
```

nghĩa là testbench sẽ **sample / quan sát** các tín hiệu này từ DUT.

```text
   DUT
    │
    │ dout, full, empty
    ▼
TESTBENCH
```

Ghi nhớ:

```text
clocking block output
= TB gửi tín hiệu vào DUT

clocking block input
= TB đọc tín hiệu từ DUT
```

## 7. Tại sao cần clocking block?

Nếu không dùng clocking block, DUT và testbench có thể cùng hoạt động tại đúng một cạnh clock.

Ví dụ DUT:

```systemverilog
always_ff @(posedge clk) begin
    if (wr_en)
        mem[wr_ptr] <= din;
end
```

Testbench kiểu cũ:

```systemverilog
@(posedge clk);
wr_en = 1;
din   = 8'hAA;
```

Tại đúng `posedge clk`, cả DUT và testbench đều được đánh thức:

```text
            posedge clk
                │
        ┌───────┴───────┐
        ▼               ▼
       DUT              TB

   đọc wr_en        đổi wr_en = 1
```

Vấn đề là không muốn phụ thuộc vào việc DUT đọc trước hay TB đổi trước.

Hiện tượng kiểu này gọi là:

```text
Race Condition
```

## 8. Clocking block giúp giảm race condition như thế nào?

Clocking block xác định một mốc đồng bộ:

```systemverilog
clocking cb @(posedge clk);
```

Việc drive và sample tín hiệu của testbench được tổ chức quanh `posedge clk` theo cơ chế timing của SystemVerilog.

Thay vì Driver thao tác trực tiếp kiểu:

```systemverilog
@(posedge clk);
wr_en = 1;
```

sau này Driver có thể thao tác qua clocking block:

```systemverilog
@(vif.cb);
vif.cb.wr_en <= 1;
```

Monitor cũng đọc qua clocking block:

```systemverilog
dout = vif.cb.dout;
```

Có thể hình dung:

```text
                posedge clk
                    │
          ┌─────────┴─────────┐
          │                   │
        DUT             Clocking Block
                              │
                     quản lý thời điểm
                     drive / sample
```

Điều này giúp giảm các race condition giữa DUT và testbench liên quan tới việc drive/sample tín hiệu theo clock.

Lưu ý: clocking block không tự động loại bỏ mọi race condition trong simulation; nó giúp kiểm soát tốt phần giao tiếp giữa DUT và testbench khi dùng đúng cách.

## 9. Tại sao `rst_n` chưa đưa vào clocking block?

FIFO hiện tại dùng reset bất đồng bộ:

```systemverilog
always_ff @(posedge clk or negedge rst_n)
```

Reset có thể tác động mà không cần chờ `posedge clk`.

Vì vậy trong project hiện tại, ta có thể điều khiển reset trực tiếp:

```systemverilog
fifo_bus.rst_n = 0;
```

thay vì đi qua clocking block.

## 10. Vai trò của interface trong môi trường verification

```text
                 fifo_if
        ┌───────────────────────┐
        │ clk                   │
        │ rst_n                 │
        │ wr_en                 │
        │ rd_en                 │
        │ din                   │
        │ dout                  │
        │ full                  │
        │ empty                 │
        │                       │
        │ clocking block cb     │
        └───────────┬───────────┘
                    │
        ┌───────────┼───────────┐
        ▼           ▼           ▼
     Driver        DUT       Monitor
```

Driver dùng interface để drive:

```text
wr_en
rd_en
din
```

Monitor dùng interface để quan sát:

```text
dout
full
empty
```

Cả hai dùng chung clock.


## 11. Ghi nhớ nhanh

```text
interface
→ Gom các tín hiệu liên quan vào cùng một khối.

fifo_if
→ Tên kiểu interface.

fifo_bus
→ Instance thật của interface trong testbench.

virtual fifo_if vif
→ Handle để class truy cập interface thật.

clocking block
→ Quản lý cách TB drive và sample tín hiệu quanh cạnh clock.

clocking block output
→ TB drive tín hiệu tới DUT.

clocking block input
→ TB sample tín hiệu từ DUT.
```

Mục tiêu chính:

```text
Tổ chức testbench sạch hơn
+
Dễ kết nối Driver / Monitor
+
Giảm nguy cơ race condition giữa DUT và TB
```
