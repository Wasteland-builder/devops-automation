# 一、 故障现象

- **前台报错：**运营终端登录后页面提示会话已失效，请重新登录
- **业务影响：** 
  - 柜台无法使用
  - 受影响的服务器 IP/主机名：`10.118.193.154`

# 二、 处理过程

## 1. 分析报错

1、1、进入F12开发者模式，复现问题，查看哪个请求报401（Herders）
2、将Herders下General中的Request URL路径复制
3、在OTS库中进行查询：
	A： 查不到数据

```sql
SELECT t.* ,t.rowid FROM tsys_subtrans t where rel_url = ''; 
```

​	B：查出两条记录

```sql
SELECT t.* ,t.rowid FROM tsys_subtrans_relurl t where url = ''';
```

4、根据SUB_TRANS_CODE可查询菜单：

```sql
select * from TSYS_SUBTRANS t where t.SUB_TRANS_CODE in ('bsfunctions','otsfunctions','gtinvestmanager','searchtradeaccoinfo')；
```

可查到需要的接口权限，发现缺少勾选交易柜台公共接口权限，勾选上即可