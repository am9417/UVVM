# Run this script in this xsim subfolder
# xvhdl, xelab and xsim should be in the path

# Compile dependencies
.\compile_xsim.ps1 uvvm_util
.\compile_xsim.ps1 uvvm_vvc_framework
.\compile_xsim.ps1 bitvis_vip_scoreboard
.\compile_xsim.ps1 bitvis_vip_sbi
.\compile_xsim.ps1 bitvis_vip_uart
.\compile_xsim.ps1 bitvis_vip_clock_generator
.\compile_xsim.ps1 bitvis_uart

# Compile demo TB
xvhdl -v 2 --2019 -work bitvis_uart ..\bitvis_uart\tb\uart_vvc_demo_th.vhd
xvhdl -v 2 --2019 -work bitvis_uart ..\bitvis_uart\tb\uart_vvc_demo_tb.vhd

# Elaborate and run
xelab -v 2 bitvis_uart.uart_vvc_demo_tb
xsim -stats -nosignalhandlers --R bitvis_uart.uart_vvc_demo_tb