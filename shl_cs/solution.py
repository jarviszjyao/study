import sys


def longest_common_prefix(strings: list[str]) -> str:
    if not strings:
        return ""
    base = strings[0]
    for i, ch in enumerate(base):
        for s in strings[1:]:
            if i >= len(s) or s[i] != ch:
                return base[:i]
    return base


def main() -> None:
    data = sys.stdin.read().split()
    if not data:
        return
    n = int(data[0])
    names = [data[i + 1].lower() for i in range(n)]
    lcp = longest_common_prefix(names)
    if lcp:
        print(lcp)


if __name__ == "__main__":
    main()
