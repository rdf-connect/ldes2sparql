import json
import glob
import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Path where your JSON files are stored
data_path = "./results"   # adjust if needed

# Collect data
data = {}
for file in glob.glob(os.path.join(data_path, "*.json")):
    server_name = os.path.splitext(os.path.basename(file))[0]
    with open(file, "r") as f:
        data[server_name] = json.load(f)

# Build DataFrame (each server = one column)
df = pd.DataFrame(data)

# Reshape into long format for seaborn
df_long = df.melt(var_name="Server", value_name="Response Time (ms)")

# --- Seaborn boxplot (no palette warning) ---
plt.figure(figsize=(10, 6))
sns.boxplot(
    data=df_long,
    x="Server",
    y="Response Time (ms)",
    hue="Server",       # assign palette to Server
    showmeans=True,
    meanprops={"marker": "X", "markerfacecolor": "blue", "markeredgecolor": 'none', "markersize": 5},
    palette="Set2",
    legend=False        # no redundant legend
)
plt.title("Response Time Distribution per Server")
plt.tight_layout()
plt.savefig("boxplot.svg", format="svg")
plt.close()


# --- Line plot ---
# plt.figure(figsize=(20, 10))
# for col in df.columns:
#     plt.plot(df.index, df[col], label=col)
# plt.xlabel("Request Index")
# plt.ylabel("Response Time (ms)")
# plt.title("Response Times per Request")
# plt.legend()
# plt.tight_layout()
# plt.savefig("lineplot.svg", format="svg")
# plt.close()