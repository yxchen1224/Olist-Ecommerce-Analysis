
import pandas as pd
from pathlib import Path

# 1. 获取项目根目录
BASE_DIR = Path(__file__).resolve().parent.parent

# 2. 读取第五个脚本保存的短间隔分析数据
DATA_DIR = BASE_DIR / "data"

orders = pd.read_csv(DATA_DIR / "olist_orders_dataset.csv")
customers = pd.read_csv(DATA_DIR / "olist_customers_dataset.csv")

# 3. 重新计算完整的客户购买间隔
orders["order_purchase_timestamp"] = pd.to_datetime(
    orders["order_purchase_timestamp"],
    errors="coerce"
)

customer_orders = orders.merge(
    customers[["customer_id", "customer_unique_id"]],
    on="customer_id",
    how="left"
)

customer_orders = customer_orders.sort_values(
    ["customer_unique_id", "order_purchase_timestamp"]
)

customer_orders["interval_days"] = (
    customer_orders.groupby("customer_unique_id")
    ["order_purchase_timestamp"].diff().dt.total_seconds()
    / 86400
)

intervals = customer_orders["interval_days"].dropna()

# 4. 方案A：保留全部复购间隔
all_stats = intervals.describe(
    percentiles=[0.25, 0.50, 0.75, 0.90]
)

# 5. 方案B：排除小于1天的复购间隔
filtered_intervals = intervals[intervals >= 1]

filtered_stats = filtered_intervals.describe(
    percentiles=[0.25, 0.50, 0.75, 0.90]
)

# 6. 汇总两种方案
comparison = pd.DataFrame({
    "保留全部间隔": all_stats,
    "排除小于1天": filtered_stats
})

print("\n两种方案的复购间隔对比（单位：天）：")
print(comparison.round(2))

print("\n记录数量对比：")
print("方案A：", len(intervals))
print("方案B：", len(filtered_intervals))
print("排除记录数：", len(intervals) - len(filtered_intervals))

# 7. 保存对比结果
output_path = BASE_DIR / "interval_sensitivity.csv"

comparison.to_csv(
    output_path,
    encoding="utf-8-sig"
)

print("\n对比结果已保存到：", output_path)

