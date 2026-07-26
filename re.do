# 1. Chỉ biên dịch lại các file (không cần vlib/vmap nữa)
# =========================================================
# 2. Compile RTL
# =========================================================

vlog -sv rtl/sync_fifo.sv

# =========================================================
# 3. Compile Testbench
# =========================================================

vlog -sv tb/fifo_if.sv

vlog -sv -mfcu \
    tb/fifo_transaction.sv \
    tb/fifo_monitor.sv \
    tb/fifo_scoreboard.sv \
    tb/fifo_tb.sv


# 2. Restart mô phỏng, giữ nguyên cửa sổ Wave hiện tại (-f để ép buộc không hỏi lại)
restart -f

# 3. Chạy lại mô phỏng với dữ liệu mới
run -all