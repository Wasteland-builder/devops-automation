# # def enroll(name, gender, age=6, city="Beijing"):
# #     print("name:", name)
# #     print("gender:", gender)
# #     print("age:", age)
# #     print("city:", city)


# # enroll("Bob", "M")


# # 定义默认参数要牢记一点：默认参数必须指向不变的对象！
# # def add_end(L=[]):
# #     L.append("END")
# #     return L
# def add_end(L=None):
#     if L is None:
#         L = []
#     L.append("END")
#     return L


# print(add_end([1, 2]))
# print(add_end())
# print(add_end())


# # 可变参数
# def calc(*numbers):
#     sum = 0
#     for n in numbers:
#         sum = sum + n * n
#     return sum


# nums = [1, 2, 3]

# print(calc(1, 2))
# print(calc())
# # *nums表示把nums这个list的所有元素作为可变参数传进去
# print(calc(*nums))


# #  关键字参数
# def person(name, age, **kw):
#     print("name:", name, "age:", age, "other:", kw)


# person("Bob", 35, city="Beijing")
# person("Adam", 45)

# def mul(x, y):
#     return x * y


def mul(*args):
    result = 1
    if len(args) == 0:
        raise TypeError("mul() 缺少参数，至少需要传入一个数字")
    for arg in args:
        result = result * arg
    return result


print("mul(5) =", mul(5))
print("mul(5, 6) =", mul(5, 6))
print("mul(5, 6, 7) =", mul(5, 6, 7))
print("mul(5, 6, 7, 9) =", mul(5, 6, 7, 9))
if mul(5) != 5:
    print("mul(5)测试失败!")
elif mul(5, 6) != 30:
    print("mul(5, 6)测试失败!")
elif mul(5, 6, 7) != 210:
    print("mul(5, 6, 7)测试失败!")
elif mul(5, 6, 7, 9) != 1890:
    print("mul(5, 6, 7, 9)测试失败!")
else:
    try:
        mul()
        print("mul()测试失败!")
    except TypeError:
        print("测试成功!")
