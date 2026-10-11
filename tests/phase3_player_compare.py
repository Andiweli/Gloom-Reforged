"""Compare the initialized embedded MED CODE with the Phase 2 binary.
Usage: python tests/phase3_player_compare.py DLL old-game new-game new-bench
Only HUNK relocations and the two documented cold-entry patches are masked.
"""
import ctypes,hashlib,struct,sys
from pathlib import Path
from phase3_med import Player
from phase2_kernel_compare import relocations

if __name__=='__main__':
 dll=ctypes.CDLL(str(Path(sys.argv[1]).absolute()));dll.test_get.restype=ctypes.c_uint
 asset=Path(__file__).parents[1]/'source/medplay'
 size=struct.unpack_from('>I',asset.read_bytes(),28)[0]*4
 masks=[(off,off+4) for off in relocations(asset)]+[(0x50,0x56),(0xe98,0xea2)]
 images=[]
 for index,path in enumerate(sys.argv[2:]):
  p=Player(dll,path,4,patched=index!=0)
  code=bytearray(p.c.bytes(p.base,size))
  for start,end in masks:code[start:end]=bytes(end-start)
  images.append(bytes(code))
  assert images[-1]==images[0],(path,'embedded player changed beyond cold patches')
  print(Path(path).name,size,'MED CODE bytes agree after relocation/16 cold patch bytes are masked;',hashlib.sha256(code).hexdigest())
