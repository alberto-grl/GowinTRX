# GowinTRX

This would possibly become a direct sampling RX with a SI5351 controlled TX for digital modes.
Right now it is Verilog borrowed from fpga_rx, Lattice MachXO2, ported to Sipeed Tang Primer 20K.
Audio out in first commit is from PWM of a GPIO.
Next steps:
- Use Tang audio DAC
- Add to Litex SOC, with Vexriscv MPU, Etherbone, SD, I2C
- Add Si5351+amp, audio in frequency detection through saturated GPIO. Borrow from H750RTX
- Add 10 bit RF ADC instead of 1 bit
- Add riscv code for encoder, some UI. Borrow from H750RTX
