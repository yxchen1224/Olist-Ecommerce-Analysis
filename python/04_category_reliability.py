
import pandas as pd
from pathlib import Path

# 1. 获取项目根目录
BASE_DIR = Path(__file__).resolve().parent.parent

# 2. 读取第三个脚本生成的统计结果
input_path = BASE_DIR / "category_repurchase_stats.csv"

category_stats = pd.read_csv(
    input_path,
    index_col=0
)

# 3. 根据复购间隔记录数划分样本量等级
def judge_reliability(count):
    if count < 10:
        return "样本极少，结果不可靠"
    elif count < 30:
        return "样本较少，需要谨慎参考"
    elif count < 100:
        return "样本中等，可以初步参考"
    else:
        return "样本相对充足，参考价值较高"

category_stats["样本量判断"] = (
    category_stats["复购间隔记录数"]
    .apply(judge_reliability)
)

# 4. 按样本量从多到少排序
category_stats = category_stats.sort_values(
    by="复购间隔记录数",
    ascending=False
)

# 5. 输出各类别的可靠性判断
print("\n商品类别复购周期可靠性分析：")
print(category_stats.to_string())

# 6. 统计不同样本量等级的类别数量
print("\n各可靠性等级的类别数量：")
print(category_stats["样本量判断"].value_counts())

# 7. 保存结果
output_path = BASE_DIR / "category_reliability.csv"

category_stats.to_csv(
    output_path,
    encoding="utf-8-sig"
)

print("\n可靠性分析结果已保存到：", output_path)
