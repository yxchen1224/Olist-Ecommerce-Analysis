
import pandas as pd
from pathlib import Path

# 1. 获取项目根目录
BASE_DIR = Path(__file__).resolve().parent.parent

# 2. 设置数据文件夹路径
DATA_DIR = BASE_DIR / "data"

# 3. 读取五张数据表
orders = pd.read_csv(DATA_DIR / "olist_orders_dataset.csv")
order_items = pd.read_csv(DATA_DIR / "olist_order_items_dataset.csv")
customers = pd.read_csv(DATA_DIR / "olist_customers_dataset.csv")
products = pd.read_csv(DATA_DIR / "olist_products_dataset.csv")
reviews = pd.read_csv(DATA_DIR / "olist_order_reviews_dataset.csv")

# 4. 将五张表放入字典，方便统一检查
tables = {
    "orders": orders,
    "order_items": order_items,
    "customers": customers,
    "products": products,
    "reviews": reviews
}

# 5. 检查每张表的数据规模、字段和缺失值
for name, df in tables.items():
    print(f"\n{name}")
    print("数据行数和列数：", df.shape)
    print("字段名称：", df.columns.tolist())
    print("缺失值数量：")
    print(df.isnull().sum())

