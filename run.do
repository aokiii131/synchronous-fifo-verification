# cd D:/Project/Summer_Project/synchronous-fifo-verification/

# =========================================================
# 0. Dọn simulation cũ
# =========================================================

quit -sim

# Xóa hoàn toàn thư viện work cũ
if {[file exists work]} {
    vdel -all -lib work
}

# =========================================================
# 1. Tạo lại work library
# =========================================================

vlib work
vmap work work

# =========================================================
# 2. Compile RTL
# =========================================================



# =========================================================
# 3. Compile Testbench
# =========================================================
vlog -sv rtl/sync_fifo.sv
vlog -sv tb/fifo_if.sv

vlog -sv -mfcu \
    tb/fifo_transaction.sv \
    tb/fifo_monitor.sv \
    tb/fifo_scoreboard.sv \
    tb/fifo_tb.sv

# =========================================================
# 4. Start simulation
# =========================================================

vsim -voptargs="+acc" work.fifo_tb

# =========================================================
# 5. Add waveform
# =========================================================

add wave -radix hex -position insertpoint sim:/fifo_tb/*

# =========================================================
# 6. Run
# =========================================================

run -all