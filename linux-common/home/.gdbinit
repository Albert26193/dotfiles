# wh cmd + 20

set print pretty on
set print array-indexes on
set print object on

set history save on
set history filename ~/.gdb/gdb.history.log
set history remove-duplicates unlimited
set trace-commands on

set logging file ~/.gdb/gdb.log
set logging on

# set auto-load safe-path ~/.gdb
# set auto-load safe-path /usr
set auto-load safe-path /
set index-cache on

set print pretty
set follow-fork-mode child
set print elements 0

handle SIGPIPE nostop
handle SIGUSR1 nostop
handle SIGILL pass nostop noprint

source ~/.gdb/py/sqlengine-gdb.py
source ~/.gdb/std-gdb.gdbinit

python
import sys 
sys.path.insert(0, '/usr/share/gcc-8/python')
from libstdcxx.v6.printers import register_libstdcxx_printers
register_libstdcxx_printers (None)
end

# Comment out the following line to disable GEP
source /root/.local/share/GEP/gdbinit-gep.py

# set single-column-tab-complete on
