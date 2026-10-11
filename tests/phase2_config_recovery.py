"""Recover across interrupted AmigaDOS Rename stages. Filesystem is modelled.
Usage: python tests/phase2_config_recovery.py DLL game.hunk bench.hunk
"""
import ctypes,sys
from pathlib import Path
from asm_regression import *

def tests(dll,path,cpu):
    count=0
    # Recover after interruption between Rename(old,backup) and Rename(tmp,new),
    # including a different task address and unreadable/existing targets.
    for state in ['before','gap','installed','absent','lock_error','race']:
        c=CPU(dll,path,cpu);io=ConfigDOS(c);backup=io.name+'.g2bak';tmp=io.name+'.g200112233.tmp'
        if state in ['gap','installed','race']:io.files[backup]=io.old;io.files[tmp]=io.new
        if state in ['gap','absent','race']:io.files.pop(io.name,None)
        if state=='installed':io.files[io.name]=io.new
        if state=='lock_error':io.fault='lock';io.files[backup]=io.old
        if state=='race':
            rename=io.rename
            def racing(c):io.files[io.name]=io.new;rename(c)
            c.hook(DOS-78,racing)
        c.w32(EXEC+276,0x445566);result=c.run('g2config_recover')
        if state=='gap':assert result==0 and io.files[io.name]==io.old
        elif state=='absent':assert io.name not in io.files
        elif state in ['installed','race']:assert io.files[io.name]==io.new
        else:assert io.files[io.name]==io.old
        if state in ['installed','lock_error','race']:assert io.files[backup]==io.old
        assert not io.opens and not io.closes;count+=1
    # Halt at every completed write/close/rename stage, restart with the file
    # state only, and require that any restored target is a whole old/new file.
    class Interrupted(Exception):pass
    for operation in ['write','close','rename1','rename2','delete']:
        c=CPU(dll,path,cpu);io=ConfigDOS(c)
        name=operation if not operation.startswith('rename') else 'rename';method=getattr(io,name)
        def stop(c,method=method):
            method(c)
            if not operation.startswith('rename') or io.renames==int(operation[-1]):raise Interrupted()
        off={'write':-48,'close':-36,'rename':-78,'delete':-72}[name];c.hook(DOS+off,stop)
        try:c.run('g2save_config_checked');raise AssertionError('interruption hook not reached')
        except Interrupted:pass
        files=io.files.copy();c=CPU(dll,path,cpu);restart=ConfigDOS(c);restart.files=files
        c.w32(EXEC+276,0x778899);c.run('g2config_recover')
        assert restart.files[restart.name] in [restart.old,restart.new],operation;count+=1
    print(Path(path).name,'CPU',cpu,':',count,'config recovery fault-injection cases passed')
    return count
if __name__=='__main__':
    dll=ctypes.CDLL(str(Path(sys.argv[1]).absolute()));dll.test_get.restype=ctypes.c_uint
    total=sum(tests(dll,path,cpu) for path in sys.argv[2:] for cpu in [4,6,9])
    print(total,'config recovery instruction cases passed; OS/filesystem calls modelled')
