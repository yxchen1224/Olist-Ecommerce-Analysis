
import pandas as pd
from pathlib import Path

# 1. 获取项目根目录和数据文件夹
BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"

# 2. 读取订单表和客户表
orders = pd.read_csv(DATA_DIR / "olist_orders_dataset.csv")
customers = pd.read_csv(DATA_DIR / "olist_customers_dataset.csv")


# 3. 将订单时间转换为日期时间格式
orders["order_purchase_timestamp"] = pd.to_datetime(
    orders["order_purchase_timestamp"],
    errors="coerce"
)

# 4. 将真实客户编号合并到订单表
customer_orders = orders.merge(
    customers[["customer_id", "customer_unique_id"]],
    on="customer_id",
    how="left"
)

# 5. 统计每位真实客户的订单数量
customer_order_counts = (
    customer_orders
    .groupby("customer_unique_id")["order_id"]
    .nunique()
)

# 6. 区分一次性客户和复购客户
one_time_customers = (customer_order_counts == 1).sum()
repeat_customers = (customer_order_counts > 1).sum()
total_customers = customer_order_counts.index.nunique()

# 7. 计算整体复购率
repeat_rate = repeat_customers / total_customers

print("===== 客户复购分析 =====")
print("真实客户总数：", total_customers)
print("一次性客户数：", one_time_customers)
print("复购客户数：", repeat_customers)
print(f"整体复购率：{repeat_rate:.2%}")

# 8. 查看每位客户的订单数量分布
print("\n===== 客户订单数量分布 =====")
print(customer_order_counts.value_counts().sort_index())

# 9. 按客户和购买时间排序
customer_orders = customer_orders.dropna(
    subset=["customer_unique_id", "order_purchase_timestamp"]
).sort_values(
    ["customer_unique_id", "order_purchase_timestamp"]
)

# 10. 计算同一客户相邻两次购买的时间间隔
customer_orders["purchase_interval"] = (
    customer_orders
    .groupby("customer_unique_id")["order_purchase_timestamp"]
    .diff()
)

# 11. 将时间间隔转换成天数
interval_days = (
    customer_orders["purchase_interval"]
    .dropna()
    .dt.total_seconds()
    / 86400
)

# 12. 统计购买间隔
print("\n===== 客户购买间隔分析 =====")
print("有效购买间隔数量：", len(interval_days))
print(f"平均购买间隔：{interval_days.mean():.2f} 天")
print(f"中位数：{interval_days.median():.2f} 天")
print(f"P75：{interval_days.quantile(0.75):.2f} 天")
print(f"P90：{interval_days.quantile(0.90):.2f} 天")
print(f"最短间隔：{interval_days.min():.2f} 天")
print(f"最长间隔：{interval_days.max():.2f} 天")
print("同一天内的购买间隔数量：", (interval_days == 0).sum())




