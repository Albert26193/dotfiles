# wh cmd + 20

# 
# Basic setting
# 
set print pretty on
set print array-indexes on
set print object on

set history save on
set history filename ~/.gdb/gdb.history.log
set history remove-duplicates unlimited
set trace-commands on

# set logging file ~/.gdb/gdb.log
# set logging on
# set auto-load safe-path ~/.gdb
# set auto-load safe-path /usr
set auto-load safe-path /
set index-cache enabled on

set print pretty
set follow-fork-mode child
set print elements 0

# pager
set pagination on
set height 40

handle SIGPIPE nostop
handle SIGUSR1 nostop
handle SIGILL pass nostop noprint

# 
# Source scripts
# 
source ~/.gdb/py/sqlengine-gdb.py
source ~/.gdb/std-gdb.gdbinit
source /root/.local/share/GEP/gdbinit-gep.py

# 
# Python
# 
python
import sys 
import os 
sys.path.insert(0, '/usr/share/gcc-8/python')
from libstdcxx.v6.printers import register_libstdcxx_printers
register_libstdcxx_printers (None)
# gdb logger
sys.path.insert(0, os.path.expanduser("~/.gdb/py"))
import gdb_logger
import shared_printer
end

# 
# Alias
# 
alias a = advance
alias fi = finish
