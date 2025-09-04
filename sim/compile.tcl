set TARGET [lindex $argv 0]
set TB [lindex $argv 1]
set src_files [glob ../../${TARGET}/src/*.sv ../../${TARGET}/src/*.v]
set tb_files [glob ../../${TARGET}/tb/*.sv ../../${TARGET}/tb/*.v]

exec xvlog -sv {*}$src_files {*}$tb_files

## elab
exec xelab ${TB} -debug typical -log compile.log

