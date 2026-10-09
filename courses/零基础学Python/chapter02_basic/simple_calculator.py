# 计算两个整数的四则运算计算器

# var1 = 123
# var2 = 456
# var1 = var2
# var2 = 789
# print(var1)
# num1 = int(input("请输入第一个数字: "))
# num2 = int(input("请输入第二个数字: "))

num1 = input("请输入第一个数字: ")
num2 = input("请输入第二个数字: ")
op = input("请输入运算符")

sum = eval(f"{num1} {op} {num2}")
print(sum)
