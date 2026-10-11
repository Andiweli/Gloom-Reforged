"""Bounded observation of the permanent-reply failure, not an OS exit test.
Usage: python tests/phase2_p96.py DLL game.hunk bench.hunk
"""
import ctypes,sys
from pathlib import Path
from asm_regression import *

def tests(dll,path,cpu):
    for missing in ['safe','disp']:
        c=CPU(dll,path,cpu);c.w16(c.addr('p96gameplay_dbuf_active'),65535)
        for key in ['safe','disp']:
            c.w16(c.addr('p96gameplay_dbuf_'+key+'_pending'),65535)
            c.w32(c.addr('p96gameplay_dbuf_'+key+'port'),0x310000 if key=='safe' else 0x320000)
        for key,value in [('sb0',0x340000),('sb1',0x350000)]:c.w32(c.addr('p96gameplay_dbuf_'+key),value)
        c.w32(c.addr('p96gameplay_intbase'),INTUITION);c.w32(c.addr('p96gameplay_grbase'),GRAPHICS)
        polls={'safe':0,'disp':0};freed=[]
        def getmsg(c):
            key='safe' if c.get(A0)==0x310000 else 'disp';polls[key]+=1
            c.ret(0 if key==missing else (0x330000 if polls[key]==1 else 0))
        c.hook(EXEC-372,getmsg)
        c.hook(GRAPHICS-270,lambda c:c.ret())
        for addr in [INTUITION-774,INTUITION-66,EXEC-672,EXEC-210,GRAPHICS-228]:
            c.hook(addr,lambda c:(freed.append(c.get(PC)),c.ret()))
        c.set(A7,STACK);c.w32(STACK,STOP);c.set(PC,c.addr('g2p96_gameplay_dbuf_free'))
        for _ in range(100000):
            pc=c.get(PC);assert pc!=STOP
            if pc in c.hooks:c.hooks[pc](c)
            else:assert BASE<=pc<BASE+len(c.code);dll.test_step()
        assert polls[missing]>100 and not freed and not dll.test_faults()
        assert c.r16(c.addr('p96gameplay_dbuf_active'))==65535
        assert c.r16(c.addr('p96gameplay_dbuf_'+missing+'_pending'))==65535
        assert c.r32(c.addr('p96gameplay_dbuf_sb1'))==0x350000
        assert c.r32(c.addr('p96gameplay_dbuf_'+missing+'port')) in [0x310000,0x320000]
    print(Path(path).name,'CPU',cpu,': 2 missing-reply observations passed; exit remains blocked')
    return 2

if __name__=='__main__':
    dll=ctypes.CDLL(str(Path(sys.argv[1]).absolute()));dll.test_get.restype=ctypes.c_uint
    print(sum(tests(dll,p,cpu) for p in sys.argv[2:] for cpu in [4,6,9]),'observations passed')
