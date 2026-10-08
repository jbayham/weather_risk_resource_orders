"""Check new branch history and current diff for excluded publication artifacts.
This complements human diff review; it is not a general secret/data classifier.
"""
import os, re, subprocess, sys
from pathlib import Path
os.chdir(Path(__file__).resolve().parents[1])
base = sys.argv[1] if len(sys.argv)>1 else 'origin/master'
def git(*args):
    return subprocess.check_output(['git',*args],text=True)
changed=set(git('diff','--name-only',base).splitlines())
history=set(git('log','--format=','--name-only',f'{base}..HEAD').splitlines())
paths=changed | history | set(git("ls-files","--others","--exclude-standard").splitlines())
bad=[]
for name in sorted(paths):
    if not name: continue
    p=Path(name)
    if p.suffix.lower() in {'.pdf','.docx','.accdb','.dta','.rdata','.rds','.xlsx'}:
        bad.append(f'Excluded document/data artifact: {name}')
    if name.startswith(('paper/','audit-output/','audit-library/','build/inputs/','analysis/inputs/')):
        bad.append(f'Excluded path: {name}')
    if p.suffix.lower()=='.png' and not name.startswith('report/audit/figures/'):
        bad.append(f'New image outside generated audit figures: {name}')
    if not p.is_file() or p.suffix.lower()=='.png': continue
    text=p.read_text(errors='replace')
    if re.search(r'/(?:Users|home)/[A-Za-z0-9._-]+/',text):
        bad.append(f'Personal absolute path: {name}')
    if re.search(r'gh[pousr]_[A-Za-z0-9]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----',text):
        bad.append(f'Possible credential: {name}')
if bad:
    raise SystemExit('\n'.join(bad))
print(f'Publication scope check passed for {len(paths-{chr(10),""})} changed/history paths.')
