import gdb

class PPSharedPtr(gdb.Command):
    """pp <shared_ptr> — print the object pointed to by a std::shared_ptr"""
    def __init__(self):
        super(PPSharedPtr, self).__init__("pp", gdb.COMMAND_USER)

    def invoke(self, arg, from_tty):
        # arg is the name or expression for the shared_ptr
        if not arg:
            print("Usage: pp <shared_ptr>")
            return
        try:
            val = gdb.parse_and_eval(arg)
            # try common libstdc++ member
            ptr = val["_M_ptr"]
        except Exception:
            try:
                ptr = val["__shared_ptr_"]["_M_ptr"]
            except Exception:
                print("pp: cannot find internal _M_ptr for", arg)
                return
        if ptr == 0:
            print(arg, "is null")
        else:
            gdb.execute("p *%s" % (arg + "._M_ptr"))

# register command
PPSharedPtr()
