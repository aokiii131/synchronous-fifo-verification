# cd D:/Project/Summer_Project/synchronous-fifo-verification/

vlog -sv tb/fifo_if.sv
vlog -sv rtl/sync_fifo.sv
vlog -sv tb/queue_test.sv
vlog -sv tb/sync_fifo_tb.sv

vsim sync_fifo_tb
run -all