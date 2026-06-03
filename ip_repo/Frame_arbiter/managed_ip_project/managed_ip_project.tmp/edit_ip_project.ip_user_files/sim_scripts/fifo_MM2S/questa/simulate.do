onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib fifo_MM2S_opt

do {wave.do}

view wave
view structure
view signals

do {fifo_MM2S.udo}

run -all

quit -force
