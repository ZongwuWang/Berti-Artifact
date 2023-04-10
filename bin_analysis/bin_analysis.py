import struct
import matplotlib.pyplot as plt
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-f", "--file", help="the file to be analyzed", default="605.mcf_s-994B.champsimtrace_core0.dat")
args = parser.parse_args()

fn = "../ROB_stall_result/{}".format(args.file)
ip_dict = {}
with open(fn, "rb") as fr:
    while True:
        binary_data = fr.read(16)
        if not binary_data:
            break
        ip, stall_cycle = struct.unpack("=QQ", binary_data)
        if ip not in ip_dict.keys():
            ip_dict[ip] = [stall_cycle]
        else:
            ip_dict[ip].append(stall_cycle)

# print(f"ip = {ip}, stall_cycle = {stall_cycle}")
# 遍历ip_dict中每个key，求取每个key对应value的均值和标准差，并保存到字典中
ip_dict_mean_std = {}
for key in ip_dict.keys():
    mean = sum(ip_dict[key]) / len(ip_dict[key])
    std = (sum([(x - mean) ** 2 for x in ip_dict[key]]) / len(ip_dict[key])) ** 0.5
    ip_dict_mean_std[key] = [mean, std]

# 将每个ip的均值和标准差保存到csv文件中，文件名来源于fn
dist_fn = fn.split("/")[-1].replace(".dat", "")
mean = []
std = []
with open("extract_results/" + dist_fn + ".csv", "w") as fw:
    fw.write("ip, mean, std\n")
    for key in ip_dict_mean_std.keys():
        mean.append(ip_dict_mean_std[key][0])
        std.append(ip_dict_mean_std[key][1])
        fw.write(f"{key},{ip_dict_mean_std[key][0]},{ip_dict_mean_std[key][1]}\n")

# 画出每个ip的均值和标准差的散点图
plt.figure(figsize=(10, 10))
plt.scatter(mean, std)
plt.xlabel("mean")
plt.ylabel("std")
plt.title(dist_fn)
plt.savefig("extract_results/" + dist_fn + ".png", dpi=300, bbox_inches="tight")
plt.close()