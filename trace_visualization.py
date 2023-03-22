import matplotlib.pyplot as plt
from scipy.stats import entropy
import numpy as np
import EntropyHub as EH

def Approximate_Entropy(x, m, r=0.15):
    """
    近似熵
    m 滑动时窗的长度
    r 阈值系数 取值范围一般为：0.1~0.25
    """
    # 将x转化为数组
    x = np.array(x)
    # 检查x是否为一维数据
    if x.ndim != 1:
        raise ValueError("x的维度不是一维")
    # 计算x的行数是否小于m+1
    if len(x) < m+1:
        raise ValueError("len(x)小于m+1")
    # 将x以m为窗口进行划分
    entropy = 0  # 近似熵
    for temp in range(2):
        X = []
        for i in range(len(x)-m+1-temp):
            X.append(x[i:i+m+temp])
        X = np.array(X)
        # 计算X任意一行数据与所有行数据对应索引数据的差值绝对值的最大值
        D_value = []  # 存储差值
        for i in X:
            sub = []
            for j in X:
                sub.append(max(np.abs(i-j)))
            D_value.append(sub)
        # 计算阈值
        F = r*np.std(x, ddof=1)
        # 判断D_value中的每一行中的值比阈值小的个数除以len(x)-m+1的比例
        num = np.sum(D_value<F, axis=1)/(len(x)-m+1-temp)
        # 计算num的对数平均值
        Lm = np.average(np.log(num))
        entropy = abs(entropy) - Lm

    return entropy

def visualize(fn: str):
    blk_addr = []
    ip = []
    hit = []
    dict = {}
    entropy = {}
    with open(fn, 'r') as fr:
        while True:
            line = fr.readline()
            if line == '':
                break
            info = line.split(',')
            if info[1] not in dict.keys():
                dict[info[1]] = [int(info[0])]
            else:
                dict[info[1]].append(int(info[0]))
            blk_addr.append(int(info[0]))
            ip.append(int(info[1]))
            hit.append(int(info[2]))
    for ip in dict.keys():
        dict[ip] = [(dict[ip][i]- dict[ip][i-1]) for i in range(1, len(dict[ip]))]
    for ip in dict.keys():
        if len(dict[ip]) > 10:
            Ap, Phi = Approximate_Entropy(np.array(dict[ip]), 2, 0.2)
            # print("Entropy[{}] = {}".format(int(ip), Ap[-1]))
            entropy[ip] = Ap[-1]

    total_samples = 0
    for ip in entropy.keys():
        total_samples +=  len(dict[ip])
    weighted_entropy = 0
    for ip in entropy.keys():
        weighted_entropy += len(dict[ip]) / total_samples * entropy[ip]

    print("Weighted entropy of {} is: {}".format(fn, weighted_entropy))

    



if __name__ == "__main__":
    visualize("mem_acce_623.xalancbmk_s-325B.champsimtrace.log")