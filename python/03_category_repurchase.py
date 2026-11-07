
import pandas as pd
from pathlib import Path

# 1. 获取项目根目录和数据文件夹
BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"

# 2. 读取需要使用的数据表
orders = pd.read_csv(DATA_DIR / "olist_orders_dataset.csv")
order_items = pd.read_csv(DATA_DIR / "olist_order_items_dataset.csv")
customers = pd.read_csv(DATA_DIR / "olist_customers_dataset.csv")
products = pd.read_csv(DATA_DIR / "olist_products_dataset.csv")

# 3. 转换订单购买时间
orders["order_purchase_timestamp"] = pd.to_datetime(
    orders["order_purchase_timestamp"],
    errors="coerce"
)

# 4. 关联订单和真实客户ID
customer_orders = orders.merge(
    customers[["customer_id", "customer_unique_id"]],
    on="customer_id",
    how="left"
)

# 5. 关联订单商品和商品类别
order_products = customer_orders.merge(
    order_items[["order_id", "product_id"]],
    on="order_id",
    how="inner"
)

order_products = order_products.merge(
    products[["product_id", "product_category_name"]],
    on="product_id",
    how="left"
)

# 6. 删除缺少关键分析信息的记录
order_products = order_products.dropna(
    subset=[
        "customer_unique_id",
        "product_category_name",
        "order_purchase_timestamp"
    ]
)

# 7. 同一客户、同一类别、同一订单只保留一次
# 避免客户在一笔订单中购买多个同类别商品，被误认为多次复购
purchase_events = order_products[
    [
        "customer_unique_id",
        "product_category_name",
        "order_id",
        "order_purchase_timestamp"
    ]
].drop_duplicates()

# 8. 按客户、商品类别和购买时间排序
purchase_events = purchase_events.sort_values(
    [
        "customer_unique_id",
        "product_category_name",
        "order_purchase_timestamp"
    ]
)

# 9. 计算同一客户再次购买同一类别的时间间隔
purchase_events["repurchase_interval"] = (
    purchase_events.groupby(
        ["customer_unique_id", "product_category_name"]
    )["order_purchase_timestamp"].diff()
)

# 10. 将时间间隔转换成天数
purchase_events["interval_days"] = (
    purchase_events["repurchase_interval"].dt.total_seconds()
    / 86400
)

# 11. 只保留真正产生复购间隔的记录
repurchase_data = purchase_events.dropna(
    subset=["interval_days"]
).copy()

# 12. 按商品类别统计复购周期
category_stats = repurchase_data.groupby(
    "product_category_name"
)["interval_days"].agg(
    复购间隔记录数="count",
    平均复购间隔="mean",
    复购间隔中位数="median",
    P75=lambda x: x.quantile(0.75),
    P90=lambda x: x.quantile(0.90)
)

# 13. 按复购间隔记录数降序排列
category_stats = category_stats.sort_values(
    "复购间隔记录数",
    ascending=False
)

# 14. 输出结果
print("\n各商品类别复购周期统计：")
print(category_stats.round(2))

print("\n总体检查：")
print("复购间隔记录数：", len(repurchase_data))
print(
    "涉及的真实客户数：",
    repurchase_data["customer_unique_id"].nunique()
)
print(
    "涉及的商品类别数：",
    repurchase_data["product_category_name"].nunique()
)

# 15. 保存商品类别复购周期统计结果
output_path = BASE_DIR / "category_repurchase_stats.csv"

category_stats.round(2).to_csv(
    output_path,
    encoding="utf-8-sig"
)

print("\n统计结果已保存到：", output_path)
