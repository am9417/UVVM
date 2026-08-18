# Tcl script for compiling and running the UART demo simulation
# Source this in the Vivado Tcl console:
#   source compile_uart_demo_simple.tcl

proc _get_script_dir {} {
    if {[catch {info script} s]} {
        return [file normalize [pwd]]
    } else {
        return [file normalize [file dirname $s]]
    }
}

proc run_cmd {cmd} {
    puts "Running: [join $cmd " "]"
    if {[catch {eval exec $cmd} result]} {
        puts "ERROR: $result"
        error $result
    }
}

proc compile_library {lib_name} {
    global repo_dir script_dir

    set lib_dir [file normalize [file join $repo_dir $lib_name]]
    set compile_order_file [file normalize [file join $lib_dir script compile_order.txt]]
    if {![file exists $compile_order_file]} {
        error "Missing compile order file: $compile_order_file"
    }

    set fh [open $compile_order_file r]
    set lines [split [read $fh] "\n"]
    close $fh

    set stamp_file [file normalize [file join $script_dir "$lib_name.compiled"]]
    set needs_compile 1
    if {[file exists $stamp_file]} {
        set stamp_time [file mtime $stamp_file]
        set needs_compile 0

        if {[file exists $compile_order_file] && [expr {[file mtime $compile_order_file] > $stamp_time}]} {
            set needs_compile 1
        }

        foreach line $lines {
            set trimmed [string trim $line]
            if {$trimmed eq "" || [string match "#*" $trimmed]} {
                continue
            }

            set src_path [file normalize [file join $lib_dir script $line]]
            if {![file exists $src_path]} {
                error "Missing source file: $src_path"
            }
            if {[file mtime $src_path] > $stamp_time} {
                set needs_compile 1
                break
            }
        }
    }

    if {!$needs_compile} {
        puts "Skipping $lib_name; sources are unchanged"
        return
    }

    set target_lib ""
    foreach line $lines {
        set trimmed [string trim $line]
        if {$trimmed eq "" || [string match "#*" $trimmed]} {
            if {[string match "# library *" $trimmed]} {
                set target_lib [lindex [split $trimmed] 2]
            }
            continue
        }

        set src_path [file normalize [file join $lib_dir script $line]]
        if {![file exists $src_path]} {
            error "Missing source file: $src_path"
        }

        puts "Compiling $src_path into work library $target_lib"
        run_cmd [list xvhdl -v 2 --2008 -work $target_lib $src_path]
    }

    set fh [open $stamp_file w]
    close $fh
}

set script_dir [_get_script_dir]
cd $script_dir
set repo_dir [file normalize [file join $script_dir ..]]

set libs {uvvm_util uvvm_vvc_framework bitvis_vip_scoreboard bitvis_vip_sbi bitvis_vip_uart bitvis_vip_clock_generator bitvis_uart}
foreach lib $libs {
    compile_library $lib
}

set th_vhd [file normalize [file join $repo_dir bitvis_uart tb uart_vvc_demo_th.vhd]]
set tb_vhd [file normalize [file join $repo_dir bitvis_uart tb uart_vvc_demo_tb.vhd]]

puts "Compiling demo testbench sources..."
run_cmd [list xvhdl -v 2 --2008 -work bitvis_uart $th_vhd]
run_cmd [list xvhdl -v 2 --2008 -work bitvis_uart $tb_vhd]

puts "Elaborating and launching simulation..."
run_cmd [list xelab -v 2 --debug all bitvis_uart.uart_vvc_demo_tb]
run_cmd [list xsim -gui -nosignalhandlers bitvis_uart.uart_vvc_demo_tb]
