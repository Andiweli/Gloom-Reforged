Gloom_BuildWrapper v6-long-branch-relax-selfcheck

Ziel:
- GloomAmiga unter MSYS mit vasmm68k_mot und vlink bauen.
- Originalquellen bleiben unverändert.
- Der Wrapper erzeugt vasm-kompatible Zwischenquellen in build_vasm/.

Benötigt:
- MSYS/UCRT64 Shell
- vasmm68k_mot im PATH
- vlink im PATH
- python3 im PATH

Anwendung im GloomAmiga Repo-Ordner:

rm -rf tools build_vasm Gloom_BuildWrapper
unzip -o /pfad/zu/Gloom_BuildWrapper_v6.zip
bash Gloom_BuildWrapper/apply_msys.sh
./build_msys.sh

Erwartete Versionszeilen:

Checking wrapper version...
OK: v6-long-branch-relax-selfcheck

Normalized gloom.s -> build_vasm/gloom.s [v6-long-branch-relax-selfcheck] (...)

Was der Normalizer macht:
- verwaiste Devpac-elseif-Marker werden kommentiert
- echte if/elseif/endc-Blöcke bleiben erhalten
- 68020-Branches bsr/bra/bcc und Varianten werden explizit als .l ausgegeben

Hinweis:
Dieses Paket ist bewusst ein BuildWrapper. Es patcht nicht die Originaldateien im Repository.
