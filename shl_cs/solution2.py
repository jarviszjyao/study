import sys


def max_consecutive_run(s: str) -> int:
    if not s:
        return 0
    best = cur = 1
    for i in range(1, len(s)):
        if s[i] == s[i - 1]:
            cur += 1
            if cur > best:
                best = cur
        else:
            cur = 1
    return best


def _is_bin(s: str) -> bool:
    return bool(s) and all(c in "01" for c in s)


def to_bitstring(tokens: list[str]) -> str:
    if not tokens:
        return ""
    if len(tokens) >= 2:
        a, b = tokens[0], tokens[1]
        rest = "".join(tokens[1:])
        if a.isdigit() and _is_bin(rest) and (not _is_bin(a) or int(a) == len(rest)):
            return rest
        if len(tokens) == 2 and _is_bin(a) and b.isdigit() and not _is_bin(b):
            return a
    raw = tokens[-1]
    if raw and _is_bin(raw):
        return raw
    n = int(raw)
    return bin(n)[2:] if n > 0 else "0"


def main() -> None:
    t = sys.stdin.read().split()
    if not t:
        return
    print(max_consecutive_run(to_bitstring(t)))


if __name__ == "__main__":
    main()
