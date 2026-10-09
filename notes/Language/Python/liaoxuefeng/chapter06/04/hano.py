# def move(n, a, b, c):
#     if n == 1:
#         print(a, "-->", c)
#     else:
#         move(n - 1, a, c, b)
#         move(1, a, b, c)
#         move(n - 1, b, a, c)


def move(n, a, b, c, depth=0):
    indent = "  " * depth
    print(f"{indent}开始: n={n}, a={a}, b={b}, c={c}")
    if n == 1:
        print(f"{indent}>>> 执行: {a} --> {c}")
    else:
        move(n - 1, a, c, b, depth + 1)
        print(f"{indent}>>> 执行: {a} --> {c}")
        move(n - 1, b, a, c, depth + 1)


move(3, "A", "B", "C")
