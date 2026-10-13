import sys, re

data = sys.stdin.read().strip().split()
if not data:
    sys.exit()

def is_bin(x: str) -> bool:
    return bool(x) and all(c in '01' for c in x)

joined = ''.join(data)
if is_bin(joined):
    s = joined
else:
    # prefer any token that's a pure binary token
    s = None
    for t in data:
        if is_bin(t):
            s = t
            break
    if s is None:
        # if first token is an integer and the rest form a binary string, use rest
        if data[0].lstrip('-').isdigit():
            rest = ''.join(data[1:])
            if is_bin(rest) and (len(data) > 1):
                s = rest
            else:
                try:
                    s = bin(int(data[0]))[2:]
                except Exception:
                    s = ''.join(ch for ch in joined if ch in '01')
        else:
            # fallback: try to parse last token as integer, else extract bits
            try:
                s = bin(int(data[-1]))[2:]
            except Exception:
                s = ''.join(ch for ch in joined if ch in '01')

if not s:
    sys.exit()

print(max(map(len, re.findall(r'0+|1+', s))))
