# LeetCode Exercises



## 通用方法

* 双指针 / 快慢指针
  * 有序数组, 逼近给定值
  * 自定义点: 运算(+), 双指针移动方式(++, --)
  * k-sum (closest)
  * 滑动窗口
* DP
  * 常规DP
  * 树形DP
  * 数位DP
* 树
  * 线段树
  * Trie
  * MST
  * 树形DP
  * DFS序
  * 欧拉序
  * 树状数组
  * BST
* 并查集
  * 连通关系
* 后缀数组
  * 后缀大小
  * LCA
* DFS序
* 二分
  * 二分规则 -> 灵活
* 图
  * 单源最短 (Dijsktra, Bellman-Ford)
  * 全部最短 (Floyd)
  * 并查集
  * DFS
  * BFS 最短距离
  * 网络流
* 排序
  * 归并 -> 求数组逆序对
* xor
* 倍增
  * 求幂
  * dp
  * LCA
  * 后缀数组
* LCS
  * 单调队列$O(n\log n)$优化
* 单调栈/队列
  * 区间最值
  * 去除冗余状态, LIS
  * 最优队首



## LeetCode

### 4 Median of Two Sorted Arrays

* 对两个数列分别二分 ($i = k/2, j = k - i$), 比较中位数, 如果$a_i > b_j$, 则对$...a_{i-1}, b{j}...$ 找$i$个, 因为$b$的前$j$个都应该成为前$k$个之一. 否则, 则对$a_{i}..., ...b{j-1}$找$j$个, $a$的前$i$个都应该成为前$k$个之一. 复杂度$O(log(m + n))$

* ```python
  class Solution:
      def findMedianSortedArrays(self, nums1: List[int], nums2: List[int]) -> float:
          l = len(nums1) + len(nums2)
          if l % 2:
              return self.findKth(nums1, nums2, l // 2)
          else:
              return (self.findKth(nums1, nums2, l // 2 - 1) + self.findKth(nums1, nums2, l // 2)) / 2.0
          
      def findKth(self, A, B, k):
          if len(A) > len(B):
              A, B = B, A
          if not A:
              return B[k]
          if k == len(A) + len(B) - 1:
              return max(A[-1], B[-1])
  
          i = min(len(A) - 1, k // 2)
          j = min(len(B) - 1, k - i)
  
          if A[i] > B[j]:
              return self.findKth(A[:i], B[j:], i)
          else:
              return self.findKth(A[i:], B[:j], j)
  ```

* 二路归并$O(n + m)$

* ```c++
  class Solution {
  public:
      double findMedianSortedArrays(const vector<int>& nums1, const vector<int>& nums2)
      {
          const int*   p1       = nums1.data();
          const int*   p2       = nums2.data();
          const size_t count1   = nums1.size();
          const size_t count2   = nums2.size();
          const size_t count    = count1 + count2;
          const size_t sentinel = (count / 2) + 1;
          size_t       iter1    = 0;
          size_t       iter2    = 0;
          int          a        = 0;
          int          b        = 0;
  
          for (size_t i = 0; i < sentinel; ++i)
          {
              if (iter1 < count1 && iter2 < count2)
              {
                  if (p1[iter1] <= p2[iter2])
                  {
                      b = a;
                      a = p1[iter1++];
                  }
                  else
                  {
                      b = a;
                      a = p2[iter2++];
                  }
              }
              else if (iter1 >= count1 && iter2 < count2)
              {
                  b = a;
                  a = p2[iter2++];
              }
              else if (iter1 < count1 && iter2 >= count2)
              {
                  b = a;
                  a = p1[iter1++];
              }
              else
              {
                  break;
              }
          }
          
          if (count % 2 == 0)
          {
              return 0.5 * ((double)a + (double)b);
          }
          return (double)a;
      }
  };
  ```

* 如果我们将有序数组切分为等长的左右两部分，则 中位数 = (左半边的最大值 + 右半边的最小值) / 2

* ![1566834633155](D:\OneDrive\Pictures\Typora\1566834633155.png)

* ![1566834656405](D:\OneDrive\Pictures\Typora\1566834656405.png)

* ![1566834669929](D:\OneDrive\Pictures\Typora\1566834669929.png)

