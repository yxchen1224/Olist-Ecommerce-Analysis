
import pandas as pd
from pathlib import Path

# 1. 获取项目根目录
BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"

# 2. 读取订单和客户数据
orders = pd.read_csv(DATA_DIR / "olist_orders_dataset.csv")
customers = pd.read_csv(DATA_DIR / "olist_customers_dataset.csv")

# 3. 转换购买时间
orders["order_purchase_timestamp"] = pd.to_datetime(
    orders["order_purchase_timestamp"],
    errors="coerce"
)

# 4. 关联真实客户ID
customer_orders = orders.merge(
    customers[["customer_id", "customer_unique_id"]],
    on="customer_id",
    how="left"
)

# 5. 按真实客户和购买时间排序
customer_orders = customer_orders.sort_values(
    ["customer_unique_id", "order_purchase_timestamp"]
)

# 6. 计算同一客户相邻两次购买的时间间隔
customer_orders["purchase_interval"] = (
    customer_orders.groupby("customer_unique_id")
    ["order_purchase_timestamp"].diff()
)

# 7. 将时间间隔转换为天数
customer_orders["interval_days"] = (
    customer_orders["purchase_interval"].dt.total_seconds()
    / 86400
)

# 8. 提取有效的复购间隔
interval_data = customer_orders.dropna(
    subset=["interval_days"]
).copy()

# 9. 筛选小于1天的短间隔记录
short_intervals = interval_data[
    interval_data["interval_days"] < 1
].copy()

# 10. 输出整体检查结果
print("\n整体复购间隔记录数：", len(interval_data))

print("小于1天的间隔记录数：", len(short_intervals))

print(
    "涉及的真实客户数：",
    short_intervals["customer_unique_id"].nunique()
)

print(
    "恰好为0天的记录数：",
    (short_intervals["interval_days"] == 0).sum()
)

# 11. 查看短间隔记录的分布
print("\n短间隔记录统计：")
print(short_intervals["interval_days"].describe())

# 12. 查看部分具体记录
print("\n短间隔记录示例：")
print(
    short_intervals[
        [
            "customer_unique_id",
            "order_id",
            "order_purchase_timestamp",
            "interval_days"
        ]
    ].head(20).to_string(index=False)
)

# 13. 保存短间隔记录
output_path = BASE_DIR / "short_interval_records.csv"

short_intervals.to_csv(
    output_path,
    index=False,
    encoding="utf-8-sig"
)

print("\n短间隔记录已保存到：", output_path)
