from pathlib import Path
import csv,re,json,sys
root=Path.cwd(); out=root/'report/audit'; lines=list(csv.reader(open(root/'report/tables/need_formatting/02_gp_raw.txt'),delimiter='\t'))
expected={}; models=['ol_all','ol_raw','ol_index','ol_sfwp']
for i,row in enumerate(lines):
 if len(row)<5 or row[0] in ['', 'Observations','VARIABLES','Robust standard errors in parentheses']:continue
 for j,m in enumerate(models,1):
  if re.match(r'^-?\d+\.\d+',row[j]):
   b=float(re.sub(r'\*','',row[j]));se=float(lines[i+1][j].strip('()'))
   expected[m,row[0]]=(b,se)
gacc={'NO':2,'NR':3,'NW':4,'RM':5,'SO':6,'SW':7,'WB':8}
cause={'Lightning':2,'N/A':3,'Under Investigation':4};terrain={'Medium':2,'High':3,'Extreme':4}
def stata_name(t):
 if t.startswith('cut'):return 'Constant '+t
 if t.startswith('sfwp'):return t[4:]+'.sfwp'
 if t.startswith('gacc'):
  v=t[4:].split(':')[0];return str(gacc[v])+('.gacc1#c.doy_cos' if ':' in t else '.gacc1')
 if t.startswith('cause_descr'):return str(cause[t[11:]])+'.cause_desc1'
 if t.startswith('terrain'):return str(terrain[t[7:]])+'.terrain1'
 if t.startswith('year'):return t[4:]+'.year1'
 return t
rows=[]
for x in csv.DictReader(open(out/'gp-coefficients.csv')):
 t=stata_name(x['term']);b,se=expected[x['model'],t];got=float(x['estimate']);gs=float(x['se'])
 rows.append(dict(model=x['model'],term=t,expected=b,reproduced=got,difference=got-b,expected_se=se,reproduced_se=gs,se_difference=gs-se,tolerance=.0005,coefficient_match=abs(got-b)<=.0005,se_match=abs(gs-se)<=.0005))
with open(out/'stata-comparison.csv','w') as f:
 w=csv.DictWriter(f,rows[0],lineterminator="\n");w.writeheader();w.writerows(rows)
for m in models:
 a=[x for x in rows if x['model']==m];print(m,len(a),'coefficient matches',sum(x['coefficient_match'] for x in a),'SE matches',sum(x['se_match'] for x in a),'max errors',max(abs(x['difference']) for x in a),max(abs(x['se_difference']) for x in a))
for x in rows:
 if not x['coefficient_match'] or not x['se_match']:print('MISMATCH',x)
