# ~/.gdbinit.d/auto_stamp.py
import datetime as dt
import gdb

# 把原来的 execute 函数保存起来
_original_execute = gdb.execute

def _execute_with_stamp(cmd, *args, **kw):
    # 打印时间戳（不换行，方便与命令输出对齐）
    print("[{}]".format(dt.datetime.now().strftime("%H:%M:%S.%f")[:-3]), end=" ")
    return _original_execute(cmd, *args, **kw)

# 替换掉 gdb.execute
gdb.execute = _execute_with_stamp
