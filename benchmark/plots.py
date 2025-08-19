import json
import glob
import os
import numpy as np
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

# --- Handle timeouts (-1) ---
# Replace -1 with (max observed + 20%)
max_val = df[df != -1].max().max()
timeout_val = max_val * 1.2
df.replace(-1, timeout_val, inplace=True)

# Long format for seaborn plots
df_long = df.melt(var_name="SPARQL engine", value_name="Response Time (ms)")

# Add a timeout flag for special plotting
df_long["Timeout"] = df_long["Response Time (ms)"] == timeout_val

# Get sorted engine names
engine_order = sorted(df_long["SPARQL engine"].unique())

# --- Seaborn boxplot + timeouts ---
plt.figure(figsize=(10, 6))
sns.boxplot(
    data=df_long,
    x="SPARQL engine",
    y="Response Time (ms)",
    hue="SPARQL engine",
    showmeans=True,
    meanprops={"marker": "X", "markerfacecolor": "blue", "markeredgecolor": 'none', "markersize": 5},
    palette="Set2",
    legend=False,
    order=engine_order
)

# Overlay timeout points
timeouts_long = df_long[df_long["Timeout"]]
sns.stripplot(
    data=timeouts_long,
    x="SPARQL engine",
    y="Response Time (ms)",
    color="red",
    marker="X",
    size=6,
    jitter=False,
    label="Timeout"
)

plt.title("Response Time Distribution per SPARQL engine")
plt.legend()
plt.tight_layout()
plt.savefig("boxplot.svg", format="svg")
plt.close()

# --- Faceted lineplots with smoothing and timeout markers ---
# Add Member Index for lineplot
df["Member Index"] = df.index
df_long_line = df.melt(
    id_vars="Member Index",
    var_name="SPARQL engine",
    value_name="Response Time (ms)"
)
df_long_line["Timeout"] = df_long_line["Response Time (ms)"] == timeout_val

# Apply rolling mean smoothing
window_size = 5
df_long_line["Smoothed"] = (
    df_long_line.groupby("SPARQL engine")["Response Time (ms)"]
    .transform(lambda x: x.rolling(window_size, min_periods=1).mean())
)

# Get sorted engine names
engine_order = sorted(df_long_line["SPARQL engine"].unique())

# FacetGrid: one subplot per engine
g = sns.FacetGrid(
    df_long_line,
    col="SPARQL engine",
    col_wrap=3,
    sharey=True,
    height=3,
    aspect=1.5,
    col_order=engine_order
)
g.map_dataframe(sns.lineplot, "Member Index", "Smoothed", alpha=0.8)

# Overlay red crosses for timeouts
for ax, (engine, subdata) in zip(g.axes.flatten(), df_long_line.groupby("SPARQL engine")):
    timeouts = subdata[subdata["Timeout"]]
    if not timeouts.empty:
        ax.scatter(
            timeouts["Member Index"],
            timeouts["Response Time (ms)"],
            color="red",
            marker="x",
            s=40,
            label="Timeout"
        )
        ax.legend()


g.set_titles(col_template="{col_name}")
g.set_axis_labels("Member Index", "Response Time (ms)")
g.fig.subplots_adjust(top=0.88)  # leave space on top
g.fig.suptitle(f"Response Times per Request (Smoothed, window={window_size})", fontsize=14)


plt.tight_layout()
plt.savefig("lineplot.svg", format="svg")
plt.close()
