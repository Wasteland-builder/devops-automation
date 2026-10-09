# 一开始的代码没有考虑到空字符串的情况，所以需要做一个判断
def trim(s):
    if s == "":
        return s
    while s and s[0] == " ":
        s = s[1:]
    while s and s[-1] == " ":
        s = s[:-1]
    return s


# 测试:
if trim("hello  ") != "hello":
    print("测试失败!")
elif trim("  hello") != "hello":
    print("测试失败!")
elif trim("  hello  ") != "hello":
    print("测试失败!")
elif trim("  hello  world  ") != "hello  world":
    print("测试失败!")
elif trim("") != "":
    print("测试失败!")
elif trim("    ") != "":
    print("测试失败!")
else:
    print("测试成功!")
