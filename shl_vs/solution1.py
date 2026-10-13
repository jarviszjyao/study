import sys

data = sys.stdin.read().strip().split()
if not data:
    sys.exit()

if data[0].lstrip('-').isdigit():
    n = int(data[0]) if data[0].lstrip('-').isdigit() else 0
    names = data[1:1+n]
else:
    names = data

names = [s.lower() for s in names if s]
if not names:
    sys.exit()

pref = names[0]
for s in names[1:]:
    i = 0
    m = min(len(pref), len(s))
    while i < m and pref[i] == s[i]:
        i += 1
    pref = pref[:i]
    if not pref:
        break

if pref:
    print(pref)