* ![1566834679439](D:\OneDrive\Pictures\Typora\1566834679439.png)

* ```c++
  class Solution {
  public:
      double findMedianSortedArrays(vector<int>& nums1, vector<int>& nums2) {
          int N1 = nums1.size();
          int N2 = nums2.size();
          if (N1 < N2) return findMedianSortedArrays(nums2, nums1);
  
          int lo = 0, hi = N2 * 2;
          while (lo <= hi) {
              int mid2 = (lo + hi) / 2;
              int mid1 = N1 + N2 - mid2;
  
              double L1 = (mid1 == 0) ? INT_MIN : nums1[(mid1-1)/2];
              double L2 = (mid2 == 0) ? INT_MIN : nums2[(mid2-1)/2];
              double R1 = (mid1 == N1 * 2) ? INT_MAX : nums1[(mid1)/2];
              double R2 = (mid2 == N2 * 2) ? INT_MAX : nums2[(mid2)/2];
  
              if (L1 > R2) lo = mid2 + 1;
              else if (L2 > R1) hi = mid2 - 1;
              else return (max(L1,L2) + min(R1, R2)) / 2;
          }
          return -1;
      }
  };
  ```

* [acwing](https://www.acwing.com/solution/leetcode/content/50/)



#### 84 Largest Rectangle in Histogram

* 先弄进去一个0保证输出, 然后裸的单调栈, 维护一个单调递增的栈, 更小的元素就不断`pop`

* ```c++
  class Solution {
  public:
      int largestRectangleArea(vector<int>& heights) {
          stack<int> m;
          heights.push_back(0);
          int res = 0;
          int lastK = 0;
          for (int i  = 0; i < heights.size(); ++i) {
              while (!m.empty() && heights[i] < heights[m.top()]) {
                  int h = m.top();
                  m.pop();
                  int k = 0;
                  if (m.empty()) {
                      k = -1;
                  } else {
                      k = m.top();
                  }
                  res = max(res, (i - k - 1) * heights[h]);
              }
              m.push(i);
          }
          return res;
      }
  };
  ```

* 扩展: 最大全1矩阵, 先预处理一维视为之前连续的1个数, 然后就是对每行做最大直方图





### 96 Unique Binary Search Trees

* Catalan数, $f(n) = \sum_{i = 0}^{n-1}f(i)f(n - i - 1)$, $f(n) = C(2n, n) / (n + 1)$

* 组合数取模 -> 打表 / Lucas / 素数指标 (not used here)

* [Purfer序列](https://blog.csdn.net/qq_39930039/article/details/78947656)

  * > （1） 生成数列：
    >
    > 选取此时树上编号最小的叶子节点，删除此节点且将此节点所连接的节点加入数列末端
    >
    > 不断的重复上述操作，直到只剩两个节点时停止该操作。
    >
    > (所以一个purfer序列的长度应为n-2)
    >
    > 
    >
    > （2）还原无根树：
    >
    > 设集合A = {1，2，3，...... ，n-1， n}
    >
    > 设purfer数列 a1， a2， ...... ， an
    >
    > 顺次选出purfer数列首位元素，然后在集合A中选出另一元素与它相连边
    >
    > 选出元素需满足一下特点：
    >
    > ① 该元素此时不能在purfer序列中
    >
    > ② 该元素此时应在集合A中
    >
    > ③ 满足以上两条件的最小元素
    >
    > 不断进行以上操作，知道purfer数列为空，此时A集合必然存在两个元素，最后将这两个元素连接起来，则此无根树还原完毕。

* ```c++
  class Solution {
  public:
      int numTrees(int n) {
          long long ans=1, i;
          for(i = 1; i <= n; i++)
              ans = ans * (i + n) / i;
          return ans / i;
      }
  };
  ```





### 149 Max Points on a Line

* 转化成斜率 + 共点, [max-points-on-a-line](https://leetcode.com/problems/max-points-on-a-line/)
* 对每个点, 求所有斜率 `(dx/gcd, dy/gcd)`, 如果相同, 表示共线. 考虑垂直和重合

```c++
class Solution {
public:
    int maxPoints(vector<vector<int>>& points) {
        if (points.size() < 2) return points.size();
        int N = points.size();
        int result = 0;
        for (int i = 0; i < N; ++i) {
            map<pair<int, int>, int> cnt;
            int local = 0;
            int overlap = 0;
            int vertical = 0;
            for (int j = i + 1; j < N; ++j) {
                int x1 = points[i][0];
                int y1 = points[i][1];
                int x2 = points[j][0];
                int y2 = points[j][1];
                if (x1 == x2 && y1 == y2) {
                    ++overlap;
                    continue;
                } else if (x1 == x2) {
                    ++vertical;
                    local = max(local, vertical);
                } else {
                    int dx = x2 - x1;
                    int dy = y2 - y1;
                    int g = __gcd(dx, dy);
                    dx /= g;
                    dy /= g;
                    auto p = make_pair(dx, dy);
                    cnt[p]++;
                    local = max(local, cnt[p]);
                }
            }
            result = max(result, local + overlap + 1);
        }
        return result;
    }
};
```



### 315 Count of Smaller Numbers After Self

* 求逆序数, 考虑归并排序, 同时有序, 则考虑双指针优化

* ```c++
  class Solution {
  public:
      void merge(vector<pair<int, int>>& nums, vector<int>& cnt, int l, int r) {
          if (r - l <= 1) return;
          int m = l + (r - l) / 2;
          merge(nums, cnt, l, m);
          merge(nums, cnt, m, r);
          for (int i = l, j = m; i < m; ++i) {
              while (j < r && nums[i].first > nums[j].first) ++j;
              cnt[nums[i].second] += j - m;
          }
          inplace_merge(nums.begin() + l, nums.begin() + m, nums.begin() + r);
      }
      vector<int> countSmaller(vector<int>& nums) {
          vector<int> cnt(nums.size(), 0);
          vector<pair<int, int>> n;
          for (int i = 0; i < nums.size(); ++i) {
              n.push_back(make_pair(nums[i], i));
          }
          merge(n, cnt, 0, nums.size());
          return cnt;
      }
  };
  ```

* 用BST + size信息, 倒着查询并更新树上size (二分为<root, >=root)

* 用BIT + size信息, 倒着查询并更新树状数组 (二分为index表示下一位=0, =1)

* 用线段树, 以值建树(O(N))后倒着查询并更新size (二分为前半线段, 后半线段)

* [ref](https://leetcode.com/problems/count-of-smaller-numbers-after-self/discuss/76657/3-ways-(Segment-Tree-Binary-Indexed-Tree-Binary-Search-Tree)-clean-python-code)





### 547 Friend Circles

* 裸的并查集

* ```c++
  #pragma GCC optimize("O3")
  
  static const auto speedup = [](){
      ios::sync_with_stdio(false);
      cin.tie(nullptr);
      return nullptr;
  }();
  
  class Solution {
  public:
      
      int find(vector<int>& uni, int idx) __attribute__ ((hot)) {
          while (uni[idx] != idx) {
              size_t oidx = idx;
              idx = uni[idx];
              uni[oidx] = idx;
          }
          return idx;
      }
      
      int findCircleNum(vector<vector<int>>& M) __attribute__ ((hot)) {
          vector<int> uni(M.size());
          iota(uni.begin(), uni.end(), 0);
          size_t N = M.size();
          for (size_t i = 0; i < N; ++i) {
              for (size_t j = i + 1; j < N; ++j) {
                  if (M[i][j] == 1) {
                      int il = find(uni, i);
                      int jl = find(uni, j);
                      if (il != jl) {
                          uni[il] = jl;
                      }
                  }
              }
          }
          size_t cnt = 0;
          for (size_t i = 0; i < N; ++i) {
              if (uni[i] == i) {
                  ++cnt;
              }
              std::cout << uni[i] << ' ';
          }
          return cnt;
      }
  };
  ```

* 





### 719 Find K-th Smallest Pair Distance

* 首先排序 O(NlogN), 这样求小于M的差值数可以通过双(快慢)指针完成, O(N).

* 二分差值, 以小于mid差值的数量<K为界限

* ```c++
  class Solution {
  public:
      int smallestDistancePair(vector<int>& nums, int k) {
          sort(nums.begin(), nums.end());
          int N = nums.size();
          int lo = 0, hi = nums.back() - nums[0];
          while (lo < hi) {
              int mid = (lo + hi) / 2;
              int left = 0;
              int cnt = 0; // less than mid
              for (int i = 0; i < N; ++i) {
                  while (nums[i] - nums[left] > mid) {
                      ++left;
                  }
                  cnt += i - left;
              }
              if (cnt >= k)
                  hi = mid;
              else
                  lo = mid + 1;
          }
          return lo;
      }
  };
  ```



### 1092 Shortest Common Supersequence

* 先求两个字符串的LCS (DP, 用来存位置, 单调队列不知道如何记位置). 然后往里面插字符

* ```python
  class Solution:
      def lcs(self, str1, str2):
          a = len(str1)
          b = len(str2)
          string_matrix = [[0 for i in range(b+1)] for i in range(a+1)]   
          for i in range(1, a+1):
              for j in range(1, b+1):
                  if i == 0 or j == 0:
                      string_matrix[i][j] = 0
                  elif str1[i-1] == str2[j-1]:
                      string_matrix[i][j] = 1 + string_matrix[i-1][j-1]
                  else:
                      string_matrix[i][j] = max(string_matrix[i-1][j], string_matrix[i][j-1])
          ind = []
          i = a
          j = b
          while i > 0 and j > 0:
              if str1[i-1] == str2[j-1]:
                  ind.append((i - 1, j - 1))
                  i -= 1
                  j -= 1
              elif string_matrix[i-1][j] > string_matrix[i][j-1]:
                  i -= 1
              else:
                  j -= 1
          return ind
      
      def shortestCommonSupersequence(self, str1: str, str2: str) -> str:
          N1 = len(str1)
          N2 = len(str2)
          common_ind = self.lcs(str1, str2)
          res = ''
          common_ind.append((-1, -1))
          for i in range(len(common_ind) - 2, -1, -1):
              k1, k2 = common_ind[i]
              l1, l2 = common_ind[i + 1]
              res += str1[l1 + 1:k1]
              res += str2[l2 + 1:k2]
              res += str1[k1]
              print(l1, k1, l2, k2)
          res += str1[common_ind[0][0] + 1:]
          res += str2[common_ind[0][1] + 1:]
          return res
  ```





## Miscs



### Total number of 1's in binary expansions

- [OEIS-A000788](http://oeis.org/A000788)

- ```c++
  unsigned A000788(unsigned n)
  {
  	unsigned v = 0;
  	for (unsigned bit = 1; bit <= n; bit <<= 1)
  		v += ((n>>1)&~(bit-1)) + ((n&bit) ? (n&((bit<<1)-1))-(bit-1) : 0);
  	return v;
  }
  ```

- $a(2^m+r) = m 2^{m-1} + r + 1 + a(r)$

  - ```c++
    int MSB(int n) 
    { 
        // Below steps set bits after 
        // MSB (including MSB) 
      
        // Suppose n is 273 (binary 
        // is 100010001). It does following 
        // 100010001 | 010001000 = 110011001 
        n |= n >> 1; 
      
        // This makes sure 4 bits 
        // (From MSB and including MSB) 
        // are set. It does following 
        // 110011001 | 001100110 = 111111111 
        n |= n >> 2; 
      
        n |= n >> 4; 
        n |= n >> 8; 
        n |= n >> 16; 
      
        // Increment n by 1 so that 
        // there is only one set bit 
        // which is just before original 
        // MSB. n now becomes 1000000000 
        n = n + 1; 
      
        // Return original MSB after shifting. 
        // n now becomes 100000000 
        return (n >> 1); 
    } 
    
    unsigned int msb32(unsigned int x)
    {
        static const unsigned int bval[] =
        { 0,1,2,2,3,3,3,3,4,4,4,4,4,4,4,4 };
    
        unsigned int base = 0;
        if (x & 0xFFFF0000) { base += 32/2; x >>= 32/2; }
        if (x & 0x0000FF00) { base += 32/4; x >>= 32/4; }
        if (x & 0x000000F0) { base += 32/8; x >>= 32/8; }
        return base + bval[x];
    }
    ```

  - 

- $a(2^n - 1) = n2^{n-1}$

- $a(2n) = a(n) + a(n-1) + n, a(2n + 1) = 2a(n) + n + 1$

