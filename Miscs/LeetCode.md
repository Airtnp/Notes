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
  * 单调队列优化 `dp[i] = min(f[k]) + g[i] (0 < k < i)`
  
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

* 二分 -> 单调函数
  
  * 二分规则 -> 灵活
  * 三分 `(l, mid, (mid + r) / 2, r)` -> 凸函数
  
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
  
* 离散化

  * 先排序, 去重, 再用下标表示

  * ```c++
    sort(sub_a.begin(), sub_a.end());
    int size = unique(sub_a.begin(), sub_a.end()) - sub_a.begin();
    for(i = 0; i < n; ++i)
        a[i] = lower_bound(sub_a.begin(), sub_a.end(), a[i]) - sub_a.begin() + 1;
    ```

* Top K

  * quick select (partition in quicksort)
  * priority queue
  
* 背包问题

  * [背包九讲](https://blog.csdn.net/ling_du/article/details/41594767)
  * 01背包
  * 完全背包
  * 多重背包
  * 多维背包



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



### 39 &  & 216 Combinational Sum i & ii & iii

* 经典NP-Hard

* i. 先排序, 然后DFS强做, 可剪枝

* ```c++
  class Solution {
  public:
      void helper(vector<vector<int>>& res, vector<int>& candidates, int target, vector<int>& nums, int offset) {
          if (target == 0) {
              res.push_back(nums);
              return;
          }
          for (int k = offset; k < candidates.size(); ++k) {
              int i = candidates[k];
              nums.push_back(i);
              if (target >= i)
                  helper(res, candidates, target - i, nums, k);
              nums.pop_back();
          }
      }
      
      
      vector<vector<int>> combinationSum(vector<int>& candidates, int target) {
          sort(candidates.begin(), candidates.end());
          vector<vector<int>> res;
          vector<int> nums;
          helper(res, candidates, target, nums, 0);
          return res;
      }
  };
  ```

* ii. 同一个数只试一遍: 同一个offset下只能用第一个 `k > offset && candidates[k] == candidates[k - 1]`

* ```c++
  class Solution {
  public:
      void helper(vector<vector<int>>& res, vector<int>& candidates, int target, vector<int>& nums, int offset) {
          if (target == 0) {
              res.push_back(nums);
              return;
          }
          for (int k = offset; k < candidates.size(); ++k) {
              int i = candidates[k];
              if (k > offset && candidates[k] == candidates[k - 1])
                  continue;
              nums.push_back(i);
              if (target >= i)
                  helper(res, candidates, target - i, nums, k + 1);
              nums.pop_back();
          }
      }
      
      
      vector<vector<int>> combinationSum2(vector<int>& candidates, int target) {
          sort(candidates.begin(), candidates.end());
          vector<vector<int>> res;
          vector<int> nums;
          helper(res, candidates, target, nums, 0);
          return res;
      }
  };
  ```

* iii, 没啥技术含量

* ```c++
  class Solution {
  public:
      void helper(vector<vector<int>>& res, vector<int>& nums, int k, int n, int offset) {
          if (nums.size() == k && n == 0) { res.push_back(nums); return ; }
          if (nums.size() == k) return;
          for (int i = offset; i <= 9; ++i) {
              if (n - i < 0) break;
              nums.push_back(i);
              helper(res, nums, k, n - i, i + 1);
              nums.pop_back();
          }
      }
  
      vector<vector<int>> combinationSum3(int k, int n) {
          vector<vector<int>> result;
          vector<int> nums;
          helper(result, nums, k, n, 1);
          return result;
      }
  };
  ```

* 







### 84 Largest Rectangle in Histogram

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



### 74 & 240 Search a 2D Matrix i & ii

* 74: 因为相当于一个有序数组切分成几段, 二维二分, 先找row再找col

  * ```c++
    class Solution {
    public:
        bool searchMatrix(vector<vector<int>>& matrix, int target) {
            if (!matrix.size() || !matrix[0].size()) return false;
            vector<int> first;
            for (auto& v : matrix) {
                first.push_back(v[0]);
            }
            auto it = upper_bound(first.begin(), first.end(), target);
            if (it == first.begin()) return false;
            auto& col = matrix[it - first.begin() - 1];
            auto tit = lower_bound(col.begin(), col.end(), target);        
            if (tit == col.end() || *tit != target)
                return false;
            return true;
        }
    };
    ```

* 240: 相当于一个二维菱形, 从最大开始双指针 $O(M + N)$

  * ```c++
    class Solution {
    public:
        bool searchMatrix(vector<vector<int>>& matrix, int target) {
            int m = matrix.size();
            if (m == 0) return false;
            int n = matrix[0].size();
            int i = 0, j = n - 1;
            while (i < m && j >= 0) {
                if (matrix[i][j] == target)
                    return true;
                else if (matrix[i][j] > target) {
                    --j;
                } else 
                    ++i;
            }
            return false;
        }
    };
    ```

  * [SO-saddleback search](https://stackoverflow.com/questions/2457792/how-do-i-search-for-a-number-in-a-2d-array-sorted-left-to-right-and-top-to-botto/2458113#2458113)

  * 也可以对每一行做二分, $O(M\log{N})$







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





### 145 Binary Tree Postorder Traversal

* 迭代求前序: 压入根, 每次出栈, 放入right, 放入left

  * ```c++
    stack.push(root);
    while (!stack.isEmpty()) {
        Node node = stack.pop();
        result.add(node.val);
        if (node.right) stack.push(node.right);
        if (node.left) stack.push(node.left);
    }
    ```

  * 

* 迭代求中序: 循环压入left, 每次弹出加入right

  * ```c++
    stack.push(root);
    while (!stack.isEmpty()) {
        while (stack.top().left != null) {
            stack.push(stack.top().left);
        }
        if (!stack.isEmpty()) {
            Node node = stack.pop();
            result.add(node.val);
            if (node.right != null) {
                stack.push(node.right);
            }
        }
    }
    ```

* 迭代求后序: 先走完左子树, 然后走右子树, 栈回溯时判断上一次pop的是否是栈顶的right, 是则为回溯路径

  * ```c++
    class Solution {
    public:
        vector<int> postorderTraversal(TreeNode* root) {
            vector<int> nodes;
            stack<TreeNode*> s;
            TreeNode* last = nullptr;
            while (root || !s.empty()) {
                if (root) {
                    s.push(root);
                    root = root->left;
                } else {
                    TreeNode* node = s.top();
                    if (node->right && last != node->right) {
                        root = node->right;
                    } else {
                        nodes.push_back(node->val);
                        last = node;
                        s.pop();
                    }
                }
            }
            return nodes;
        }
    };
    ```

  * 也可以reverse前序遍历

* [Morris遍历](https://www.cnblogs.com/AnnieKim/archive/2013/06/15/morristraversal.html)

  * 在遍历中原地更改右节点用于恢复前驱





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



### 189 Rotate Array

* 暴力移位

* 三次翻转

  * 总体翻转

  * 前`k`个翻转

  * 后`n - k`个翻转

  * ```c++
    class Solution {
    public:
        void rotate(vector<int>& nums, int k) {
            k %= nums.size();
            reverse(nums.begin(), nums.end());
            reverse(nums.begin(), nums.begin() + k);
            reverse(nums.begin() + k, nums.end());
        }
    };
    ```

* gcd交换

  * 循环左移会造成`N / gcd(N, k)`个`gcd(N, k)`大小的循环群

  * ```c++
    class Solution {
    public:
        void rotate(vector<int>& nums, int k) {
            int n = nums.size();
            k %= n;
            int cyclic = __gcd(n, k);
            for (int start = cyclic - 1; start >= 0; --start) {
                int current = start;
                int prev = nums[start];
                do {
                    int next = (current + k) % n;
                    swap(prev, nums[next]);
                    swap(current, next);
                } while (start != current);
            }
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



### 435 Non-overlapping Intervals

* 对结束时间贪心, 仅当初始时间大于等于原结束时间才更改活动区间

* ```c++
  class Solution {
  public:
      int eraseOverlapIntervals(vector<vector<int>>& intervals) {
          if (!intervals.size())
              return 0;
          auto cmp = [](const vector<int>& l, const vector<int>& r) {
              if (l[1] != r[1])
                  return l[1] < r[1];
              return l[0] < r[0];
          };
          sort(intervals.begin(), intervals.end(), cmp);
          int cnt = 1;
          int end = intervals[0][1];
          for (int i = 1; i < intervals.size(); ++i) {
              if (intervals[i][0] < end)
                  continue;
              end = intervals[i][1];
              ++cnt;
          }
          return intervals.size() - cnt;
      }
  };
  ```







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




### 572 Subtree of Another Tree

* 先做depth优化, 找到候选根, 然后比较

* ```c++
  class Solution {
  public:
      vector<TreeNode*> candidates;
      
      int depth(TreeNode* root, int d) {
          if (!root) return 0;
          int currentd = max(depth(root->left, d), depth(root->right, d)) + 1;
          if (currentd == d) {
              candidates.push_back(root);
          }
          return currentd;
      }
      
      bool is_same_tree(TreeNode* s, TreeNode* t) {
          if (!s && !t) return true;
          if (!s || !t) return false;
          if (s->val != t->val)
              return false;
          return is_same_tree(s->left, t->left) && is_same_tree(s->right, t->right);
      }
      
      bool isSubtree(TreeNode* s, TreeNode* t) {
          if (!s && !t) return true;
          if (!s || !t) return false;
          int tdepth = depth(t, -1);
          depth(s, tdepth);
          for (auto n : candidates) {
              if (is_same_tree(n, t))
                  return true;
          }
          return false;
      }
  };
  ```

* 先做欧拉序, 然后找子序列?





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





### 796 Rotate String

* [TODO]
* rolling hash
* KMP





### 792 Number of Matching Subsequence

* 优化成对每个字符串的首字符集合, 相当于同时做n个匹配

* ```c++
  class Solution {
  public:
      int numMatchingSubseq(string S, vector<string>& words) {
          unordered_map<string_view, int> indup;
          unordered_map<string_view, int> indup_cnt;
          for (const auto& s : words) {
              ++indup[s];
          }
          int count = 0;
          using It = decltype(indup)::iterator;
          vector<vector<It>> queue(26);
          for (auto it = indup.begin(); it != indup.end(); ++it) {
              queue[it->first[0] - 'a'].push_back(it);
          }
          int cnt = 0;
          
          for (auto c : S) {
              vector<It> u;
              queue[c - 'a'].swap(u);
              for (auto it : u) {
                  int scnt = ++indup_cnt[it->first];
                  if (scnt < it->first.length()) {
                      queue[it->first[scnt] - 'a'].push_back(it);
                  } else {
                      cnt += it->second;
                  }
              }
          }
          return cnt;
      }
  };
  ```



### 850 Rectangle Area II

* HDU 1542

* 线段树 + 扫描线 (+ 离散化)

* 先对`y`坐标区域建线段树, 每次插入记录上次插入的`x`坐标和是否是左端线段. 求和 $O(N\log{N})$

* ```c++
   int m = 1e9 + 7;
  struct Segment {
    	int x;
      int y_down;
      int y_up;
      bool is_left;
  };
  struct SegTreeNode {
      int x; // last x index
      int y_down;
    	int y_up;
      bool is_leaf;
      int acc; // how many lines in this section
      void print() {
          cout &lt;&lt; &quot;x: &quot; &lt;&lt; x &lt;&lt; &quot; [&quot; &lt;&lt; y_down &lt;&lt; &quot;, &quot; &lt;&lt; y_up &lt;&lt; &quot;] &quot; &lt;&lt; acc &lt;&lt; &quot;\n&quot;;
      }
  };
  struct SegTree {
    	vector&lt;SegTreeNode&gt; nodes;
      SegTree(int n) {
          nodes.resize(1 &lt;&lt; n);
      }
      void build(int i, int l, int r, const vector&lt;int&gt;&amp; yvalue) {
          nodes[i] = {0, yvalue[l], yvalue[r], false, 0};
          if (l + 1 == r) {
              nodes[i].is_leaf = true;
              return;
          }
          int mid = (l + r) &gt;&gt; 1;
          build(2 * i, l, mid, yvalue);
          build(2 * i + 1, mid, r, yvalue);
      }
      long long insert(int i, const Segment&amp; seg) {
          if (seg.y_up &lt;= nodes[i].y_down || seg.y_down &gt;= nodes[i].y_up) return 0;
          if (nodes[i].is_leaf) {
              if (!nodes[i].acc) {
                  nodes[i].acc += seg.is_left ? 1 : -1;
                  nodes[i].x = seg.x;
                  return 0;
              } else {
                  long long diff_x = (seg.x - nodes[i].x) % m;
                  long long diff_y = (nodes[i].y_up - nodes[i].y_down) % m;
                  long long v = (diff_x * diff_y) % m;
                  nodes[i].x = seg.x;
                  nodes[i].acc += seg.is_left ? 1 : -1;
                  return v % m;
              }
          }
          return insert(2 * i, seg) + insert(2 * i + 1, seg);
      }
  };
  class Solution {
  public:
      int rectangleArea(vector&lt;vector&lt;int&gt;&gt;&amp; rectangles) {
      	vector&lt;int&gt; yvalue;
          yvalue.push_back(-1); // for fill 0;
          vector&lt;Segment&gt; lines;
          for (auto&amp; l : rectangles) {
              yvalue.push_back(l[1]);
              yvalue.push_back(l[3]);
              lines.emplace_back(Segment{l[0], l[1], l[3], true});
              lines.emplace_back(Segment{l[2], l[1], l[3], false});
          }
          sort(yvalue.begin(), yvalue.end());
  		// discretization
          auto it = unique(yvalue.begin(), yvalue.end());
          yvalue.erase(it, yvalue.end());
          sort(lines.begin(), lines.end(), [](const auto&amp; l, const auto&amp; r){
              return l.x &lt; r.x;
          });
          SegTree tree{8};
          tree.build(1, 1, yvalue.size() - 1, yvalue);
          long long ans = 0;
          for (auto&amp; l : lines) {
              ans += tree.insert(1, l);
              ans %= m;
          }
          return ans;
      }    
  };
  ```

* 不用线段树的扫描线: 每次直接遍历所有`x`线段 $O(N^2)$

* ```c++
   def rectangleArea(self, rectangles):
          xs = sorted(set([x for x1, y1, x2, y2 in rectangles for x in [x1, x2]] + [0]))
          x_i = {v: i for i, v in enumerate(xs)}
          count = [0] * len(x_i)
          L = []
          for x1, y1, x2, y2 in rectangles:
              L.append([y1, x1, x2, 1])
              L.append([y2, x1, x2, -1])
          L.sort()
          cur_y = cur_x_sum = area = 0
          for y, x1, x2, sig in L:
              area += (y - cur_y) * cur_x_sum
              cur_y = y
              for i in range(x_i[x1], x_i[x2]):
                  count[i] += sig
              cur_x_sum = sum(x2 - x1 if c else 0 for x1, x2, c in zip(xs, xs[1:], count))
          return area % (10 ** 9 + 7)
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



### 序列移除 (CF #243 Div.1 C)

* ![1566911533892](D:\OneDrive\Pictures\Typora\1566911533892.png)
  * 注意这题第二种操作和CF不一样
  * dp转移一样, 但是dp只是用来判断能否取到$j$个, 并非最优下标. 同时每个$j$要用最大下标$b_u$判断是否成立
* [codeforce r243 div.1 c](http://codeforces.com/problemset/problem/425/C)
* 先对b做counting sort得到下标. 然后对a数列和总共宝石数做dp. $dp(i, j)$ 表示取到 $a_i$ 元素前缀时 (不一定操作), 且总宝石数为$j$时, 剩下的 $b$ 最小序列起始点. 那么转移方程就是
  * $dp(i, j) = dp(i - 1, j)$, 不拿宝石
  * $dp(i, j) = (a_i$ 在 $b_{k + 1}, \cdots, b_{n-1}$ 中出现的最小位置$)$, 其中$k$是$dp(i - 1, j - 1)$, 拿宝石, 则从之前的最小序列之后开始找下一个匹配元素
* 总支出$j * cost + i + dp(i, j)$
* 单调性: 支出只会选 $b$ 中小的下标 (cost小, 且可能性多)