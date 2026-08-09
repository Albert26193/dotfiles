import datetime, pathlib, gdb

_LOG_DIR = pathlib.Path.home() / ".gdb/logs"
_LOG_DIR.mkdir(exist_ok=True)
_LOG_FILE = _LOG_DIR / f"{datetime.date.today().isoformat()}.log"

def start(overwrite=True):
    # gdb.execute("set pagination on")
    # gdb.execute("set logging enabled " + ("on" if overwrite else "off"))
    gdb.execute("set logging enabled off")
    gdb.execute(f"set logging file {_LOG_FILE}")
    gdb.execute("set logging enabled on")
    # gdb.execute("set logging overwrite off")
    gdb.execute("set trace-commands on")
    #  3. 每次提示符出现后强制刷新日志
    # gdb.execute("define hookpost-post-prompt\n set logging flush on")
    gdb.write(f"[gdb-log] logging → {_LOG_FILE}  (flush-on-prompt)\n")

def stop():
    gdb.execute("set logging off")

# 自动开始
start()

