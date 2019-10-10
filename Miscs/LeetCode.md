# LeetCode Exercises



## 通用方法

* 双指针 / 快慢指针
  * 有序数组, 逼近给定值
  * 链表: 快慢指针找中点, 找环, 找环起始点, 找重复值
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
  * LCS
  * LRS (Repeat)
  * LPS (Palindrome)
  
* DFS序

* 二分 -> 单调函数
  
  * 二分规则 -> 灵活
  * 边界?
    * `L == R` allowed?
    * `L = mid + 1` or `R = mid - 1` or both? mid的时候成立吗? 是否一定有更优的方案?
    * 把`[L, R]`视为闭区间
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
  
* KMP

  * next数组: 前缀后缀公共元素的最大长度

  * ```java
    void GetNextval(char* p, int next[])
    {
    	int pLen = strlen(p);
    	next[0] = -1;
    	int k = -1;
    	int j = 0;
    	while (j < pLen - 1)
    	{
    		//p[k]表示前缀，p[j]表示后缀
    		if (k == -1 || p[j] == p[k])
    		{
    			++j;
    			++k;
    			//较之前next数组求法，改动在下面4行
    			if (p[j] != p[k])
    				next[j] = k;   //之前只有这一行
    			else
    				//因为不能出现p[j] = p[ next[j ]]，所以当出现时需要继续递归，k = next[k] = next[next[k]]
    				next[j] = next[k];
    		}
    		else
    		{
    			k = next[k];
    		}
    	}
    }
    ```

* AC自动机

  * Trie + 失配指针
  
* 链表

  * dummy head, **p = &&dummy_head

* 情况编码

  * 数位dp
  * 有限情况? => 循环节

* 矩阵快速幂



## LeetCode



### 3. Longest Substring Without Duplicate

* 单向快慢双指针, `left`表示左窗口位置, 由`left = max(left, m[s[i]])`更新, `right/i`表示当前处理位置

* ```c++
  class Solution {
  public:
      int lengthOfLongestSubstring(string s) {
          vector<int> m(256, -1);
          int res = 0, left = -1;
          for (int i = 0; i < s.size(); ++i) {
              left = max(left, m[s[i]]);
              m[s[i]] = i;
              res = max(res, i - left);
          }
          return res;
      }
  };
  ```

* 







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



### 5. Longest Palindromic Substring

* 最长子回文串, Manacher

  * ![1568847870792](D:\OneDrive\Pictures\Typora\1568847870792.png)
  * ![1568847881201](D:\OneDrive\Pictures\Typora\1568847881201.png)

* ```python
  class Solution:
      def longestPalindrome(self, s: str) -> str:
          news = '$' + '#'.join(s) + '#*'
          N = len(news)
          length = [0] * N
          pi = 0
          maxl = 0
          for i in range(1, N):
              if maxl > i:
                  length[i] = min(maxl - i, length[2 * pi - i])
              else:
                  length[i] = 1
              while i - length[i] > 0 and i + length[i] < N and news[i - length[i]] == news[i + length[i]]:
                  length[i] += 1
              if length[i] > maxl:
                  maxl = length[i]
                  pi = i
          return news[pi - maxl + 1:pi + maxl].replace('#', '').replace('$', '').replace('*', '')
  ```

* `dp(i, j) = dp(i + 1, j - 1) + s[i] == s[j] or 0`

* ```python
  def longestPalindrome(self, s):
      dp = [[0] * len(s) for i in range(len(s))]
      ans = ""
      max_length = 0
      for i in range(len(s) - 1, -1, -1):
          for j in range(i, len(s)):
              if s[i] == s[j] and (j - i < 3 or dp[i+1][j-1] == 1):
                  dp[i][j] = 1
                  if ans == "" or max_length < j - i + 1:
                      ans = s[i:j+1]
                      max_length = j - i + 1
      return ans
  ```

* 







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



### 46. & 47. Permutations i & ii

* 46: 递归交换即可

* ```c++
  class Solution {
  public:
      vector<vector<int>> result;
      void per(vector<int> num, int st) {
          if( num.size()-1 == st) {
              result.push_back(num);
              return;
          }
          for(int i = st;i< num.size();i++) {
              swap(num[i],num[st]);
              per(num,st+1);
              swap(num[i],num[st]);
          }
      }
      
      
      vector<vector<int>> permute(vector<int>& nums) {
          per(nums,0);
          return result;
      }
  };
  ```

* 47: 去重条件, 和当前首数相同的不可交换

  * 同时, 不交换回来

  * >  E.g. [1,1,2,2], we should not swap value position 1 and 3 becuase when when list as [1,2,1,2] , swap position 2 and 3 ([1,2,2,1]) has been done before

* ```c++
  class Solution {
  public:
      vector<vector<int>> result;
      void per(vector<int> num, int st) {
          if(num.size() - 1 == st) {
              result.push_back(num);
              return;
          }
          for(int i = st; i < num.size(); i++) {
              if (i > st && num[i] == num[st]) continue;
              swap(num[i], num[st]);
              per(num, st + 1);
          }
      }
      
      
      vector<vector<int>> permuteUnique(vector<int>& nums) {
          sort(nums.begin(), nums.end());
          per(nums,0);
          return result;
      }
  };
  
  // alternative check duplicate
  void backtracking(vector<int>& nums, vector<vector<int>>& res,int begin){
      if(begin==nums.size()-1){
          res.push_back(nums);
          return;
      }
      for(int i = begin; i<nums.size();i++){
          if((nums[i]!=nums[begin] || i == begin) && checkmiddle(nums,i,begin)){
              swap(nums[i],nums[begin]);
              backtracking(nums, res, begin+1);
              swap(nums[i],nums[begin]);
          }
      }
  
  }
  
  bool checkmiddle(vector<int>& nums, int i , int begin){
      for(int k = begin; k<i; k++)
          if(nums[i] == nums[k])
              return false;
      return true;
  }
  ```

  * `next_permutation`: 从后找第一个非逆序元素, 二分查找第一个大于该元素的位置, 交换, 然后对后序元素做逆序

    * ```c++
      class Solution {
      public:
          void nextPermutation(vector<int>& nums) {
              auto it = is_sorted_until(nums.rbegin(), nums.rend());
              if (it != nums.rend())
                  swap(*it, *upper_bound(nums.rbegin(), it, *it));
              reverse(nums.rbegin(), it);
          }
      };
      ```

    * 



### 48. Rotate Image

* 向量法, 和中心的差向量转90度, 注意可以直接反向转3次

* ```c++
  class Solution {
  public:
      void rotate(vector<vector<int>>& matrix) {
          int N = matrix.size();
          float core = (N - 1) / 2.0;
          for (int i = 0; i < (N + 1) / 2; ++i) {
              for (int j = 0; j < N / 2; ++j) {
                  float dx = i - core;
                  float dy = j - core;
                  for (int k = 0; k < 3; ++k) {
                      float ndx = -dy;
                      float ndy = dx;
                      int x = core + dx + 0.5;
                      int y = core + dy + 0.5;
                      int nx = core + ndx + 0.5;
                      int ny = core + ndy + 0.5;
                      swap(matrix[x][y], matrix[nx][ny]);
                      dx = ndx;
                      dy = ndy;
                  }
              }
          }
      }
  };
  ```

* 逆序 + 对称

* ```c++
  /*
   * clockwise rotate
   * first reverse up to down, then swap the symmetry 
   * 1 2 3     7 8 9     7 4 1
   * 4 5 6  => 4 5 6  => 8 5 2
   * 7 8 9     1 2 3     9 6 3
  */
  void rotate(vector<vector<int> > &matrix) {
      reverse(matrix.begin(), matrix.end());
      for (int i = 0; i < matrix.size(); ++i) {
          for (int j = i + 1; j < matrix[i].size(); ++j)
              swap(matrix[i][j], matrix[j][i]);
      }
  }
  
  /*
   * anticlockwise rotate
   * first reverse left to right, then swap the symmetry
   * 1 2 3     3 2 1     3 6 9
   * 4 5 6  => 6 5 4  => 2 5 8
   * 7 8 9     9 8 7     1 4 7
  */
  void anti_rotate(vector<vector<int> > &matrix) {
      for (auto vi : matrix) reverse(vi.begin(), vi.end());
      for (int i = 0; i < matrix.size(); ++i) {
          for (int j = i + 1; j < matrix[i].size(); ++j)
              swap(matrix[i][j], matrix[j][i]);
      }
  }
  ```

* 



### 49. Group Anagrams

* 普通/计数排序插入

* ```c++
  class Solution {
  public:
      vector<vector<string>> groupAnagrams(vector<string>& strs) {
          unordered_map<string, vector<string>> mp;
          for (string s : strs) {
              mp[strSort(s)].push_back(s);
          }
          vector<vector<string>> anagrams;
          for (auto p : mp) { 
              anagrams.push_back(p.second);
          }
          return anagrams;
      }
  private:
      string strSort(string s) {
          int counter[26] = {0};
          for (char c : s) {
              counter[c - 'a']++;
          }
          string t;
          for (int c = 0; c < 26; c++) {
              t += string(counter[c], c + 'a');
          }
          return t;
      }
  }
  ```

* 字符串Hash: 多项式, 素数, ... (太大的数据要加上取模)

* ```c++
  constexpr array<int, 27> primes = {2, 3, 5, 7, 11 ,13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 107};
  
  static auto const magic = []{
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);
    std::cout.tie(nullptr);
    return nullptr;
  }();
  
  class Solution {
  public:
      vector<vector<string>> groupAnagrams(vector<string>& strs) {
          unordered_map<long long, int> m;
          vector<vector<string>> res;
          int cnt = 0;
          int mo = 1e9 + 7;
          for (auto& s : strs) {
              long long xres = 1;
              for (auto c : s) {
                  xres = (xres * primes[c - 'a']) % mo;
              }
              if (m.find(xres) == m.end()) {
                  m[xres] = cnt;
                  ++cnt;
                  res.emplace_back(vector<string>{s});
              } else {
                  res[m[xres]].emplace_back(move(s));
              }
          }
          return res;
      }
  };
  ```

* 



### 54. Spiral Matrix

* 四次遍历

* ```c++
  class Solution {
  public:
      vector<int> spiralOrder(vector<vector<int>>& matrix) {
          if (matrix.size() == 0 || matrix[0].size() == 0) return {};
          int c1 = 0, c2 = matrix[0].size() - 1;
          int r1 = 0, r2 = matrix.size() - 1;
          vector<int> res;
          while (c1 <= c2 && r1 <= r2) {
              for (int i = c1; i <= c2; ++i) {
                  res.push_back(matrix[r1][i]);
              }
              ++r1;
              
              for (int i = r1; i <= r2; ++i) {
                  res.push_back(matrix[i][c2]);
              }
              --c2;
              
              if (c1 > c2 || r1 > r2) break;
              
              for (int i = c2; i >= c1; --i) {
                  res.push_back(matrix[r2][i]);
              }
              --r2;
  
              for (int i = r2; i >= r1; --i) {
                  res.push_back(matrix[i][c1]);
              }
              ++c1;
          }
          return res;
      }
  };
  ```

* 或者把direction存下来

* ```c++
  class Solution {
  public:
      vector<int> spiralOrder(vector<vector<int>> &matrix) {
          vector<int> result;
          if (matrix.empty()) return result;
          result = matrix[0];  // no need to check the first row
          int dirs[4][2] = {{1, 0}, {0, -1}, {-1, 0}, {0, 1}};  // direction offsets
          int d = 0;  // direction index
          int m = matrix.size();
          int n = matrix[0].size();
          int pos[2] = {0, n - 1};  // start from the top right corner
          int i = (m - 1) * n;  // number of the rest numbers
          while (i > 0) {
              for (int j = 1; j < m; j++) {
                  i--;
                  pos[0] += dirs[d][0]; pos[1] += dirs[d][1];
                  result.push_back(matrix[pos[0]][pos[1]]);
              }
              m--;  // decrease the size of row or column
              swap(m, n);  // switch between horizontal and vertical mode
              d = (d + 1) % 4;  // loop between direction offsets
          }
          return result;
      }
  };
  ```

* 终止条件可以用`res.size() < n * m`



### 56. Merge Intervals

* 区间合并, 按起始时间排序合并右端点 (不同于区间不相交)

* ```c++
  class Solution {
  public:
      vector<vector<int>> merge(vector<vector<int>>& intervals) {
          if (intervals.empty()) return {};
          sort(intervals.begin(), intervals.end(), [](const auto& l, const auto& r){
              return l[0] < r[0];
          });
          vector<vector<int>> res;
          auto [l, r] = tie(intervals[0][0], intervals[0][1]);
          for (const auto& x : intervals) {
              if (x[0] <= r) {
                  r = max(r, x[1]);
              } else {
                  res.push_back({l, r});
                  l = x[0];
                  r = x[1];
              }
          }
          res.push_back({l, r});
          return res;
      }
  };
  ```



### 57. Insert Interval

* 二分两端

* ```c++
  class Solution {
  public:
      using Interval = vector<int>;
      vector<Interval> insert(vector<Interval>& intervals, Interval newInterval) {
          auto compare = [] (const Interval &intv1, const Interval &intv2)
                            { return intv1[1] < intv2[0]; };
          auto range = equal_range(intervals.begin(), intervals.end(), newInterval, compare);
          // very tricky. lower_bound(..., comp) & upper_bound(..., comp), the parameter order are reversed.
          auto itr1 = range.first, itr2 = range.second;
          if (itr1 == itr2) {
              intervals.insert(itr1, newInterval);
          } else {
              itr2--;
              itr2->at(0) = min(newInterval[0], itr1->at(0));
              itr2->at(1) = max(newInterval[1], itr2->at(1));
              intervals.erase(itr1, itr2);
          }
          return intervals;
      }
  };
  ```

* ```c++
  class Solution {
  public:
      vector<vector<int>> insert(vector<vector<int>>& intervals, vector<int>& newInterval) {
          auto sit = lower_bound(intervals.begin(), intervals.end(), newInterval[0], [](const vector<int>& iv, int v){
              return iv[1] < v;
          });
          auto eit = upper_bound(intervals.begin(), intervals.end(), newInterval[1], [](int v, const vector<int>& iv){
              return v < iv[0];
          });
          if (sit == eit) {
              intervals.insert(sit, newInterval);
          } else {
              --eit;
              eit->at(0) = min(newInterval[0], sit->at(0));
              eit->at(1) = max(newInterval[1], eit->at(1));
              intervals.erase(sit, eit);
          }
          return intervals;
      }
  };
  ```

* 



### 60. Permutation Sequence

* 计数, 每次固定最早的数会有$(n-k)!$个. 注意序数要先减一

* ```c++
  class Solution {
  public:
      string getPermutation(int n, int k) {
          vector<int> fac;
          fac.push_back(1);
          for (int i = 1; i < n; ++i) {
              fac.push_back(fac.back() * i);
          }
          vector<int> nums(n, 0);
          iota(nums.begin(), nums.end(), 1);
          string res;
          k -= 1;
          for (int i = 0; i < n; ++i) {
              int sel = k / fac[n - i - 1];
              res += to_string(nums[sel]);
              nums.erase(nums.begin() + sel);
              k -= sel * fac[n - i - 1];
          }
          return res;
      }
  };
  ```

* 





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



### 76. Minimum Window Substring

* 通用解法, 快慢双指针维护窗口, `map/unordered_map`维护计数

* ```c++
  vector<int> cmap(128, 0);
          for (auto c: t) ++cmap[c];
          int counter = t.size(), begin = 0, end = 0, res = INT_MAX, head = 0;
          while (end < s.size()){
              if (cmap[s[end++]]-- > 0) counter--;
              while (counter == 0){
                  if (end - begin < res) {
                      res = end - begin;
                      head = begin;
                  }
                  if (cmap[s[begin++]]++ == 0) counter++;
              }  
          }
          return res == INT_MAX ? "" : s.substr(head, res);
  ```

* 





### 80. Remove Duplicate from Sorted Array II

* 排序过的数列, 判断`k`位之前是否相等, 维护得到最长连续`k`个相等元素的队列

* ```c++
  class Solution {
  public:
      int removeDuplicates(vector<int>& nums) {
          int k = 2;
          if (nums.size() < k) return nums.size();
          int idx = k;
          for (int i = k; i < nums.size(); ++i) {
              if (nums[idx - k] != nums[i]) {
                  nums[idx] = nums[i];
                  ++idx;
              }
          }
          return idx;
      }
  };
  ```



### 81. Search in Rotated Sorted Array II

* 二分查找, 对前有序后有序讨论, 注意边界

* ```c++
  class Solution {
  public:
      bool search(vector<int>& nums, int target) {
          int l = 0, r =  nums.size() - 1;
          
          while (l <= r) {
              int mid = l + (r - l) / 2;
              if (nums[mid] == target) return true;
              if ((nums[l] == nums[mid]) && (nums[r] == nums[mid])) {
                  ++l;
                  --r;
              } else if (nums[l] <= nums[mid]) { // left ordered
                  if ((nums[l] <= target) && nums[mid] > target) {
                      r = mid - 1;
                  } else {
                      l = mid + 1;
                  }
              } else { // right ordered
                  if ((nums[mid] < target) && nums[r] >= target) {
                      l = mid + 1;
                  } else {
                      r = mid - 1;
                  }
                  
              }
          }
          return false;
      }
  };
  ```

* 



### 84 & 85. Largest Rectangle in Histogram / Maximal Rectangle

- 先弄进去一个0保证输出, 然后裸的单调栈, 维护一个单调递增的栈, 更小的元素就不断`pop`

- ```c++
  class Solution {
  public:
      int largestRectangleArea(vector<int>& heights) {
          stack<int> m;
          heights.push_back(0);
          int res = 0;
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
  
- 最大全1矩阵, 先预处理一维(行)视为之前连续的1个数, 然后就是对每列做最大直方图

- ```c++
  class Solution {
  public:
      int maximalRectangle(vector<vector<char>>& matrix) {
          int N = matrix.size();
          if (N == 0) return 0;
          int M = matrix[0].size();
          if (M == 0) return 0;
          vector<vector<int>> rowacc(N, vector<int>(M, 0));
          for (int i = 0; i < N; ++i) {
              rowacc[i][0] = (matrix[i][0] == '1');
              for (int j = 1; j < M; ++j) {
                  if (matrix[i][j] == '0') {
                      rowacc[i][j] = 0;
                  } else {
                      rowacc[i][j] = rowacc[i][j - 1] + 1;
                  }
              }
          }
          int res = 0;
          for (int j = 0; j < M; ++j) {
              stack<int> m;
              for (int i = 0; i <= N; ++i) {
                  int current = 0;
                  if (i == N) current = 0;
                  else current = rowacc[i][j];
                  while (!m.empty() && current < rowacc[m.top()][j]) {
                      int h = m.top();
                      int k = 0;
                      m.pop();
                      if (m.empty()) {
                          k = -1;
                      } else {
                          k = m.top();
                      }
                      res = max(res, (i - k - 1) * rowacc[h][j]);
                  }
                  m.push(i);
              }
          }
          return res;
      }
  };
  ```

- DP解法

- > height[i] record the current number of countinous '1' in column i
  >
  > left[i] record the left most index j which satisfies that for any index k from j to  i, height[k] >= height[i];
  >
  > right[i] record the right most index j which satifies that for any index k from i to  j, height[k] >= height[i];
  >
  > we need to update maxArea with value (height[i] * (right[i] - left[i] + 1));
  >
  > cur_left: last 1 index starts
  >
  > cur_right: first coming 1 index

* > left(i,j) = max(left(i-1,j), cur_left), cur_left can be determined from the current row
  >
  > right(i,j) = min(right(i-1,j), cur_right), cur_right can be determined from the current row
  >
  > height(i,j) = height(i-1,j) + 1, if matrix[i][j]=='1';
  >
  > height(i,j) = 0, if matrix[i][j]=='0'

* ```c++
  class Solution {public:
  int maximalRectangle(vector<vector<char> > &matrix) {
      if(matrix.empty()) return 0;
      const int m = matrix.size();
      const int n = matrix[0].size();
      int left[n], right[n], height[n];
      fill_n(left,n,0); fill_n(right,n,n); fill_n(height,n,0);
      int maxA = 0;
      for(int i=0; i<m; i++) {
          int cur_left=0, cur_right=n; 
          for(int j=0; j<n; j++) { // compute height (can do this from either side)
              if(matrix[i][j]=='1') height[j]++; 
              else height[j]=0;
          }
          for(int j=0; j<n; j++) { // compute left (from left to right)
              if(matrix[i][j]=='1') left[j]=max(left[j],cur_left);
              else {left[j]=0; cur_left=j+1;}
          }
          // compute right (from right to left)
          for(int j=n-1; j>=0; j--) {
              if(matrix[i][j]=='1') right[j]=min(right[j],cur_right);
              else {right[j]=n; cur_right=j;}    
          }
          // compute the area of rectangle (can do this from either side)
          for(int j=0; j<n; j++)
              maxA = max(maxA,(right[j]-left[j])*height[j]);
      }
      return maxA;
  }
  ```

* 



### 87. Scramble String

* 判断字符串移位: 倍增一个, 搜索第二个

* 对每个下标判断`s1`的两部分能否由`s2`中同一位置或者对称的两部分组成. 剪枝: 小于等于3长度一定可以, 计数不相等一定不行

* ```c++
  class Solution {
      vector<array<int, 26>> s1cnt;
      vector<array<int, 26>> s2cnt;
  public:
      bool comp(pair<int, int> s1idx, pair<int, int> s2idx) {
          for (int i = 0; i < 26; ++i) {
              int c1 = s1cnt[s1idx.second][i] - s1cnt[s1idx.first][i];
              int c2 = s2cnt[s2idx.second][i] - s2cnt[s2idx.first][i];
              if (c1 != c2) return false;
          }
          return true;
      }
      
      bool helper(const string& s1, const string& s2, pair<int, int> s1idx, pair<int, int> s2idx) {
          int N = s1idx.second - s1idx.first;
          if (N == 0) return true;
          if (!comp({s1idx.first, s1idx.second}, {s2idx.first, s2idx.second})) return false;
          if (N <= 3) return true;
          if (s1.substr(s1idx.first, s1idx.second) == s2.substr(s2idx.first, s2idx.second)) return true;
          for (int i = 1; i < N; ++i) {
              if (helper(
                      s1, s2,
                      {s1idx.first, s1idx.first + i}, 
                      {s2idx.first, s2idx.first + i})
                  && 
                  helper(
                      s1, s2,
                      {s1idx.first + i, s1idx.second}, 
                      {s2idx.first + i, s2idx.second})           
                 )
                  return true;
              if (helper(
                      s1, s2,
                      {s1idx.first, s1idx.first + i}, 
                      {s2idx.second - i, s2idx.second})
                  && 
                  helper(
                      s1, s2,
                      {s1idx.first + i, s1idx.second}, 
                      {s2idx.first, s2idx.second - i})
                 )
                  return true;
          }
          return false;
      }
      
      bool isScramble(string s1, string s2) {
          int N = s1.size();
          if (!s1.length()) return true;
          if (s1 == s2) return true;
          s1cnt.resize(N + 1);
          s2cnt.resize(N + 1);
          fill(s1cnt[0].begin(), s1cnt[0].end(), 0);
          fill(s2cnt[0].begin(), s2cnt[0].end(), 0);
          
          for (int i = 0; i < N; ++i) {
              for (int j = 0; j < 26; ++j) {
                  s1cnt[i + 1][j] = s1cnt[i][j] + ((s1[i] - 'a') == j);
                  s2cnt[i + 1][j] = s2cnt[i][j] + ((s2[i] - 'a') == j);
              }
          }
          
          return helper(s1, s2, {0, N}, {0, N});       
      }
  };
  ```

* 或者对`s1`下标, `s2`下标, 长度进行dp

* ```c++
  class Solution {
  public:
      bool isScramble(string s1, string s2) {
          int sSize = s1.size(), len, i, j, k;
          if(0==sSize) return true;
          if(1==sSize) return s1==s2;
          bool isS[sSize+1][sSize][sSize];
  
          for(i=0; i<sSize; ++i)
              for(j=0; j<sSize; ++j)
                  isS[1][i][j] = s1[i] == s2[j];
                  
          for(len=2; len <=sSize; ++len)
              for(i=0; i<=sSize-len; ++i)
                  for(j=0; j<=sSize-len; ++j)
                  {
                      isS[len][i][j] = false;
                          for(k=1; k<len && !isS[len][i][j]; ++k)
                          {
                              isS[len][i][j] = isS[len][i][j] || (isS[k][i][j] && isS[len-k][i+k][j+k]);
                              isS[len][i][j] = isS[len][i][j] || (isS[k][i+len-k][j] && isS[len-k][i][j+k]);
                          }
                  }
          return isS[sSize][0][0];            
  
      }
  };
  ```






### 89. Gray Code

* 从0长开始, 每次保留k-1长 (相当于多一个0), 再倒序加入最高位变1的数 (保证每次差1)

* ```c++
  class Solution {
  public:
      vector<int> grayCode(int n) {
          vector<int> res(1, 0);
  
          for(int i = 0; i < n; ++i){
              int size = res.size();
              for(int j = size - 1; j >= 0; --j){
                  res.push_back(res[j] | (1 << i));
              }
          }
          return res;
      }
  };
  ```

* 







### 96. & 97. Unique Binary Search Trees I & II

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

* 从n-1树中生成n树

* > 1) The nth node is the new root, so `newroot->left = oldroot;`
  > 2) the nth node is not root, we traverse the old tree, every time the node in the old tree has a right child, we can perform: `old node->right = nth node, nth node ->left = right child;` and when we reach the end of the tree, don't forget we can also add the nth node here.

* 或者即为Catalan树的分治

* ```c++
  class Solution {
  public:
      vector<TreeNode *> generateTree(int from, int to) {
          vector<TreeNode*> ret;
          
          if (to - from < 0) return {nullptr};
          if (to - from == 0) return {new TreeNode{from}};
          
          for (int i = from; i <= to; ++i) {
              vector<TreeNode*> l = generateTree(from, i - 1);
              vector<TreeNode*> r = generateTree(i + 1, to);
              for (auto j : l) {
                  for (auto k : r) {
                      TreeNode * h = new TreeNode{i};
                      h->left = j;
                      h->right = k;
                      ret.push_back(h);
                  }
              }
          }
          return ret;
      }
  
      vector<TreeNode*> generateTrees(int n) {
          if (n == 0) return {};
          return generateTree(1, n);
      }
  };
  ```






### 99. Recover Binary Search Tree

* 中序遍历, 保证原BST顺序应该是从小到大, 同时维护上一个访问的节点, 第一次失配中的大节点 (`prev`), 和最后一次失配的最小节点 (`curr`), 交换大小失配节点

* ```c++
  class Solution {
  public:
      void recoverTree(TreeNode* root) {
          TreeNode* smaller = nullptr, *larger = nullptr;
          TreeNode* node = root, *prev = nullptr;
          stack<TreeNode*> s;
          while (!s.empty() || node) {
              while (node) {
                  s.push(node);
                  node = node->left;
              }
              node = s.top();
              s.pop();
              
              if (prev && node->val <= prev->val) {
                  if (!larger) larger = prev;
                  smaller = node;
              }
              
              prev = node;
              node = node->right;
          }
          swap(smaller->val, larger->val);
      }
  };
  ```

* 



### 105. & 106. Construct Binary Tree From Preorder + Inorder & Inorder + Postorder

* 或者从preorder提取第一个分治

* ```c++
  class Solution {
  public:
      TreeNode* buildTree(vector<int>& preorder, vector<int>& inorder) {
          return helper(preorder, 0, preorder.size(), inorder, 0, inorder.size());
      }
      TreeNode* helper(vector<int>& preorder,int i,int j,vector<int>& inorder,int ii,int jj) {
          if(i >= j || ii >= jj)
              return NULL;
          int mid = preorder[i];
          auto f = find(inorder.begin() + ii,inorder.begin() + jj,mid);
          int dis = f - inorder.begin() - ii;
          TreeNode* root = new TreeNode(mid);
          root->left = helper(preorder, i + 1, i + 1 + dis, inorder, ii, ii + dis);
          root->right = helper(preorder, i + 1 + dis, j, inorder, ii + dis + 1, jj);
          return root;
      }
  };
  ```

* 或者从postorder提取最后一个分治

* ```c++
  class Solution {
  public:
      TreeNode* buildTree(vector<int>& inorder, vector<int>& postorder) {
          return helper(inorder, 0, inorder.size(), postorder, 0, postorder.size());
      }
      TreeNode* helper(vector<int>& inorder,int i,int j,vector<int>& postorder,int ii,int jj) {
          if(i >= j || ii >= jj)
              return NULL;
          int mid = postorder[jj - 1];
          auto f = find(inorder.begin() + i, inorder.begin() + j, mid);
          int dis = f - inorder.begin() - i;
          TreeNode* root = new TreeNode(mid);
          root->left = helper(inorder, i, i + dis, postorder, ii, ii + dis);
          root->right = helper(inorder, i + dis + 1, j, postorder, ii + dis, jj - 1);
          return root;
      }
  };
  ```

* 





### 115. Distinct Subsequences

* `dp(i, j)`表示`0..i`的s和`0..j`的t中能有多少个subsequence, 则

* `dp(i, j) = dp(i, j - 1) or dp(i, j - 1) + dp(i - 1, j - 1)`

* 压缩一维(`i`), 并倒着求`dp(j)`来保障`dp(i - 1, j - 1)`未被修改

* ```c++
  static const auto speedup = [](){
      ios::sync_with_stdio(false);
      cin.tie(nullptr);
      return nullptr;
  }();
  
  
  class Solution {
  public:
      int numDistinct(string s, string t) {
          size_t slen = s.length();
          size_t tlen = t.length();
          vector<uint32_t> dp(tlen + 1, 0);
          dp[0] = 1;
          for (size_t i = 0; i < slen; ++i) {
              for (size_t j = tlen; j-- > 0;) {
                  if (s[i] == t[j]) {
                      dp[j+1] += dp[j];
                  }
              }
          }
          return dp[tlen];
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
    vector<int> nodes;
    stack<TreeNode*> todo;
    while (root || !todo.empty()) {
        while (root) {
            todo.push(root);
            root = root -> left;
        }
        root = todo.top();
        todo.pop();
        nodes.push_back(root -> val);
        root = root -> right;
    }
    return nodes;
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

  * 也可以直接把树的左右节点删了

  * 手动模拟栈

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



### 164. Maximum Gap

* O(N), 用桶排序划分 (鸽笼原理保证差距最大值不在桶中 -> 必定有一个空桶)

* ```c++
  class Solution {
  public:
      int maximumGap(vector<int>& nums) {
          if (nums.size() <= 1) return 0;
          int maxn = *max_element(nums.begin(), nums.end());
          int minn = *min_element(nums.begin(), nums.end());
          int size = (maxn - minn) / nums.size() + 1;
          int cnt = (maxn - minn) / size + 1;
          int res = 0;
          int pre = 0;
          vector<int> bucket_min(cnt, INT_MAX), bucket_max(cnt, INT_MIN);
          for (auto num : nums) {
              int idx = (num - minn) / size;
              bucket_min[idx] = min(bucket_min[idx], num);
              bucket_max[idx] = max(bucket_max[idx], num);
          }
          for (int i = 1; i < cnt; ++i) {
              if (bucket_min[i] == INT_MAX || bucket_max[i] == INT_MIN) continue;
              res = max(res, bucket_min[i] - bucket_max[pre]);
              pre = i;
          }
          return res;
      }
  };
  ```

* 

















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



### 321. Create Maximum Number

* 将`k`分拆成`i`和`k-i`个分别到两个序列中找`n`个最大序列

* 单调栈维护单调递减, 同时保持一个最大可`drop = size - n`数量, 为空或者`drop`为0超过上限则单调栈不再pop元素

* 合并需要考虑相同情况向后寻找

* ```c++
  class Solution {
  public:
      vector<int> maxArray(vector<int>& nums, int k) {
          int drop = nums.size() - k;
          vector<int> st;
          // monotonic stack
          for (int n : nums) {
              while (drop > 0 && !st.empty() && st.back() < n) {
                  --drop;
                  st.pop_back();
              }
              st.push_back(n);
          }
          // could be monotonically >k sequence
          st.resize(k);
          return st;
      }
      
      template <typename It, typename Comp>
      It equal_merge(It first1, It last1, It first2, It last2, It d_first, Comp cp) {
          for (; first1 != last1; ++d_first) {
              if (first2 == last2) {
                  return std::copy(first1, last1, d_first);
              }
              It copy_first1 = first1;
              It copy_first2 = first2;
              while (copy_first1 != last1 && copy_first2 != last2) {
                  if (cp(*copy_first2, *copy_first1)) {
                      *d_first = *first2;
                      ++first2;
                      break;
                  } else if (cp(*copy_first1, *copy_first2)) {
                      *d_first = *first1;
                      ++first1;
                      break;
                  }
                  ++copy_first1;
                  ++copy_first2;
              }
              if (copy_first1 == last1 || copy_first2 == last2) {
                  if (copy_first1 == last1) {
                      *d_first = *first2;
                      ++first2;
                  } else {
                      *d_first = *first1;
                      ++first1;
                  }
              }
          }
          return std::copy(first2, last2, d_first);
      }
      
      vector<int> maxNumber(vector<int>& nums1, vector<int>& nums2, int k) {
          if (k == 0) return {};
          int N = nums1.size();
          int M = nums2.size();
          auto comp = [k](const auto& l, const auto& r) {
              for (int i = 0; i < k; ++i) {
                  if (l[i] < r[i])
                      return true;
                  if (l[i] > r[i])
                      return false;
              }
              return true;
          };
          vector<int> res(k, -1);
          for (int i = 0; i <= k; ++i) {
              if (i <= N && k - i <= M) {
                  vector<int> p1 = maxArray(nums1, i);
                  vector<int> p2 = maxArray(nums2, k - i);
                  for (auto& i : p1)
                      cout << i << ' ';
                  cout << endl;
                  for (auto& i : p2)
                      cout << i << ' ';
                  cout << endl;
                  vector<int> temp(k);
                  equal_merge(p1.begin(), p1.end(), p2.begin(), p2.end(), temp.begin(), greater<int>{});
                  res = max(res, temp, comp);
              }
          }
          return res;
      }
  };
  ```

* 其他`equal_merge`的实现

* ```c++
  vector<int> equal_merge(vector<int> nums1, vector<int> nums2) {
      vector<int> out;
      auto i1 = nums1.begin(), end1 = nums1.end();
      auto i2 = nums2.begin(), end2 = nums2.end();
      while (i1 != end1 || i2 != end2)
          out.push_back(lexicographical_compare(i1, end1, i2, end2) ? *i2++ : *i1++);
      return out;
  }
  
  // vector是有built-in的比较operator的!!!!
  vector<int> equal_merge(vector<int> nums1, vector<int> nums2) {
      vector<int> out;
      while (nums1.size() + nums2.size()) {
          vector<int>& now = nums1 > nums2 ? nums1 : nums2;
          out.push_back(now[0]);
          now.erase(now.begin());
      }
      return out;
  }
  ```

* 也可以贪心的求区间内的最大值, 因为是字典序比较, 每次限定可选范围然后取最早的最大值一定是总体最优. 

* 再用一次RMQ?

* ```c++
  class Solution {
  public:
      pair<int,int> getBestIndex(vector<int>& nums, int start, int span) {
  	// get index and maximum
          int max_idx = 0, max_ = nums[start];
          for (auto i = 1; i < span; i++) {
              auto val = nums[start+i];
              if (val > max_) {
                  max_idx = i;
                  max_ = val;
                  if (max_ == 9) break;
              }
          }
          return {max_idx, max_};
      }
      
      vector<int> maxNumber(vector<int>& nums1, vector<int>& nums2, int k) {
          auto size = max(nums1.size(), nums2.size());
          vector<int> best_seq;
          vector<pair<int,int>> list_indices = {{0,0}};
          while (k--) {
              vector<pair<int,int>> next_list_indices;
              int max_ = -1;
              for (auto it = list_indices.begin(); it != list_indices.end(); it++) {
                  int n1, n2;
                  tie(n1, n2) = *it;
                  int remaining = nums1.size() + nums2.size() - n1 - n2 - k;
                  int idx1, max1 = -1, idx2, max2 = -1;
                  int end1 = nums1.size(), end2 = nums2.size();
                  if (it != list_indices.begin()) end1 = min(end1, (it-1)->first + 1);
                  if (it+1 != list_indices.end()) end2 = min(end2, (it+1)->second + 1);
                  auto remaining1 = min(remaining, end1 - n1);
                  auto remaining2 = min(remaining, end2 - n2);
                  // or just
                  /*
                  auto n1 = indices.first;
                  auto n2 = indices.second;
                  auto remaining = nums1.size() + nums2.size() - n1 - n2 - k;
                  auto remaining1 = min(remaining, nums1.size() - n1);
                  auto remaining2 = min(remaining, nums2.size() - n2);
                  */
                  if (remaining1)
                      tie(idx1, max1) = getBestIndex(nums1, n1, remaining1);
                  if (remaining2)
                      tie(idx2, max2) = getBestIndex(nums2, n2, remaining2);
                  auto max12 = max(max1, max2);
                  if (max12 < max_) continue;
                  if (max12 > max_) max_ = max12, next_list_indices.clear();
                  if (max1 >= max2 && (it == list_indices.begin() || (it-1)->first != n1+idx1+1))
                      next_list_indices.push_back({n1+idx1+1, n2});
                  if (max1 <= max2) next_list_indices.push_back({n1, n2+idx2+1});
              }
              best_seq.emplace_back(max_);
              list_indices = move(next_list_indices);
          }
          return best_seq;
      }
  }
  ```

* DP会超时

* > Let `f(i,j,k)` represent maximum number of length k generated from nums1[1:i] and nums2[1:j].
  >
  >  the formula is: `f(i,j,k) = max{f(i-1,j,k), f(i,j-1,k), f(i-1,j,k-1) + [nums1[i]], f(i,j-1,k-1) + [nums2[j]] }`

* ```python
   def maxNumber(self, nums1, nums2, k):
      """
      :type nums1: List[int]
      :type nums2: List[int]
      :type k: int
      :rtype: List[int]
      """
      m = len(nums1)
      n = len(nums2)
      if k > m + n or k <= 0:
          return []
      #kk = 0
      pre_dp = [[[] for _ in xrange(n + 1)] for __ in xrange(m + 1)]
      
      for kk in xrange(1, k + 1):
          #kk
          dp = [[[] for _ in xrange(n + 1)] for __ in xrange(m + 1)]
          #i >= kk, j = 0
          for i in xrange(kk, m + 1):
              dp[i][0] = max(pre_dp[i-1][0] + [nums1[i-1]], dp[i-1][0])
              
          #i = 0, j >= kk
          for j in xrange(kk, n + 1):
              dp[0][j] = max(pre_dp[0][j-1] + [nums2[j-1]], dp[0][j-1])
          
          #i > 0, j > 0
          for i in xrange(1, m + 1):
              for j in xrange(1, n + 1):
                  if i + j < kk:
                      continue
                  dp[i][j] = max(dp[i-1][j], \
                                  dp[i][j-1], \
                                  pre_dp[i-1][j] + [nums1[i-1]], \
                                  pre_dp[i][j-1] + [nums2[j-1]])
          pre_dp, dp = dp, pre_dp
      return pre_dp[m][n]
  ```

* 



### 378. Kth Smallest Element in a Sorted Matrix

* 二分结果并统计每列大于该元素的数量

* ```c++
  class Solution {
  public:
      int kthSmallest(vector<vector<int>>& matrix, int k) {
          int n = matrix.size();
          int l = matrix[0][0], r = matrix[n-1][n-1], mid;
          while(l < r){
              mid = l + (r - l) / 2;
              int cnt = 0, j = n - 1;
              for(int i = 0; i < n; ++i){
                  while(j >= 0 && matrix[i][j] > mid)
                      j--;
                  cnt += j+1;
              }
              if(cnt < k)
                  l = mid + 1;
              else
                  r = mid;
          }
          return l;
      }
  };
  ```

* ![1570297327462](D:\OneDrive\Pictures\Typora\1570297327462.png)

* ![1570297343761](D:\OneDrive\Pictures\Typora\1570297343761.png)

* ![1570297414638](D:\OneDrive\Pictures\Typora\1570297414638.png)

* ![1570297424654](D:\OneDrive\Pictures\Typora\1570297424654.png)

* ```c++
  class Solution {
  public:
  	int kthSmallest(const std::vector<std::vector<int>> & matrix, int k)
  	{
  		if (k == 1) // guard for 1x1 matrix
  		{
  			return matrix.front().front();
  		}
  
  		size_t n = matrix.size();
  		std::vector<size_t> indices(n);
  		std::iota(indices.begin(), indices.end(), 0);
  		std::array<size_t, 2> ks = { k - 1, k - 1 }; // use zero-based indices
  		std::array<int, 2> results = biSelect(matrix, indices, ks);
  		return results[0];
  	}
  
  private:
  	// select two elements from four elements, recursively
  	std::array<int, 2> biSelect(
  		const std::vector<std::vector<int>> & matrix,
  		const std::vector<size_t> & indices,
  		const std::array<size_t, 2> & ks)
  	// Select both ks[0]-th element and ks[1]-th element in the matrix,
  	// where k0 = ks[0] and k1 = ks[1] and n = indices.size() satisfie
  	// 0 <= k0 <= k1 < n*n  and  k1 - k0 <= 4n-4 = O(n)   and  n>=2
  	{
  		size_t n = indices.size();		
  		if (n == 2u) // base case of resursion
  		{			
  			return biSelectNative(matrix, indices, ks);
  		}
  		
  		// update indices
  		std::vector<size_t> indices_;
  		for (size_t idx = 0; idx < n; idx += 2)
  		{
  			indices_.push_back(indices[idx]);
  		}
  		if (n % 2 == 0) // ensure the last indice is included
  		{
  			indices_.push_back(indices.back());
  		}
  
  		// update ks
  		// the new interval [xs_[0], xs_[1]] should contain [xs[0], xs[1]]
  		// but the length of the new interval should be as small as possible
  		// therefore, ks_[0] is the largest possible index to ensure xs_[0] <= xs[0]
  		// ks_[1] is the smallest possible index to ensure xs_[1] >= xs[1]
  		std::array<size_t, 2> ks_ = { ks[0] / 4, 0 };
  		if (n % 2 == 0) // even
  		{
  			ks_[1] = ks[1] / 4 + n + 1;
  		}
  		else // odd
  		{
  			ks_[1] = (ks[1] + 2 * n + 1) / 4;
  		}
  
  		// call recursively
  		std::array<int, 2> xs_ = biSelect(matrix, indices_, ks_);
  
  		// Now we partipate all elements into three parts:
  		// Part 1: {e : e < xs_[0]}.  For this part, we only record its cardinality
  		// Part 2: {e : xs_[0] <= e < xs_[1]}. We store the set elementsBetween
  		// Part 3: {e : x >= xs_[1]}. No use. Discard.
  		std::array<int, 2> numbersOfElementsLessThanX = { 0, 0 };
  		std::vector<int> elementsBetween; // [xs_[0], xs_[1])
  
  		std::array<size_t, 2> cols = { n, n }; // column index such that elem >= x
  		 // the first column where matrix(r, c) > b
  		 // the first column where matrix(r, c) >= a
  		for (size_t row = 0; row < n; ++row)
  		{
  			size_t row_indice = indices[row];
  			for (size_t idx : {0, 1})
  			{
  				while ((cols[idx] > 0)
  					&& (matrix[row_indice][indices[cols[idx] - 1]] >= xs_[idx]))
  				{
  					--cols[idx];
  				}
  				numbersOfElementsLessThanX[idx] += cols[idx];
  			}
  			for (size_t col = cols[0]; col < cols[1]; ++col)
  			{
  				elementsBetween.push_back(matrix[row_indice][indices[col]]);
  			}
  		}
  
  		std::array<int, 2> xs; // the return value
  		for (size_t idx : {0, 1})
  		{
  			size_t k = ks[idx];
  			if (k < numbersOfElementsLessThanX[0]) // in the Part 1
  			{
  				xs[idx] = xs_[0];
  			}
  			else if (k < numbersOfElementsLessThanX[1]) // in the Part 2
  			{
  				size_t offset = k - numbersOfElementsLessThanX[0];
  				std::vector<int>::iterator nth = std::next(elementsBetween.begin(), offset);
  				std::nth_element(elementsBetween.begin(), nth, elementsBetween.end());
  				xs[idx] = (*nth);
  			}
  			else // in the Part 3
  			{
  				xs[idx] = xs_[1];
  			}
  		}
  		return xs;
  	}
  
  	// select two elements from four elements, using native way
  	std::array<int, 2> biSelectNative(
  		const std::vector<std::vector<int>> & matrix,
  		const std::vector<size_t> & indices,
  		const std::array<size_t, 2> & ks)
  	{
  		std::vector<int> allElements;
  		for (size_t r : indices)
  		{
  			for (size_t c : indices)
  			{
  				allElements.push_back(matrix[r][c]);
  			}
  		}
  		std::sort(allElements.begin(), allElements.end());
  		std::array<int, 2> results;
  		for (size_t idx : {0, 1})
  		{
  			results[idx] = allElements[ks[idx]];
  		}
  		return results;
  	}
  };
  
  class Solution(object):
      def kthSmallest(self, matrix, k):
  
          # The median-of-medians selection function.
          def pick(a, k):
              if k == 1:
                  return min(a)
              groups = (a[i:i+5] for i in range(0, len(a), 5))
              medians = [sorted(group)[len(group) / 2] for group in groups]
              pivot = pick(medians, len(medians) / 2 + 1)
              smaller = [x for x in a if x < pivot]
              if k <= len(smaller):
                  return pick(smaller, k)
              k -= len(smaller) + a.count(pivot)
              return pivot if k < 1 else pick([x for x in a if x > pivot], k)
  
          # Find the k1-th and k2th smallest entries in the submatrix.
          def biselect(index, k1, k2):
  
              # Provide the submatrix.
              n = len(index)
              def A(i, j):
                  return matrix[index[i]][index[j]]
              
              # Base case.
              if n <= 2:
                  nums = sorted(A(i, j) for i in range(n) for j in range(n))
                  return nums[k1-1], nums[k2-1]
  
              # Solve the subproblem.
              index_ = index[::2] + index[n-1+n%2:]
              k1_ = (k1 + 2*n) / 4 + 1 if n % 2 else n + 1 + (k1 + 3) / 4
              k2_ = (k2 + 3) / 4
              a, b = biselect(index_, k1_, k2_)
  
              # Prepare ra_less, rb_more and L with saddleback search variants.
              ra_less = rb_more = 0
              L = []
              jb = n   # jb is the first where A(i, jb) is larger than b.
              ja = n   # ja is the first where A(i, ja) is larger than or equal to a.
              for i in range(n):
                  while jb and A(i, jb - 1) > b:
                      jb -= 1
                  while ja and A(i, ja - 1) >= a:
                      ja -= 1
                  ra_less += ja
                  rb_more += n - jb
                  L.extend(A(i, j) for j in range(jb, ja))
                  
              # Compute and return x and y.
              x = a if ra_less <= k1 - 1 else \
                  b if k1 + rb_more - n*n <= 0 else \
                  pick(L, k1 + rb_more - n*n)
              y = a if ra_less <= k2 - 1 else \
                  b if k2 + rb_more - n*n <= 0 else \
                  pick(L, k2 + rb_more - n*n)
              return x, y
  
          # Set up and run the search.
          n = len(matrix)
          start = max(k - n*n + n-1, 0)
          k -= n*n - (n - start)**2
          return biselect(range(start, min(n, start+k)), k, k)[0]
  ```

* [Selection in X + Y and Matrices with sorted rows and columns](http://www.cse.yorku.ca/~andy/pubs/X+Y.pdf)





### 410. Split Array Largest Sum

* 连续的数列, 有上下界的问题, 考虑二分 + 贪心

* 最小: 元素最大值, 最大: 元素和, 二分贪心求出最小最大和

* 注意溢出

* ```c++
  class Solution {
  public:
      int splitArray(vector<int>& nums, int m) {
          int N = nums.size();
          long long sum = accumulate(nums.begin(), nums.end(), 0ll);
          long long l = *max_element(nums.begin(), nums.end());
          long long r = sum;
          while (l < r) {
              long long mid = l + (r - l) / 2;
              long long cur_sum = 0;
              int cur_group = 0;
              int can_divide = true;
              for (int i = 0; i < N; ++i) {
                  if (cur_sum + nums[i] <= mid) {
                      cur_sum += nums[i];
                  } else {
                      cur_sum = nums[i];
                      ++cur_group;
                      if (cur_group > m) {
                          can_divide = false;
                          break;
                      }
                  }
              }
              if (cur_sum != 0)
                  ++cur_group;
              if (cur_group > m) {
                  can_divide = false;
              }
              if (can_divide) {
                  r = mid;
              } else {
                  l = mid + 1;
              }
          }
          return l;
      }
  };
  ```

* > `dp[s,j]` is the solution for splitting subarray `n[j]...n[L-1]` into `s` parts.
  >
  > `dp[s+1,i] = min{ max(dp[s,j], n[i]+...+n[j-1]) }, i+1 <= j <= L-s`









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



### 456. 132 Pattern

* 倒着构造单调递减栈, 保存`a_k` 为单调栈最后一次弹出的元素, 则存在`a_i`小于`a_k`则单调栈中必定有比`a_k`大的且存在于`i, k`之间的`a_j`. 实际上`a_k`维护了栈中最大数的后继中比最大数小的最远数

* ```c++
  class Solution {
  public:
      bool find132pattern(vector<int>& nums) {
          int s3 = INT_MIN;
          stack<int> st;
          for (int i = nums.size() - 1; i >= 0; --i) {
              if (nums[i] < s3) return true;
              else {
                  while(!st.empty() && nums[i] > st.top()){ 
                      s3 = st.top();
                      st.pop(); 
                  }
              }
              st.push(nums[i]);
          }
          return false;
      }
  };
  ```

* 











### 465. Optimal Account Balancing

* 权限题

* > 一群朋友去度假，有时会互相借钱。例如，Alice为Bill的午餐买单，花费$10。然后Chris给Alice $5打车费。我们可以将每一笔交易模型化为一个三元组 (x, y, z)，意思是x给y花费$z。假设Alice, Bill和Chris分别标号0,1,2，以上交易可以表示为[[0, 1, 10], [2, 0, 5]]。
  >
  > 给定一群人的交易列表，返回结清债务关系的最小交易数

* > ```
  > 统计每个人借出/借入的金钱总数
  > 
  > 将借出金钱的人放入集合rich，借入金钱的人放入集合poor
  > 
  > 问题转化为计算从rich到poor的最小“债务连线”数
  > 
  > 尝试用rich中的每个金额与poor中的每个金额做匹配
  > 
  > 若存在差值，则将差值加入相应集合继续搜索
  > 
  > 通过保存中间计算结果可以减少重复搜索
  > ```

* > ```c++
  > 
  > class Solution {
  > public:
  >     int minTransfers(vector<vector<int>>& transactions) {
  >         unordered_map<int, int> mp;
  >         for (auto x : transactions) {
  >             mp[x[0]] -= x[2];
  >             mp[x[1]] += x[2];
  >         }
  >         vector<int> in;
  >         vector<int> out;
  >         for (auto x : mp) {
  >             if (x.second < 0) out.push_back(-x.second);
  >             else if (x.second > 0) in.push_back(x.second);
  >         }
  >         int amount = 0;
  >         for (auto x : in) amount += x;
  >         if (amount == 0) return 0;
  >         int res = (int)in.size() + (int)out.size() - 1;
  >         dfs(in, out, 0, 0, amount, 0, res);
  >         return res;
  >     }
  >     
  >     void dfs(vector<int> &in, vector<int> &out, int i, int k, 
  >              int amount, int step, int &res) {
  >         if (step >= res) return;
  >         if (amount == 0) {
  >             res = step;
  >             return;
  >         }
  >         if (in[i] == 0) {
  >             ++i;
  >             k = 0;
  >         }
  >         for (int j = k; j < out.size(); j++) {
  >             int dec = min(in[i], out[j]);
  >             if (dec == 0) continue;
  >             in[i] -= dec;
  >             out[j] -= dec;
  >             dfs(in, out, i, j + 1, amount - dec, step + 1, res);
  >             in[i] += dec;
  >             out[j] += dec;
  >         }
  >     }
  > };
  > 1
  > 2
  > 3
  > 4
  > 5
  > 6
  > 7
  > 8
  > 9
  > 10
  > 11
  > 12
  > 13
  > 14
  > 15
  > 16
  > 17
  > 18
  > 19
  > 20
  > 21
  > 22
  > 23
  > 24
  > 25
  > 26
  > 27
  > 28
  > 29
  > 30
  > 31
  > 32
  > 33
  > 34
  > 35
  > 36
  > 37
  > 38
  > 39
  > 40
  > 41
  > 42
  > 43
  > 44
  > class Solution {
  > public:
  >     int minTransfers(vector<vector<int>>& transactions) {
  >         unordered_map<int, int> mp;
  >         for (auto x : transactions) {
  >             mp[x[0]] -= x[2];
  >             mp[x[1]] += x[2];
  >         }
  >         vector<int> in;
  >         vector<int> out;
  >         for (auto x : mp) {
  >             if (x.second < 0) out.push_back(-x.second);
  >             else if (x.second > 0) in.push_back(x.second);
  >         }
  >         int amount = 0;
  >         for (auto x : in) amount += x;
  >         if (amount == 0) return 0;
  >         int res = (int)in.size() + (int)out.size() - 1;
  >         dfs(in, out, 0, 0, amount, 0, res);
  >         return res;
  >     }
  >     
  >     void dfs(vector<int> &in, vector<int> &out, int i, int k, 
  >              int amount, int step, int &res) {
  >         if (step >= res) return;
  >         if (amount == 0) {
  >             res = step;
  >             return;
  >         }
  >         if (in[i] == 0) {
  >             ++i;
  >             k = 0;
  >         }
  >         for (int j = k; j < out.size(); j++) {
  >             int dec = min(in[i], out[j]);
  >             if (dec == 0) continue;
  >             in[i] -= dec;
  >             out[j] -= dec;
  >             dfs(in, out, i, j + 1, amount - dec, step + 1, res);
  >             in[i] += dec;
  >             out[j] += dec;
  >         }
  >     }
  > };
  > ```
  >
  > 



 



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
          cout << "x: " << x << " [" << y_down << ", " << y_up << "] " << acc << "\n";
      }
  };
  struct SegTree {
    	vector<SegTreeNode> nodes;
      SegTree(int n) {
          nodes.resize(1 << n);
      }
      void build(int i, int l, int r, const vector<int>& yvalue) {
          nodes[i] = {0, yvalue[l], yvalue[r], false, 0};
          if (l + 1 == r) {
              nodes[i].is_leaf = true;
              return;
          }
          int mid = (l + r) >> 1;
          build(2 * i, l, mid, yvalue);
          build(2 * i + 1, mid, r, yvalue);
      }
      long long insert(int i, const Segment& seg) {
          if (seg.y_up <= nodes[i].y_down || seg.y_down >= nodes[i].y_up) return 0;
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
      int rectangleArea(vector<vector<int>>& rectangles) {
      	vector<int> yvalue;
          yvalue.push_back(-1); // for fill 0;
          vector<Segment> lines;
          for (auto& l : rectangles) {
              yvalue.push_back(l[1]);
              yvalue.push_back(l[3]);
              lines.emplace_back(Segment{l[0], l[1], l[3], true});
              lines.emplace_back(Segment{l[2], l[1], l[3], false});
          }
          sort(yvalue.begin(), yvalue.end());
          auto it = unique(yvalue.begin(), yvalue.end());
          yvalue.erase(it, yvalue.end());
          sort(lines.begin(), lines.end(), [](const auto& l, const auto& r){
              return l.x < r.x;
          });
          SegTree tree{8};
          tree.build(1, 1, yvalue.size() - 1, yvalue);
          long long ans = 0;
          for (auto& l : lines) {
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



### 865. Smallest Subtree with all the Deepest Nodes

* 一遍返回`(maxDepth, maxDepthNodesLCA)`

* ```c++
  class Solution {
  public:
      TreeNode* subtreeWithAllDeepest(TreeNode* root) {
          return deep(root).second;
      }
  
      pair<int, TreeNode*> deep(TreeNode* root) {
          if (!root) return {0, NULL};
          pair<int, TreeNode*> l = deep(root->left), r = deep(root->right);
  
          int d1 = l.first, d2 = r.first;
          return {max(d1, d2) + 1, d1 == d2 ? root : d1 > d2 ? l.second : r.second};
      }
  };
  ```

* BFS得到最左最右的最深节点, 做LCA

* ```c++
  class Solution {
  public:
      TreeNode* lca( TreeNode* root, TreeNode* p, TreeNode* q ) {
          if ( !root || root == p || root == q ) return root;
          TreeNode *left = lca( root->left, p, q );
          TreeNode *right = lca (root->right, p, q );
  
          return !left? right: !right? left: root;
      }
      
      TreeNode* subtreeWithAllDeepest(TreeNode* root) {
          if ( !root || !root->left && !root->right ) return root;
          TreeNode *leftMost = NULL;
          TreeNode *rightMost = NULL;
          
          queue<TreeNode*> q;
          q.push(root);
          while( !q.empty() ) {
              int levelSize = q.size();
              for(int level = 0; level < levelSize; level++ ) {
                  TreeNode* node = q.front(); q.pop();
                  if ( level == 0 ) leftMost = node;
                  if ( level == levelSize - 1 ) rightMost = node;
                  
                  if (node->left) q.push(node->left);
                  if (node->right) q.push(node->right);
                  
              }
          }
          return lca( root, leftMost, rightMost );
      }
  };
  ```

* 







### 903. Valid Permutations for DI Sequence

* $dp(i, j)$表示前$i + 1$个字符已满足情况下最后一个数位是$j + 1$的排列数, 每轮可用的上轮排列数都应递减1, 满足组合数要求

* $dp(i + 1, j) = \sum_{k = 0 \or i - 1}^{j - 1 \or j} dp(i, k)$, $j$ from $(0, n - i - 1)$, 可做前缀和

* ![image](D:\OneDrive\Pictures\Typora\image_1536486527.png)

* ```c++
  class Solution {
  public:
      int numPermsDISequence(string S) {
          int n = S.length(), mod = 1e9 + 7;
          vector<vector<int>> dp(n + 1, vector<int>(n + 1));
          for (int j = 0; j <= n; j++) dp[0][j] = 1;
          for (int i = 0; i < n; i++) {
              if (S[i] == 'I') {
                  for (int j = 0, last = 0; j < n - i; ++j) {
                      dp[i + 1][j] = (last + dp[i][j]) % mod;
                      last = dp[i + 1][j];
                  }
              } else {
                  for (int j = n - i - 1, last = 0; j >= 0; --j) {
                      dp[i + 1][j] = (last + dp[i][j + 1]) % mod;
                      last = dp[i + 1][j];
                  }
              }
          }
          return dp[n][0];
      }
  };
  ```




### 957. Prison Cells After N Days

* 局面数不超过64, 直接模拟找出循环节

* ```c++
  class Solution {
  public:
      vector<int> prisonAfterNDays(vector<int>& cells, int N) {
          int n = cells.size(), cycle = 0;
          vector<int> cur(n, 0), direct;
          while(N-- > 0) {
              for(int i = 1; i < n - 1; ++i) cur[i] = cells[i - 1] == cells[i + 1];
              if(direct.empty()) direct = cur;
              else if(direct == cur) N %= cycle;
              ++cycle;
              cells = cur;
          }
          return cur;
      }
  };
  ```

* 然而循环节最长为14, 证明?

* > The main reason is that the values of the 1st, 3rd, 5th and 7th number in the array before an iteration completely determine the values of the 2nd, 4th, 6th and 8th number after an iteration. Similiarly, the values of the 2nd, 4th, 6th and 8th number before an iteration completely determine the values of the 1st, 3rd, 5th and 7th number after the iteration.
  >
  > 
  >
  > To see this, take as example the 5th number (odd). After an iteration its value will depend only on the before-iteration value of the 4th and 6th number (even).
  >
  > 
  >
  > After one iteration, the 1st and 8th number are 0 and stay that way. So after one iteration, the array looks like:
  >
  > 
  >
  > - 0x?y?z?0.
  >
  > 
  >
  > After one more iteration the values of x,y and z (2nd, 4th and 6th array element) completely determine the non-? values given here (r,s and t):
  >
  > 
  >
  > - 0?r?s?t0.
  >
  > 
  >
  > After one more iteration, those values (r,s and t) determine again the new (2nd, 4th and 6th array element):
  >
  > 
  >
  > - 0x′?y′?z′?0.
  >
  > 
  >
  > What this shows, is that after two iterations of the cycle, x, y, and z determine the values of x', y', and z', and are **independent of the in between values.**
  >
  > 
  >
  > The same can be said of course for the remaining 3 values (above shown as ?,).
  >
  > 
  >
  > So from the original 8-bit data set, 2 bits immediately become and stay 0. (the ends). Then 2 sets of 3 bits of data remain that, after 2 iterations, determine the "next" value of the exact same 3 bits of data. (xyz determine x'y'z' after two iterations and rst determine r's't' after 2 iterations. x,y,z does not depend on rst looking at it every two iterations.)
  >
  > 
  >
  > So those 2 sets of 3 bit data have a maximal cycle length of 8 (2^3 = 8). Because we need two of our iterations for one step in the 3-bit cycle, that makes a maximal iteration count of 16.
  >
  > 
  >
  > Now to get to the 14 iterations...
  >
  > 
  >
  > what's needed is to actually write down those cycles of the 3 bit data. It turns out that it's one cycle of 7 steps and one 1 cyle of 1 step.
  >
  > 
  >
  > You get the 1 step cycle if you start with (this is one step remember, because each step is 2 iterations for each set of data)
  >
  > 
  >
  > - 00?0?1?0,
  >
  > 
  >
  > then the next iteration will be
  >
  > 
  >
  > - 0?1?0?00
  >
  > 
  >
  > and the next one will be (again)
  >
  > 
  >
  > - 00?0?1?0.
  >
  > 
  >
  > If you start with any other configuration, you will find the 7-step cycle. As 1 step is two iterations, this explains the max 14 iterations. Therefore, 7 is the max cycle and there are two sets, which make 14 total.









### 973. K Closest Points to Origin

* Top K问题

  * quickselect
  * min-heap

* ```c++
  class Solution {
  public:
      vector<vector<int>> kClosest(vector<vector<int>>& points, int K) {
          int N = points.size();
          int l = 0, r = N - 1, remain = K;
          while (l < r) {
              auto pivot = points[r];
              auto dis = [](const vector<int>& em) -> long long {
                  return (long long)em[0] * em[0] + em[1] * em[1];
              };
              auto first_not_less_equal_it = partition(points.begin() + l, points.begin() + r, [&](const auto& em) {
                  return dis(em) <= dis(pivot);
              });
              iter_swap(points.begin() + r, first_not_less_equal_it);
              int n_less_equal = distance(points.begin(), first_not_less_equal_it);
              if (n_less_equal == K) {
                  break;
              } else if (n_less_equal > K) {
                  r = n_less_equal - 1;
              } else {
                  l = n_less_equal + 1;
              }
          }
          return {points.begin(), points.begin() + K};
      }
  };
  ```

* 学会`partial_sort`和`nth_element`

* ```c++
  class Solution {
  public:
      vector<vector<int>> kClosest(vector<vector<int>>& points, int K) {
          partial_sort(points.begin(), points.begin() + K, points.end(), [](vector<int>& p, vector<int>& q) {
              return p[0] * p[0] + p[1] * p[1] < q[0] * q[0] + q[1] * q[1];
          });
          return vector<vector<int>>(points.begin(), points.begin() + K);
      }
  };
  
  class Solution {
  public:
      vector<vector<int>> kClosest(vector<vector<int>>& points, int K) {
          nth_element(points.begin(), points.begin() + K - 1, points.end(), [](vector<int>& p, vector<int>& q) {
              return p[0] * p[0] + p[1] * p[1] < q[0] * q[0] + q[1] * q[1];
          });
          return vector<vector<int>>(points.begin(), points.begin() + K);
      }
  };
  
  class Solution {
  public:
      vector<vector<int>> kClosest(vector<vector<int>>& points, int K) {
          priority_queue<vector<int>, vector<vector<int>>, compare> pq;
          for (vector<int>& point : points) {
              pq.push(point);
              if (pq.size() > K) {
                  pq.pop();
              }
          }
          vector<vector<int>> ans;
          while (!pq.empty()) {
              ans.push_back(pq.top());
              pq.pop();
          }
          return ans;
      }
  private:
      struct compare {
          bool operator()(vector<int>& p, vector<int>& q) {
              return p[0] * p[0] + p[1] * p[1] < q[0] * q[0] + q[1] * q[1];
          }
      };
  };
  
  class Solution {
  public:
      vector<vector<int>> kClosest(vector<vector<int>>& points, int K) {
          multiset<vector<int>, compare> mset(points.begin(), points.end());
          vector<vector<int>> ans;
          copy_n(mset.begin(), K, back_inserter(ans));
          return ans;
      }
  private:
      struct compare {
          bool operator()(const vector<int>& p, const vector<int>& q) const {
              return p[0] * p[0] + p[1] * p[1] < q[0] * q[0] + q[1] * q[1];
          }
      };
  };
  
  class Solution {
  public:
      vector<vector<int>> kClosest(vector<vector<int>>& points, int K) {
          int l = 0, r = points.size() - 1;
          while (true) {
              int p = partition(points, l, r);
              if (p == K - 1) {
                  break;
              }
              if (p < K - 1) {
                  l = p + 1;
              } else {
                  r = p - 1;
              }
          }
          return vector<vector<int>>(points.begin(), points.begin() + K);
      }
  private:
      bool farther(vector<int>& p, vector<int>& q) {
          return p[0] * p[0] + p[1] * p[1] > q[0] * q[0] + q[1] * q[1];
      }
      
      bool closer(vector<int>& p, vector<int>& q) {
          return p[0] * p[0] + p[1] * p[1] < q[0] * q[0] + q[1] * q[1];
      }
      
      int partition(vector<vector<int>>& points, int left, int right) {
          int pivot = left, l = left + 1, r = right;
          while (l <= r) {
              if (farther(points[l], points[pivot]) && closer(points[r], points[pivot])) {
                  swap(points[l++], points[r--]);
              }
              if (!farther(points[l], points[pivot])) {
                  l++;
              }
              if (!closer(points[r], points[pivot])) {
                  r--;
              }
          }
          swap(points[pivot], points[r]);
          return r;
      }
  };
  ```

* 









### 992. Subarrays with K Different Integers

* 滑动窗口 + 双指针, 维护窗口内不同的字符个数. 统计所有不超过`K`个 - 不超过`K-1`个

* ```c++
  static const int __ = []() {
      std::ios::sync_with_stdio(false);
      std::cin.tie(nullptr);
      std::cout.tie(nullptr);
      return 0;
  }();
  
  class Solution {
  public:
      int subarraysWithKDistinct(vector<int>& A, int K) {
          return atMostK(A, K) - atMostK(A, K - 1);        
      }
      int atMostK(vector<int>& A, int K) {
          int i = 0, res = 0;
          map<int, int> count;
          for (int j = 0; j < A.size(); ++j) {
              if (count[A[j]] == 0) --K;
              ++count[A[j]];
              while (K < 0) {
                  --count[A[i]];
                  if (count[A[i]] == 0) ++K;
                  ++i;
              }
              res += j - i + 1;
          }
          return res;
      }
  };
  ```

* 只做一遍, 用`i`, `j`维护窗口右端点(看到的最新值)和窗口左端点(最后一个仅出现一次的值), `prefix`表示这段长度

* > If the subarray `[j, i]` contains `K` unique numbers, and first `prefix` numbers also appear in `[j + prefix, i]` subarray, we have total `1 + prefix` good subarrays. For example, there are 3 unique numers in `[1, 2, 1, 2, 3]`. First two numbers also appear in the remaining subarray `[1, 2, 3]`, so we have 1 + 2 good subarrays: `[1, 2, 1, 2, 3]`, `[2, 1, 2, 3]` and `[1, 2, 3]`.
  >
  > 
  >
  > We can iterate through the array and use two pointers for our sliding window (`[j, i]`). The back of the window is always the current position in the array (`i`). The front of the window (`j`) is moved so that A[j] appear only once in the sliding window. In other words, we are trying to shrink our sliding window while maintaining the same number of unique elements.
  >
  > 
  >
  > To do that, we keep tabs on how many times each number appears in our window (`m`). After we add next number to the back of our window, we try to remove as many as possible numbers from the front, until the number in the front appears only once. While removing numbers, we are increasing `prefix`.
  >
  > 
  >
  > If we collected `K` unique numbers, then we found 1 + `prefix` sequences, as each removed number would also form a sequence.
  >
  > 
  >
  > If our window reached `K + 1` unique numbers, we remove one number from the head (again, that number appears only in the front), and reset `prefix` as now we are starting a new sequence. This process is demonstrated step-by-step for the test case below; `prefix` are shown as `+1` in the green background.

* ```c++
  static const int __ = []() {
      std::ios::sync_with_stdio(false);
      std::cin.tie(nullptr);
      std::cout.tie(nullptr);
      return 0;
  }();
  
  class Solution {
  public:
      int subarraysWithKDistinct(vector<int>& A, int K) {
          vector<int> m(A.size() + 1);
          int res = 0;
          for (auto i = 0, j = 0, prefix = 0, count = 0; i < A.size(); ++i) {
              // new distinct
              if (m[A[i]]++ == 0) {
                  ++count;
              }
              // exceed K
              if (count > K) {
                  --m[A[j++]];
                  --count;
                  prefix = 0;
              }
              // increase prefix
              while (m[A[j]] > 1) {
                  ++prefix;
                  --m[A[j++]];
              }
              if (count == K) {
                  res += prefix + 1;
              }
          }
          return res;        
      }
  };
  ```

* 带更新的`priority_queue`?







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





### 1140. Stone Game II

* 先后拿 最多 -> 总和 + 差值 最多 -> 差值最大

* `dp(i, m) = max{-dp(i + k, max(m, k)) + p[i] + ... + p[i + k - 1]} 1 <= k <= remain`

* 前缀和

* ```c++
  class Solution {
  public:
      int stoneGameII(vector<int>& piles) {
          int N = piles.size();
          int s = 0;
          vector<int> prefixsum(N + 1, 0);
          int idx = 0;
          for (auto& i : piles) {
              s += i;
              prefixsum[idx + 1] = s;
              ++idx;
          }
          vector<vector<int>> dp(N + 1, vector<int>(N + 1, 0));
          for (int i = 0; i < N + 1; ++i) {
              dp[N][i] = 0;
          }
          for (int i = N - 1; i >= 0; --i) {
              for (int j = 1; j < N; ++j) {
                  int opt = min(2 * j + 1, N - i + 1);
                  dp[i][j] = -dp[i + 1][max(j, 1)] + piles[i];
                  for (int k = 1; k < opt; ++k) {
                      dp[i][j] = max(-dp[i + k][max(j, k)] + prefixsum[i + k] - prefixsum[i], dp[i][j]);
                  }
              }
          }
          return (s + dp[0][1]) / 2;
      }
  };
  ```






### 1157. Online Majority Elements In Subarray

* 区间多数值

* 统计每个值的出现下标, 每次询问多次随机选择区间内一点, 判断是否对应值为多数值 (个数超过一半), 生日理论保证可行性

* ```c++
  class MajorityChecker {
  public:
      vector<int> x;
      vector<int> v[20001];
      MajorityChecker(vector<int>& arr) {
          x = arr;
          for (int i = 1; i <= 20000; i++)
              v[i].clear();
          for (int i = 0; i < x.size(); i++) {
              v[x[i]].push_back(i);
          }
          srand(time(0));
      }
      
      int query(int left, int right, int threshold) {
          int l = right - left + 1;
          for (int i = 0; i < 30; i++) {
              int tmp = x[rand() % l + left];
              if (upper_bound(v[tmp].begin(), v[tmp].end(), right) - lower_bound(v[tmp].begin(), v[tmp].end(), left) >= threshold)
                  return tmp;
          }
          return -1;
      }
  };
  
  /**
   * Your MajorityChecker object will be instantiated and called as such:
   * MajorityChecker* obj = new MajorityChecker(arr);
   * int param_1 = obj->query(left,right,threshold);
   */
  ```

* 区间查询 (单点更新) -> 线段树, 每个区间无多数值则为-1, 否则从左右孩子中选择多数值作为区间值 (这里更新成nlog^2n了, 应该存下多数值的个数的). 查询时, 当一个区间被查询区间包含的时候, 则这个多数值为备选值, 重新二分来验证

* ```c++
  class MajorityChecker {
  private:
      unordered_map<int, vector<int>> pos;
      vector<int> tree;
      vector<int> a;
      
  public:
      MajorityChecker(vector<int>& arr): a(arr) {
          for (int i = 0; i < arr.size(); ++i) {
              pos[arr[i]].push_back(i);
          }
          tree = vector<int>(arr.size() * 4, -1);
          build_tree(1, 0, arr.size() - 1);
      }
      
      void build_tree(int tree_pos, int l, int r) {
          if (l == r) {
              tree[tree_pos] = a[l];
              return;
          }
          int mid = (l + r) >> 1;
          build_tree(tree_pos * 2, l, mid);
          build_tree(tree_pos * 2 + 1, mid + 1, r);
          if (tree[tree_pos * 2] != -1 && get_occurrence(tree[tree_pos * 2], l, r) * 2 > r - l + 1) {
              tree[tree_pos] = tree[tree_pos * 2];
          }
          else if (tree[tree_pos * 2 + 1] != -1 && get_occurrence(tree[tree_pos * 2 + 1], l, r) * 2 > r - l + 1) {
              tree[tree_pos] = tree[tree_pos * 2 + 1];
          }
      }
      
      pair<int, int> query(int tree_pos, int l, int r, int queryl, int queryr) {
          if (l > queryr || r < queryl) {
              return make_pair(-1, -1);
          }
          if (queryl <= l && r <= queryr) {
              if (tree[tree_pos] == -1) {
                  return make_pair(-1, -1);
              }
              int occ = get_occurrence(tree[tree_pos], queryl, queryr);
              if (occ * 2 > queryr - queryl + 1) {
                  return make_pair(tree[tree_pos], occ);
              }
              else {
                  return make_pair(-1, -1);
              }
          }
          int mid = (l + r) >> 1;
          pair<int, int> res_l = query(tree_pos * 2, l, mid, queryl, queryr);
          if (res_l.first > -1) {
              return res_l;
          }
          pair<int, int> res_r = query(tree_pos * 2 + 1, mid + 1, r, queryl, queryr);
          if (res_r.first > -1) {
              return res_r;
          }
          return make_pair(-1, -1);
      }
      
      int get_occurrence(int num, int l, int r) {
          auto iter = pos.find(num);
          if (iter == pos.end()) {
              return 0;
          }
          const auto& vec = iter->second;
          auto iter_l = lower_bound(vec.begin(), vec.end(), l);
          if (iter_l == vec.end()) {
              return 0;
          }
          auto iter_r = upper_bound(vec.begin(), vec.end(), r);
          return iter_r - iter_l;
      }
      
      int query(int left, int right, int threshold) {
          pair<int, int> ans = query(1, 0, a.size() - 1, left, right);
          if (ans.second >= threshold) {
              return ans.first;
          }
          return -1;
      }
  };
  ```

* 分块, 对每个块找出多数值, 这些必定是所有的候选项 (否则, 和肯定小于总数的一半)

* ```c++
  class MajorityChecker {
  private:
      unordered_map<int, vector<int>> pos;
      vector<int> a;
      vector<int> bucket;
      int bucket_size;
      
      
  public:
      MajorityChecker(vector<int>& arr): a(arr) {
          for (int i = 0; i < arr.size(); ++i) {
              pos[arr[i]].push_back(i);
          }
          bucket_size = round(sqrt(a.size()));
          int l = 0;
          while (l < a.size()) {
              int r = min(l + bucket_size, (int)a.size()) - 1;
              bucket.push_back(vote(l, r));
              l += bucket_size;
          }
      }
      
      int vote(int l, int r) {
          int target = a[l], occ = 1;
          for (int i = l + 1; i <= r; ++i) {
              if (a[i] == target) {
                  ++occ;
              }
              else {
                  --occ;
                  if (occ < 0) {
                      target = a[i];
                      occ = 1;
                  }
              }
          }
          int cnt = 0;
          for (int i = l; i <= r; ++i) {
              if (a[i] == target) {
                  ++cnt;
              }
          }
          if (cnt * 2 > r - l + 1) {
              return target;
          }
          return -1;
      }
      
      int get_occurrence(int num, int l, int r) {
          auto iter = pos.find(num);
          if (iter == pos.end()) {
              return 0;
          }
          const auto& vec = iter->second;
          auto iter_l = lower_bound(vec.begin(), vec.end(), l);
          if (iter_l == vec.end()) {
              return 0;
          }
          auto iter_r = upper_bound(vec.begin(), vec.end(), r);
          return iter_r - iter_l;
      }
      
      int query(int left, int right, int threshold) {
          int bucket_l = left / bucket_size;
          int bucket_r = right / bucket_size;
          if (bucket_l == bucket_r) {
              int candidate = vote(left, right);
              if (candidate != -1 && get_occurrence(candidate, left, right) >= threshold) {
                  return candidate;
              }
              return -1;
          }
          else {
              int vote_l = vote(left, (bucket_l + 1) * bucket_size - 1);
              int vote_r = vote(bucket_r * bucket_size, right);
              if (vote_l != -1 && get_occurrence(vote_l, left, right) >= threshold) {
                  return vote_l;
              }
              if (vote_r != -1 && get_occurrence(vote_r, left, right) >= threshold) {
                  return vote_r;
              }
              for (int i = bucket_l + 1; i < bucket_r; ++i) {
                  int occ = get_occurrence(bucket[i], left, right);
                  if (occ >= threshold) {
                      return bucket[i];
                  }
              }
              return -1;
          }
      }
  };
  ```

* 主席树

* ```python
  class Solution:
      def __init__(self, arr):
          """
          :type arr: List[int]
          """
          self.t = []
          self.h = []
          self.l = min(arr)
          self.r = max(arr)
  
          self.t.append({"v": 0, "l": 0, "r": 0})
          self.h.append(0)
          n = len(arr)
          for i in range(n):
              x = arr[i]
              l, r = self.l, self.r
              now = self.h[i]
              self.h.append(len(self.t))
              while True:
                  rec = self.t[now]
                  tmp = {"v": rec["v"] + 1}
                  self.t.append(tmp)
                  if l < r:
                      o = (l + r) >> 1
                      if x <= o:
                          tmp["l"] = len(self.t)
                          tmp["r"] = rec["r"]
                          r = o
                          now = rec["l"]
                      else:
                          tmp["l"] = rec["l"]
                          tmp["r"] = len(self.t)
                          l = o + 1
                          now = rec["r"]
                  else:
                      break
  
      def query(self, left, right, threshold):
          """
          :type left: int
          :type right: int
          :type threshold: int
          :rtype: int
          """
          l = self.l
          r = self.r
          u = self.h[left]
          v = self.h[right + 1]
          while True:
              if self.t[v]["v"] - self.t[u]["v"] < threshold:
                  return -1
              if l == r:
                  return l
              o = (l + r) >> 1
              if self.t[self.t[v]["l"]]["v"] - self.t[self.t[u]["l"]]["v"] >= threshold:
                  r, u, v = o, self.t[u]["l"], self.t[v]["l"]
              else:
                  l, u, v = o + 1, self.t[u]["r"], self.t[v]["r"]
  
                          
  ```

* 树套树 (树状数组 + 线段树)

* ```c++
  const int MAXN=2e4+50;
  const int MAXM=2e4;
  
  struct BTree{ int ch[2], sum; }node[MAXN*100];
  int root[MAXN], numn, PL, PR;
  
  inline int lowbit(int x){ return x&-x; }
  
  void init(){ 
      numn=0;
      memset(root, 0, sizeof(root));
  }
  
  void insertNode(int &x, int l, int r, int p){
      if (!x) { x=++numn; node[x].ch[0]=node[x].ch[1]=node[x].sum=0; }
  
      ++node[x].sum;
  
      if (l<r){
          int m=(l+r)/2;
          if (p<=m){
              insertNode(node[x].ch[0], l, m, p);
          }else insertNode(node[x].ch[1], m+1, r, p);
      }
  }
  
  void insertTree(int p, int v){
      for (int i=v; i<=MAXM; i+=lowbit(i)) 
          insertNode(root[i], PL, PR, p);
  }
  
  int queryNode(int x, int l, int r, int left, int right){
      if (!x) return 0;
      if (left<=l && r<=right) return node[x].sum;
  
      int m=(l+r)/2, ret=0;
      if (left<=m) ret+=queryNode(node[x].ch[0], l, m, left, right);
      if (m+1<=right) ret+=queryNode(node[x].ch[1], m+1, r, left, right);
  
      return ret;
  }
  
  int queryTree(int left, int right, int v){
      int ret=0;
      for (int i=v; i>0; i-=lowbit(i))
          ret+=queryNode(root[i], PL, PR, left, right);
      return ret;
  }
  
  class MajorityChecker {
  public:
      MajorityChecker(vector<int>& a) {
          PL=0, PR=a.size()-1;
          init();
          for (int i=PL; i<=PR; i++) insertTree(i, a[i]);
      }
      
      int query(int left, int right, int threshold) {
          int ans=0, now=32768/2, k=threshold;
          while(now){
              if (now+ans>MAXM) { now/=2; continue; }
              int v=queryNode(root[ans+now], PL, PR, left, right);
              if (v<k) { k-=v; ans+=now; }
              now/=2;
          }
          
          int cnt=queryTree(left, right, ans+1) - queryTree(left, right, ans);
          return cnt>=threshold?ans+1:-1;
      }
  };
  ```

* 









### 1178. Number of Valid Words for Each Puzzle

* 预处理, 数位hashmap

  * lowercase character -> 1 << 26 hashmap大小
  * pattern length == 7 -> 1 << 7 pattern类型, 直接把pattern计数排序

* ```c++
  class Solution {
  public:
      vector<int> findNumOfValidWords(vector<string>& words, vector<string>& puzzles) {
          vector<int> first[26];
          vector<int> fword[26];
          vector<uint32_t> pword;
          int i = 0;
          for (auto& s: puzzles) {
              first[s[0] - 'a'].push_back(i);
              ++i;
              uint32_t idx = 0;
              for (auto c : s) {
                  idx |= 1 << (c - 'a');
              }
              pword.push_back(idx);
          }
          vector<int> res(puzzles.size(), 0);
          for (auto& w : words) {
              uint32_t widx = 0;
              vector<int> backup;
              bool flg[26];
              fill(flg, flg + 26, false);
              for (auto c : w) {
                  widx |= 1 << (c - 'a');
              }
              for (auto c : w) {
                  if (!flg[c - 'a']) {
                      fword[c - 'a'].push_back(widx);
                  }
                  flg[c - 'a'] = true;
              }
          }
          for (int i = 0; i < 26; ++i) {
              for (auto pi : first[i]) {
                  for (auto widx : fword[i]) {
                      uint32_t pidx = pword[pi];
                      if ((pidx & widx) == widx) {
                          res[pi] += 1;
                      }
                  }
              }
          }
          return res;
      }
  };
  ```

* 另一种方式, 开`1 << 26`的空间, 然后计数排序, `j = (j - 1) & all`遍历所有1组合可能性, 或者遍历1到`1 << len`遍历所有位取或不取

* ```c++
  const int LETTERS = 26;
  
  class Solution {
  public:
      vector<int> findNumOfValidWords(vector<string>& words, vector<string>& puzzles) {
          vector<int> freq(1 << LETTERS, 0);
          for (string &word : words) {
              int mask = 0;
              for (char c : word)
                  mask |= 1 << (c - 'a');
              freq[mask]++;
          }
          vector<int> answer;
          for (string &puzzle : puzzles) {
              int mask = 0;
              for (char c : puzzle)
                  mask |= 1 << (c - 'a');
              int first = puzzle[0] - 'a';
              int sub = mask;
              int total = 0;
              while (true) {
                  if (sub >> first & 1)
                      total += freq[sub];
                  if (sub == 0)
                      break;
                  sub = (sub - 1) & mask;
              }
              answer.push_back(total);
          }
          return answer;
      }
  };
  ```

* ```c++
  class Solution {
  public:
      vector<int> findNumOfValidWords(vector<string>& words, vector<string>& puzzles) {
          int m = puzzles.size();
          vector<int> ret(m);
          vector<int> cnt(1 << 26);
          for (auto& it : words) {
              int mask = 0;
              for (auto& c : it) {
                  mask |= 1 << (c - 'a');
              }
              cnt[mask]++;
          }
          for (int i = 0; i < m; ++i) {
              const auto& s = puzzles[i];
              int len = s.size();
              for (int k = 0; k < (1 << len - 1); ++k) {
                  int mask = 1 << (s[0] - 'a');
                  for (int i = 0; i < len - 1; ++i) {
                      if (k & (1 << i)) {
                          mask |= 1 << (s[i + 1] - 'a');
                      }
                  }
                  ret[i] += cnt[mask];
              }
          }
          return ret;
      }
  };
  ```

* 对word建trie, 那么每一层要么向后找, 要么向下一层找 (`S[idx] == ch`), 同时携带一个当前是否满足`yes`/头部是否满足`passed`s的标志. 计数则只在所有`word`最大字符的节点放置计数, 当满足时获取这部分计数

* ```c++
  struct node {
      node* child[27];
      int cnt;
      node() {
          cnt = 0;
          memset(child, 0, sizeof(child));
      }
  };
  
  class Solution {
  public:
      node* root;
      const int CHARS = 26;
      void insert(vector < bool > &cnt, int last) {
          node *cur = root;
          for(int i = 0;i < CHARS;++i) {
              if(cnt[i]) {
                  if(cur -> child[i] == NULL) {
                      cur -> child[i] = new node();
                  }
                  cur = cur -> child[i];
                  if(i == last) {
                      // cout << i << "\n";
                      ++(cur -> cnt);
                  }
              }
          }
      }
      
      int process(string &S, int idx, node* cur, bool yes, char passby, bool passed) {
          if(idx == S.size()) {
              return (yes and passed and (cur != NULL)) ? (cur -> cnt) : 0;
          }
          
          if(cur == NULL) {
              return 0;
          }
          
          // cout << idx << " " << yes << " " << passby << " " << passed << "\n";
          
          return ((yes and passed) ? (cur -> cnt) : 0) + process(S, idx + 1, cur, 0, passby, passed) + process(S, idx + 1, cur -> child[S[idx] - 'a'], 1, passby, passed | (S[idx] == passby));
      }
      
      vector<int> findNumOfValidWords(vector<string>& A, vector<string>& Q) {
          int n = A.size();
          root = new node();
          for(int i = 0;i < n;++i) {
              vector < bool > cnt(CHARS + 1, 0);
              int m = A[i].size();
              int last = 0;
              for(int j = 0;j < m;++j) {
                  cnt[A[i][j] - 'a'] = true;
                  last = max(last, A[i][j] - 'a');
              }
              insert(cnt, last);
          }
          vector < int > ans;
          int Qn = Q.size();
          for(int i = 0;i < Qn;++i) {
              char ch = Q[i][0];
              sort(Q[i].begin(), Q[i].end());
              ans.push_back(process(Q[i], 0, root, 1, ch, 0));
          }
          
          return ans;
      }
  };
  ```




### 1183. Maximum Number of Ones

* ![1567870491139](D:\OneDrive\Pictures\Typora\1567870491139.png)

* ```python
  class Solution(object):
      def maximumNumberOfOnes(self, C, R, K, maxOnes):
          count = [0] * (K * K)
          for r in range(R):
              for c in range(C):
                  code = (r % K) * K + c % K
                  count[code] += 1
          count.sort()
          ans = 0
          for _ in range(maxOnes):
              ans += count.pop()
          return ans
  ```

* 循环矩阵, 对全部的循环矩阵同位置计数. 这个同位置可以放置1且不冲突. 最多能取到`maxOnes`这么多个位置

* ```c++
  class Solution {
  public:
      int maximumNumberOfOnes(int m, int n, int k, int x) {
          // a[i][j] == a[i + k][j]
          vector<vector<int>> cnt(k, vector<int>(k, 0));
          for (int i = 0; i < n; i++) {
              for (int j = 0; j < m; j++) {
                  cnt[i % k][j % k]++;
              }
          }
          vector<int> result;
          for (int i = 0; i < k; i++) {
              for (int j = 0; j < k; j++) result.push_back(cnt[i][j]);
          }
          sort(result.begin(), result.end());
          reverse(result.begin(), result.end());
          int ans = 0;
          for (int i = 0; i < x; i++) ans += result[i];
          return ans;
      }
  };
  ```

* 或者直接计数

* ```c++
  class Solution:
      def maximumNumberOfOnes(self, width: int, height: int, side: int, maxOnes: int) -> int:        # Soltuion: Fold Matrix
              # Take 7*5, side=3, maxOnes=3 as example:
                  # . . .|. . .|.                 1 1 .|1 1 .|1
                  # . . .|. . .|. fold  6 4 4     1 . .|1 . .|1   
                  # . . .|. . .|. ----\ 6 4 4 ==> . . .|. . .|. 
                  # ------------- ----/ 3 2 2     -------------   
                  # . . .|. . .|.         ||      1 1 .|1 1 .|1 
                  # . . .|. . .|.         \/      1 . .|1 . .|1 
                  #                  6+6+4 = 16
          
          # Matrix Horizonalize [:] -> [..]
          if width<height:
              width, height = height, width
          
          # Fold
          x,x0 = divmod(width,side)
          v,v0 = divmod(height,side)
          kount = [   x0*v0       , (side-x0)*v0,
                      x0*(side-v0), (side-x0)*(side-v0)
                  ]
          
          value = [   (x+1)*(v+1) , x*(v+1)   ,
                      (x+1)*v     , x*v       ,
                  ]
          
          # Sum the largest ones
          ans = 0
          for k,n in zip(kount, value):
              if maxOnes > k:
                  ans += k*n
                  maxOnes -= k
              else:
                  return ans + maxOnes *n
          return ans
  ```




### 1186. Maximum Subarray Sum With One Deletion

* 正反预处理, 找出正反向最大累计和, 则最大和即为`fw[i - 1] + bw[i + 1]`

* ```c++
  class Solution {
  public:
      int maximumSum(vector<int>& arr) {
          int N = arr.size();
          vector<int> fw(N, 0);
          vector<int> bw(N, 0);
          int cur_max = arr[0];
          int all_max = arr[0];
          
          int negcnt = 0;
          for (int i = 0; i < N; ++i) {
              if (arr[i] >= 0) {
                  break;
              }
              ++negcnt;
          }
          if (negcnt == N) {
              return *max_element(arr.begin(), arr.end());
          }
          
          fw[0] = arr[0];        
          for (int i = 1; i < N; i++)  { 
              cur_max = max(arr[i], cur_max + arr[i]); 
              all_max = max(all_max, cur_max); 
              fw[i] = cur_max; 
          } 
  
          cur_max = all_max = bw[N - 1] = arr[N - 1]; 
          bw[N - 1] = arr[N - 1];
          for (int i = N - 2; i >= 0; i--) { 
              cur_max = max(arr[i], cur_max + arr[i]); 
              all_max = max(all_max, cur_max); 
              bw[i] = cur_max; 
          } 
  
          int res = all_max;
  
          for (int i = 1; i < N - 1; i++) 
              res = max(res, fw[i - 1] + bw[i + 1]); 
  
          return res; 
      }
  };
  ```

* 状态转移, `dp(i, 1) = max{dp(i - 1, 0), dp(i - 1, 1) + arr[i]`表示删除一个的最大值, `dp(i, 0) = max{arr[i], dp(i - 1, 0) + arr[i]}`表示不删除的最大值(保证有一个元素的情况下)

* ```c++
  class Solution {
  public:
      int maximumSum(vector<int>& arr) {
          unsigned n = arr.size();
          int dp_i_0 = -1e4, dp_i_1 = -1e4;
          int ans = INT_MIN;
          for (int i = 0; i < n; ++i) {
              dp_i_1 = max(dp_i_1 + arr[i], dp_i_0);
              dp_i_0 = max(dp_i_0 + arr[i], arr[i]);            
              ans = max(ans, max(dp_i_0, dp_i_1));
          }
          return ans;
      }
  };
  ```

* 









### 1187. Make Array Strictly Increasing

* 先离散化得到所有元素的序, $dp(i, j)$表示$[0, i)$序列由排序后的前$j$个元素$[0, j)$构成需要的最少操作数

* $$
  dp(i, j) = \min \begin{cases} dp(i, j - 1) \\ dp(i - 1, j - 1) & \text{ (if arr1[i] = j)} \\ dp(i - 1, j - 1) + 1 & \text{ (if j can be swapped from arr2)} \end{cases}
  $$

* 边界条件, $dp(0, j) = 0$, $dp(i, 0) = \inf$, $dp(0, 0) = \inf$

* ```c++
  const int INF = 1e9 + 5;
  
  class Solution {
  public:
      int makeArrayIncreasing(vector<int>& arr1, vector<int>& arr2) {
          // discretization
          vector<int> all;
          for (auto i : arr1) all.push_back(i);
          for (auto i : arr2) all.push_back(i);
          sort(all.begin(), all.end());
          all.erase(unique(all.begin(), all.end()), all.end());
          unordered_map<int, int> discrete_map;
          int M = all.size(), N = arr1.size();
          
          if (M < N) return -1;
          
          for (int i = 0; i < M; ++i) 
              discrete_map[all[i]] = i;
          for (auto& i : arr1) i = discrete_map[i];
          unordered_set<int> from_arr2;
          for (auto& i : arr2) {
              i = discrete_map[i];
              from_arr2.insert(i);
          }
          
          vector<int> dp(M + 1, 0);
          for (int i = 0; i < N; ++i) {
              vector<int> temp = dp;
              temp[0] = INT_MAX / 2;
              for (int j = 1; j <= M; ++j) {
                  temp[j] = temp[j - 1];
                  if (arr1[i] == j - 1) temp[j] = min(temp[j], dp[j - 1]);
                  if (from_arr2.count(j - 1)) temp[j] = min(temp[j], dp[j - 1] + 1);
              }
              dp = temp;
          }
          int res = *min_element(dp.begin(), dp.end());
          return (res < (INT_MAX / 2) ? res : -1;
      }
  };
  ```

* 或者先离散化, 然后$dp(i) = \min_{j = 0}^{i - 1} dp(j) + (i - j - 1) \text{ if arr2 has more than i - j - 1 elements within (arr1[j], arr1[i])} $. $dp(i)$表示第$i$位不动前$[0, i)$位有序的最少交换次数

* ```c++
  const int INF = 1e9 + 5;
  
  class Solution {
  public:
      int makeArrayIncreasing(vector<int>& arr1, vector<int>& arr2) {
          // discretization
          vector<int> all;
          arr1.insert(arr1.begin(), -INF);
          arr1.push_back(INF);
          for (auto i : arr1) all.push_back(i);
          for (auto i : arr2) all.push_back(i);
          sort(all.begin(), all.end());
          all.erase(unique(all.begin(), all.end()), all.end());
          unordered_map<int, int> discrete_map;
          int M = all.size(), N = arr1.size();
          
          if (M < N) return -1;
          
          for (int i = 0; i < M; ++i) {
              discrete_map[all[i]] = i;
          }
          for (auto& i : arr1) i = discrete_map[i];
          unordered_set<int> from_arr2;
          for (auto& i : arr2) {
              i = discrete_map[i];
              from_arr2.insert(i);
          }
          vector<int> arr2cnt(M + 1, 0);
          int collect = 0;
          for (int i = 0; i < M; ++i) {
              if (from_arr2.count(i)) ++collect;
              arr2cnt[i] = collect;
          }
          
          vector<long long> dp(N + 1, 0);
          for (int i = 1; i < N; ++i) {
              dp[i] = LONG_MAX / 2;
              for (int j = 0; j < i; ++j) {
                  if (arr1[j] < arr1[i]) {
                      if (arr2cnt[arr1[i] - 1] - arr2cnt[arr1[j]] >= i - j - 1) {
                          dp[i] = min(dp[i], dp[j] + i - j - 1);
                      }
                  }
              }
          }
          long long res = dp[N - 1];
          return (res < (LONG_MAX / 2)) ? res : -1;
      }
  };
  ```






### 1191. K-Concatenation Maximum Sum

* 分类讨论, 如果总和>=0, 则为一次复制的最大值+(k-2)倍数组和, 否则, 则为一次复制中的最大值

* ```c++
  class Solution {
  public:
      int kConcatenationMaxSum(vector<int>& arr, int k) {
          long long sum = 0;
          int m = 1e9 + 7;
          for (auto i: arr) {
              sum += i;
          }
          long long max_so_far = 0, max_ending_here = 0;
          for (int i = 0; i < 2 * arr.size(); ++i) {
              max_ending_here = max_ending_here + arr[i % arr.size()];
              if (max_so_far < max_ending_here) 
                  max_so_far = max_ending_here;
              if (max_ending_here < 0) 
                  max_ending_here = 0; 
          }
          if (sum < 0) {
              return max_so_far % m;        
          } else {
              long long res = ((k - 2) % m) * (sum % m);
              return (res % m) + (max_so_far % m);
          }
      }
  };
  ```



### 1192. Critical Connection in a Network

* Amazon OA题, Tarjan求割桥

* ```c++
  class Solution {
  public:
      void helper(int u, vector<bool> &visited, vector<vector<int>> &res, vector<vector<int>>& adj, vector<int> &disc, vector<int> &low, vector<int> &parent) {
          static int time = 0;
          visited[u] = true;
          disc[u] = low[u] = ++time;
          for (int i = 0; i < adj[u].size(); ++i) {
              int v = adj[u][i];
              if (!visited[v]) {
                  parent[v] = u;
                  helper(v, visited, res, adj, disc, low, parent);
                  low[u] = min(low[u], low[v]);
                  if (low[v] > disc[u]) {
                      res.push_back(vector<int>{u, v});
                  }
              }
              else if (v != parent[u]) {
                  low[u] = min(low[u], disc[v]);
              }
          }
      }
  
  
      
      vector<vector<int>> criticalConnections(int n, vector<vector<int>>& connections) {
          vector<vector<int>> adj(n, vector<int>());
          for (auto& c: connections) {
              adj[c[0]].push_back(c[1]);
              adj[c[1]].push_back(c[0]);
          }
          vector<bool> visited(n + 1, false);
          vector<int> disc(n + 1, 0);
          vector<int> low(n + 1, 0);
          vector<int> parent(n + 1, 0);
          vector<vector<int>> res;
          for (int i = 0; i < n; ++i) {
              if (!visited[i]) {
                  helper(i, visited, res, adj, disc, low, parent);
              }
          }
          return res;
      }
  };
  ```

* 求无向连通图的割点

* ![1567052650935](D:\OneDrive\Pictures\Typora\1567052650935.png)

* [连通图强连通分量-割点-缩点/Tarjan](https://www.cnblogs.com/stxy-ferryman/p/7779347.html)

* [求无向连通图的割点](https://www.cnblogs.com/en-heng/p/4002658.html)

* ![1567054062693](D:\OneDrive\Pictures\Typora\1567054062693.png)




### 1199. Minimum Time to Build Blocks

* dp, 状态是前i和j worker, `dp(i, j) = min(dp(i, j), max(dp(i-1, j-1), b[i]), dp(i, j * 2) + split)`

* ```c++
  class Solution {
  public:
      int minBuildTime(vector<int>& blocks, int split) {
          constexpr int INF = 0x3F3F3F3F;
          sort(blocks.begin(), blocks.end());
          const int N = blocks.size();
          vector<int> dp(N+1);
          for (int i = 0; i < N; i++) {
              vector<int> ndp(N+1, INF);
              for (int j = N; j > 0; j--) {
                  int nj = min(j*2, N);
                  ndp[j] = max(dp[j-1], blocks[i]);
                  if (j != nj) {
                      ndp[j] = min(ndp[j], ndp[nj] + split);
                  }
              }
              dp = std::move(ndp);
          }
          return dp[1];
      }
  };
  
  // DFS-DP
  class Solution {
      int dp[1005][1005], N, MAX = 1000000009, S;
      vector<int> A;
  public:
      int cal(int x, int c) {
          if (dp[x][c] != -1) return dp[x][c];
          dp[x][c] = MAX;
          if (x == N) dp[x][c] = 0;
          else if (c > 0) {
              if (c < N) dp[x][c] = S + cal(x, min(N, 2 * c));
              dp[x][c] = min(dp[x][c], max(A[x], cal(x+1,c-1)));
          }
          //printf("dp[%d][%d] = %d\n", x, c, dp[x][c]);
          return dp[x][c];
      }
      int minBuildTime(vector<int>& blocks, int split) {
          N = blocks.size(), S = split;
          A = blocks;
          sort(A.begin(), A.end());
          reverse(A.begin(), A.end());
          memset(dp,-1,sizeof(dp));
          return cal(0, 1);
      }
  };
  ```

* 对`i..j`dp也可做, `w`表示`i..j`的最优split, 则新的`a..b`得最优split一定在`w[a][b-1]`和`w[a+1][b]`之间产生

* ```c++
  class Solution {
  public:
      int minBuildTime(vector<int>& blocks, int split) {
          sort(blocks.begin(), blocks.end());
          
          int n = blocks.size();
          
          int dp[1001][1001] = {}, w[1001][1001] = {};
          
          for (int i = 0; i < n; i++) {
              dp[i][i] = blocks[i];
              w[i][i] = i;
          }
          
          for (int k = 1; k < n; k++) {
              for (int i = 0; i + k < n; i++) {
                  int lo = w[i][i + k - 1];
                  int hi = w[i + 1][i + k];
                  dp[i][i + k] = 2147483647;
                  for (int m = lo; m <= hi; m++) {
                      int val = split + max(dp[i][m], dp[m + 1][i + k]);
                      if (val < dp[i][i + k]) {
                          dp[i][i + k] = val;
                          w[i][i + k] = m;
                      }
                  }
              }
          }
          
          return dp[0][n - 1];
      }
  };
  ```

* 二分上下界, 贪心, 从最大的开始, 倒着倍增, 每次倍增到超过给定时间. 然后倒着寻找下一个可以倍增的项. 可以先离散化优化. 最终会变为`S_n * S + max(a_n, ..., a_i+1, S_i * S + max(a_i, ..., a_j+1, ...))` 这必定是最小的

* ![1569082363066](D:\OneDrive\Pictures\Typora\1569082363066.png)

* ```c++
  class Solution {
  public:
      int minBuildTime(vector<int>& blocks, int split) {
          
          int n = blocks.size();
          
          auto check = [&](int m)
          {
              vector<int> v;
              for (auto x : blocks)
              {
                  int len = (m-x)/split;
                  v.push_back(len);
              }
              sort(v.begin(), v.end());
              int tot = 0;
              int cur = 1;
              int i = 0;
              while (i < n)
              {
                  if (v[i] == tot)
                  {
                      if (cur == 0) return 0;
                      -- cur;
                      i ++;
                  }
                  else
                  {
                      cur = cur*2;
                      tot ++;
                      if (cur > 1000) return 1;
                  }
              }
              return 1;
          };
          
          int L = *max_element(blocks.begin(), blocks.end()), R = 1000000;
         
          int ret = R;
          while (L <= R)
          {
              int m = (L+R)/2;
              if (check(m))
              {
                  ret = m;
                  R = m-1;
              }
              else
                  L = m+1;
          }
          return ret;
      }
  };
  ```

* priority queue, 回想剪绳子, 因为解必定是上文形式, 所以?

* ```c++
  class Solution {
  public:
      int minBuildTime(vector<int>& blocks, int split) {
          priority_queue<int, vector<int>, greater<int>> pq;
          for(int b: blocks) pq.push(b);
          while (pq.size() > 1){
              int a = pq.top();
              pq.pop();
              int b = pq.top();
              pq.pop();
              pq.push(split + b);
          }
          return pq.top();
      }
  };
  ```




### 1210. Minimum Moves to Reach Target with Rotations

* 对蛇尾位置和蛇方向`x, y, dir`三维BFS, 注意终止情况一定是蛇头向下

* ```c++
  class Solution {
      const int INF = 1e9 + 5;
      const int HORIZONTAL = 0, VERTICAL = 1;
  
      int R, C;
      vector<vector<int>> grid;
      vector<vector<vector<int>>> dist;
  
      bool valid(int r, int c) {
          return 0 <= r && r < R && 0 <= c && c < C;
      }
  
      void bfs_check(queue<pair<pair<int, int>, int>> &q, int r, int c, int dir, int current_dist) {
          if (current_dist < dist[r][c][dir]) {
              dist[r][c][dir] = current_dist;
              q.push({{r, c}, dir});
          }
      }
  
      void grid_bfs() {
          queue<pair<pair<int, int>, int>> q;
          dist.assign(R, vector<vector<int>>(C, vector<int>(2, INF)));
          bfs_check(q, 0, 0, HORIZONTAL, 0);
  
          while (!q.empty()) {
              pair<pair<int, int>, int> top = q.front(); q.pop();
              int r = top.first.first, c = top.first.second, dir = top.second;
              int cur_dist = dist[r][c][dir];
              int r2 = dir == HORIZONTAL ? r : r + 1;
              int c2 = dir == HORIZONTAL ? c + 1 : c;
  
              if (valid(r, c + 1) && valid(r2, c2 + 1) && !grid[r][c + 1] && !grid[r2][c2 + 1])
                  bfs_check(q, r, c + 1, dir, cur_dist + 1);
  
              if (valid(r + 1, c) && valid(r2 + 1, c2) && !grid[r + 1][c] && !grid[r2 + 1][c2])
                  bfs_check(q, r + 1, c, dir, cur_dist + 1);
  
              if (dir == HORIZONTAL) {
                  if (valid(r + 1, c) && valid(r + 1, c + 1) && !grid[r + 1][c] && !grid[r + 1][c + 1])
                      bfs_check(q, r, c, VERTICAL, cur_dist + 1);
              } else {
                  if (valid(r, c + 1) && valid(r + 1, c + 1) && !grid[r][c + 1] && !grid[r + 1][c + 1])
                      bfs_check(q, r, c, HORIZONTAL, cur_dist + 1);
              }
          }
      }
  public:
      int minimumMoves(vector<vector<int>>& _grid) {
          grid = _grid;
          R = grid.size();
          C = grid.empty() ? 0 : grid[0].size();
          grid_bfs();
          int answer = dist[R - 1][C - 2][HORIZONTAL];
          return answer < INF ? answer : -1;
      }
  };
  ```




### 1219. Path with Maximum Gold

* 练习一下数位DFS, `std::hash<bitset<N>>`

* ```c++
  vector<vector<int>> d = {
      {1, 0},
      {0, 1},
      {-1, 0},
      {0, -1}
  };
  class Solution {
  public: 
      map<pair<int, int>, unordered_map<bitset<256>, int>> m;
      int helper(vector<vector<int>>& grid, bitset<256>&b, int x, int y, int N, int M) {
          if (m.find(make_pair(x, y)) != m.end()) {
              auto& um = m[make_pair(x, y)];
              if (um.find(b) != um.end()) {
                  return um[b];
              }
          }
          int curmax = 0;
          for (int i = 0; i < 4; ++i) {
              auto& di = d[i];
              int nx = x + di[0];
              int ny = y + di[1];
              if (nx >= 0 && nx < N && ny >= 0 && ny < M && grid[nx][ny] != 0 && !b[nx * 16 + ny]) {
                  b[nx * 16 + ny] = true;
                  int res = helper(grid, b, nx, ny, N, M);
                  b[nx * 16 + ny] = false;
                  curmax = max(curmax, res);
              }
          }
          m[make_pair(x, y)][b] = curmax + grid[x][y];
          return curmax + grid[x][y];
      }
      
      
      int getMaximumGold(vector<vector<int>>& grid) {
          int N = grid.size();
          int M = grid[0].size();
          bitset<256> b;
          int max1 = 0;
          for (int i = 0; i < N; ++i) {
              for (int j = 0; j < M; ++j) {
                  if (grid[i][j] && !b[i * 16 + j]) {
                      b[i * 16 + j] = true;
                      max1 = max(max1, helper(grid, b, i, j, N, M));
                      b[i * 16 + j] = false;
                  }
                  b.reset();
              }
          }
          return max1;
      }
  };
  
  ```

* 或者离散化+mask (小于25个)

* ```c++
  int N;
  vector<int> gold;
  vector<vector<int>> adj;
  unordered_map<int, int> save;
  
  int solve(int current, int mask) {
      int key = (current << N) + mask;
  
      if (save.find(key) != save.end())
          return save[key];
  
      int answer = 0;
  
      for (int neighbor : adj[current])
          if ((mask >> neighbor & 1) == 0)
              answer = max(answer, gold[neighbor] + solve(neighbor, mask | 1 << neighbor));
  
      return save[key] = answer;
  }
  
  class Solution {
  public:
      int getMaximumGold(vector<vector<int>>& grid) {
          int R = grid.size(), C = grid.empty() ? 0 : grid[0].size();
          vector<vector<int>> gold_index(R, vector<int>(C, -1));
          gold.clear();
          N = 0;
  
          for (int r = 0; r < R; r++)
              for (int c = 0; c < C; c++)
                  if (grid[r][c] > 0) {
                      gold.push_back(grid[r][c]);
                      gold_index[r][c] = N++;
                  }
  
          adj.assign(N, {});
  
          for (int r = 0; r < R; r++)
              for (int c = 0; c < C; c++) {
                  int index = gold_index[r][c];
  
                  if (index < 0)
                      continue;
  
                  if (r > 0 && grid[r - 1][c] > 0)
                      adj[index].push_back(gold_index[r - 1][c]);
  
                  if (c > 0 && grid[r][c - 1] > 0)
                      adj[index].push_back(gold_index[r][c - 1]);
  
                  if (r + 1 < R && grid[r + 1][c] > 0)
                      adj[index].push_back(gold_index[r + 1][c]);
  
                  if (c + 1 < C && grid[r][c + 1] > 0)
                      adj[index].push_back(gold_index[r][c + 1]);
              }
  
          save.clear();
          int best = 0;
  
          for (int i = 0; i < N; i++)
              best = max(best, gold[i] + solve(i, 1 << i));
  
          return best;
      }
  };
  ```

* 主要是卡常...

* ```c++
  class Solution {
  private:
      int cur;
      int ans;
      static constexpr int dirs[4][2] = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}};
      
  public:
      void dfs(vector<vector<int>>& grid, int m, int n, int i, int j) {
          cur += grid[i][j];
          grid[i][j] = -grid[i][j];
          ans = max(ans, cur);
          for (int k = 0; k < 4; ++k) {
              int i0 = i + dirs[k][0];
              int j0 = j + dirs[k][1];
              if (i0 >= 0 && i0 < m && j0 >= 0 && j0 < n && grid[i0][j0] > 0) {
                  dfs(grid, m, n, i0, j0);
              }
          }
          cur += grid[i][j];
          grid[i][j] = -grid[i][j];
      }
      
      int getMaximumGold(vector<vector<int>>& grid) {
          int m = grid.size();
          int n = grid[0].size();
          ans = 0;
          for (int i = 0; i < m; ++i) {
              for (int j = 0; j < n; ++j) {
                  cur = 0;
                  if (grid[i][j] > 0) {
                      dfs(grid, m, n, i, j);
                  }
              }
          }
          return ans;
      }
  };
  ```



### 1220. Count Vowels Permutaton

* 弱智dp, 学习一下矩阵快速幂

* ```c++
  class Solution {
  public:
      typedef long long ll;
      typedef vector<ll> vec;
      typedef vector<vec> mat;
       
      const int MODE = 1e9 + 7;
       
      mat multiply(mat& A, mat& B) {
          int m = A.size(), n = B[0].size();
          mat res(m, vec(n, 0));
       
          for(int i=0; i<m; i++)
              for(int j=0; j<n; j++)
                  for(int k=0; k<A[i].size(); k++)
                      res[i][j] = (res[i][j] + A[i][k] * B[k][j]) % MODE;
       
          return res;
      }
       
      mat pow(mat& A, long long n) {
          mat res(A.size(), vec(A.size(), 0));
          for(int i=0; i<A.size(); i++)
              res[i][i] = 1;
       
          while(n > 0){
              if((n&1) == 1) res = multiply(A, res);
              n >>= 1;
              A = multiply(A, A);
          }
          return res;
      }
  	static constexpr const mat grid{{0,1,0,0,0}, {1,0,1,0,0}, {1,1,0,1,1}, {0,0,1,0,1}, {1,0,0,0,0} };
      int countVowelPermutation(int n) {
          grid = pow(grid, n-1);
          mat res{{1}, {1}, {1}, {1}, {1}};
          res = multiply(grid, res);
          for(int i=1; i<5; i++) res[i][0] += res[i-1][0];
          return res.back().back() % MODE;
      }
  }
  ```

* 









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
  
* [codeforce r425 div.1 c](http://codeforces.com/problemset/problem/425/C)

* 先对b做counting sort得到下标. 然后对a数列和总共宝石数做dp. $dp(i, j)$ 表示取到 $a_i$ 元素前缀时 (不一定操作), 且总宝石数为$j$时, 剩下的 $b$ 最小序列起始点. 那么转移方程就是
  * $dp(i, j) = dp(i - 1, j)$, 不拿宝石
  * $dp(i, j) = (a_i$ 在 $b_{k + 1}, \cdots, b_{n-1}$ 中出现的最小位置$)$, 其中$k$是$dp(i - 1, j - 1)$, 拿宝石, 则从之前的最小序列之后开始找下一个匹配元素
  
* 总支出$j * cost + i + dp(i, j)$

* 单调性: 支出只会选 $b$ 中小的下标 (cost小, 且可能性多)

* ```c++
  int main()
  {
      //freopen("input.in","r",stdin);
      cin>>n>>m>>s>>e;
      for(int i=1;i<=n;i++)scanf("%d",&a[i]);
      for(int j=1;j<=m;j++)scanf("%d",&b[j]),idx[b[j]].push_back(j);
      for(int i=1;i<=n;i++)idx[a[i]].push_back(INF);
      for(int i=1;i<=s/e;i++)f[i][0]=INF;
      memset(f[0],0,sizeof(f[0]));
      for(int i=1;i<=s/e;i++)
      {
          for(int j=1;j<=n;j++)
          {
              int k=lower_bound(idx[a[j]].begin(),idx[a[j]].end(),min(f[i-1][j-1]+1,INF))-idx[a[j]].begin();
              f[i][j]=min(idx[a[j]][k],f[i][j-1]);
              if(j+f[i][j]+i*e<=s)ans=i;
          }
      }   
      cout<<ans<<endl;
      return 0; 
  }
  ```

* 



### 有序的最少操作数 #1

* 一个1-n数列打乱 每次只能选一个元素放到最左边或者最右边 使其有序的最少操作数
* 先做最长连续递增子序列 (亦或是排序后的连续位置), 然后操作次数就是N - 最长子序列长度



### 单调栈 #1

* ![1567673405727](D:\OneDrive\Pictures\Typora\1567673405727.png)
* 把所有`2`操作离线, 建一个单调递增栈包含index和x
* 枚举所有`m`的最后更新index $m_i$, 在栈中找index之后的最小x
* Alternative: 按事件倒序求即可，扫到事件2就记录最小值，扫到事件1就对比，最后对原数组扫一遍把还没计算的都对比一遍



### 后缀数组 #1

* ![1567731083771](D:\OneDrive\Pictures\Typora\1567731083771.png)



### 1D K-means

* [DP-solution](https://journal.r-project.org/archive/2011-2/RJournal_2011-2_Wang+Song.pdf)
* $D[i, m] = \min_{m \leq j \leq i} \big\{ D[j - 1, m - 1] + d(x_j, \cdots, x_i) \big\}$, 同时记下$B[i, m] = \text{argmin}_j$ $O(kN)$
* $d(x_j, \cdots, x_i) = \sum_{t = k + 1}^i x_t - \sum_{t = j}^k x_t$, $O(N^2 )$预处理 ($k = (i + j) / 2$)
* $D[i, m] = 0$ 当 $m = 0$ or $i = 0$
* 反向回溯$B[i, m]$, $B[B[i, m], m - 1], \cdots$
* 2D K-means is NP hard
* will 1D K-means converging to local minimum?



### 连续抛硬币

* [连续抛硬币，遇到“正反反”停止和遇到“正反正”停止，两种情况下抛硬币的平均次数是否相同](https://www.zhihu.com/question/20157299)
* 马尔科夫转移矩阵
  * 矩阵乘法, 直到超过精度要求
* AC自动机/KMP + 高斯消元 + 期望dp
  * ![1567908149565](D:\OneDrive\Pictures\Typora\1567908149565.png)
* 矩阵求逆
  * $T + T^2 + \cdots + ... + T^{\inf} = T (1-T)^{-1}$ 结束节点概率不是1, 而是0
* ![1567907623069](D:\OneDrive\Pictures\Typora\1567907623069.png)
* [ZJOI2013 抛硬币]([https://loliconautomaton.github.io/ZJOI2013-%E6%8A%9B%E7%A1%AC%E5%B8%81/](https://loliconautomaton.github.io/ZJOI2013-抛硬币/))
* [HDU5955 Guessing the Dice Roll](https://www.cnblogs.com/dirge/p/6017703.html)
  * 获胜概率 -> 建立AC自动机 -> 期望加权列方程 -> 高斯消元
  * ![1567908485790](D:\OneDrive\Pictures\Typora\1567908485790.png)
* [JSO!2009 有趣的游戏](https://blog.csdn.net/weixin_30247781/article/details/96547993)
* [Penney's Game](http://www.matrix67.com/blog/archives/6015)
  * ![1567908500448](D:\OneDrive\Pictures\Typora\1567908500448.png)



### 约瑟夫环

* dp, $out(n) = (out(n - 1) + M) % n$, $out(1) = 0$

* > ```
  > 队里有n个人，我们对其编号：
  > 0, 1, 2, ..., n-1
  > 
  > 然后进行一轮淘汰，因为报到m的人出队，所以第一次出队的人必为(m - 1) % n(环尾下一个为环首)
  > 现在队伍的情况为：
  > 0, 1, 2, ..., m-2, m-1, m, ..., n-1
  > 
  > 将m-1标记为@，已经出队。
  > 0, 1, 2, ..., m-2,  @ , m, ..., n-1。
  > 
  > 对其重新编号，让m为0，则有：
  > n-m, n-m+1, ..., n-2, 0, 1, ..., n-1-m
  > 
  > 抛开现在的结果不看，假设我们现在要解决共有n-1人的情况，对其编号，
  > 0, 1, 2, ..., n-2。
  > 
  > 不难发现，这种情况与n人出队一次之后的情况非常相似，只是编号相差了m。
  > 
  > 我们可以一直推下去：有n-2人，有n-3人, ..., 有1人。
  > 这样就得到了递推式：
  > res[n] = (res[n-1] + m) % n;
  > 当然，只有1人的时候res[1] = 0;
  > 
  > 我们求解只需要从res[1]推到res[n]即可。
  > ```





### 趣题 #1

* 正方形格子, 只能连斜边或者水平边, 达到面积的最少边数

* > 思路：先打表把边数为x的能包含的最多碎片正方形求出来（遇到边数为4的倍数的边数就直接为斜的正方形，公式出里面包含的碎片正方形个数，再通过这个来求其他三种情况，每次把两条斜的边改为竖直和水平）。

* ![img](D:\OneDrive\Pictures\Typora\20170819210246027.jpg)

* 每次扩展多一个梯形 (+ 三角形)

* ![1568103736022](D:\OneDrive\Pictures\Typora\1568103736022.png)



### 钱老板赶工

* > ```
  > 钱老板去国外度了个假，刚回到公司就收到了n封催促工作完成的邮件。每项工作都有完成截止日期的deadline，钱老板做每项工作都会花去cost天，而且不能中断。
  > 请你帮钱老板安排一下完成工作的顺序，以减少总的工作推迟时间
  > 输入：n<=20，表示工作数量接下来n行，每一行有两个数，表示第i项工作的deadline和cost
  > 输出：最小的总的工作推出时间
  > ```

* 状压dp, $dp(x) = \min (dp(x - i) + \sum cost(x) - ddl(i))$

* ```c++
  for (int x = 1;x < (1 << n);x++) {
      sum_cost[x] = 0;
      for (int i = 0;i < n;i++) {
          if (x & (1 << i)) {
              sum_cost[x] += cost[i];
          }
      }
      for (int i = 0;i < n;i++) {
          if (x & (1 << i)) {
              dp[x] = min(dp[x], dp[x - (1 << i)] + sum_cost[x] - deadline[i]);
          }
      }
  }
  ```



### 小招喵的字符串

* > ```
  > 老板给了小招瞄一个由数字字符0-9和？组成的字符串。它想让小招瞄把所有的？用数字字符0-9填上，小招瞄想知道有多少种情况该字符串表示的数字摸13余数为5
  > 老板允许舔出来的数字有前导，因为答案很大，输出对10^9+7取模的结果
  > ```

* 余数dp, 多加一个余数维

* ```c++
  for (int i = 0;i < s.size();i++) {
      for (int j = 0;j < 13;j++) {
          if (s[i] == '?') {
              for (int k = 0;k < 10;k++) {
                  dp[i + 1][(j * 10 + k) % 13] += dp[i][j];
                  dp[i + 1][(j * 10 + k) % 13] %= mod;
              }
          } else {
              int k = s[i] - '0';
              dp[i + 1][(j * 10 + k) % 13] += dp[i][j];
              dp[i + 1][(j * 10 + k) % 13] %= mod;
          }
      }
  }
  ```



### 小招喵的树

* 求子树最大边权和

* 树形dp, $dp(i) = \max (0, dp(i), v(i), dp(j) + v(i) \text{ j is i's child })$

* ```c++
  vector<int> topo;
  vector<int> parent;
  void build() {
      topo.push_back(1);
      visited[1] = true;
      for (int i = 0;i < topo.size();i++) {
          int x = Q.front();
          Q.pop();
          for (auto edge: edges[x]) {
              int y = edge[1];
              if (!visited[y]) {
                  parent[y] = x;
                  topo.push_back(y);
                  visited[y] = true;
              }
          }
      }
      for (auto x = topo.rbegin();x != topo.rend();x++) {
          dp[x] = 0;
          for (auto edge：edges[x]) {
              if (edge[1] == parent[x]) {
                  continue;
              }
              dp[x] = max(dp[x], edge[2]);
              dp[x] = max(dp[x], edge[2] + dp[edge[1]]);
          }
      }
  }
  ```




### 分组背包

* > 题意：有n个人比赛，每个人都有一个权值，现在要将n个人分成两组，两组间的人数差<=1，问怎么分组可以使得两个组的人的权值和的差最小。
  >
  >  
  >
  > 第i个人的权值记为a[i]，令dp[i][j][k]表示只考虑前i个人，用j个人是否能将权值凑成k，如果可以则dp[i][j][k]=1,否则为0，那么转移就是如果dp[i-1][j][k]为1，那么dp[i][j+1][k+a[i]]也为1，否则为0，初始条件dp[0][0][0]=1。  



### 异或配对和

* > 题意：给出两个长度为n的数组a和b，然后求下面这个东西（n<=200000) 
  >
  > ```
  > int sum=0;
  > for(int i=0;i<n;i++){
  >     for(int j=0;j<n;j++){
  >         sum=sum^(a[i]+b[j]);
  >     }
  > }
  > cout<<sum<<endl;
  > ```

* 异或 -> 统计位贡献
* ![1569013145764](D:\OneDrive\Pictures\Typora\1569013145764.png)
* 





### 费用流 #1

* ![1569013008888](D:\OneDrive\Pictures\Typora\1569013008888.png)
* 找链环 -> 不存在, 可能环套链
* 二分图权值匹配KM -> 爆复杂度
* 最大费用网络流 队列优化BF -> 爆复杂度?





### 机器人走路

* 重复执行命令, 判断是否会遇到障碍

* 对每个障碍对每个取模情况考虑

* ```c++
  class Solution {
  public:
      bool robot(string command, vector<vector<int>>& obstacles, int x, int y) {
          int a=0,b=0,u=0,v=0;
          for(auto i:command)if(i=='R')a++;
          else b++;
          bool c=0;
          for(auto i:command)
          {
              for(auto j:obstacles)if(j[0]<=x&&j[1]<=y&&(j[0]-u)%a==0&&(j[1]-v)%b==0&&(j[0]-u)/a==(j[1]-v)/b)return 0;
              if((x-u)%a==0&&(y-v)%b==0&&(x-u)/a==(y-v)/b)c=1;
              if(i=='R')u++;
              else v++;
          }
          return c;
      }
  };
  ```



### 多米诺骨牌

* 带破损的多米诺最大个数

* 数位dp, 连续的竖骨牌: `j&k == 0`, 连续的横骨牌 `k >> n == 0, k >> n+1 == 0`

* ```c++
  class Solution {
  public:
      int domino(int n, int m, vector<vector<int>>& broken) {
          int a[10],f[10][256],ans=0,o[256],i,j,k;
          memset(a,0,sizeof(a));
          for(auto b:broken)a[b[0]]|=1<<b[1];
          memset(f,128,sizeof(f));
          f[0][(1<<m)-1]=0;
          // number of 1s
          for(i=1;i<1<<m;i++)
              o[i]=o[i>>1]+(i&1);
          for(i=0;i<n;i++)
          {
              for(j=0;j<1<<m;j++)
                  f[i+1][0]=max(f[i+1][0],f[i][j]);
              if(i)
                  for(j=0;j<1<<m;j++)
                      for(k=0;k<1<<m;k++)
                          if(!(j&k)&&!(a[i-1]&k)&&!(a[i]&k))
                              f[i+1][k]=max(f[i+1][k],f[i][j]+o[k]);
              for(j=0;j+1<m;j++)
                  if(!(a[i]>>j&1)&&!(a[i]>>j+1&1))
                      for(k=0;k<1<<m;k++)
                          if(!(k>>j&1)&&!(k>>j+1&1))
                              f[i+1][k|1<<j|1<<j+1]=max(f[i+1][k|1<<j|1<<j+1],f[i+1][k]+1);
          }
          for(i=0;i<1<<m;i++)
              ans=max(ans,f[n][i]);
          return ans;
      }
  };
  ```

* 二分匹配 (i+j % 2 二部图匹配)

* ```c++
  class Solution {
      int dx[4]={1,-1,0,0};
      int dy[4]={0,0,-1,1};
      bool use[20][20],broken[20][20],match[20][20];
      int nn,mm;
      pair<int,int> result[20][20];
      bool dfs(int x,int y)
      {
          for (int a=0;a<4;a++)
          {
              int xx = x+dx[a];
              int yy = y+dy[a];
              if (xx<0 || xx>=nn || yy<0 || yy>=mm) continue;
              if (!use[xx][yy] && !broken[xx][yy])
              {
                  use[xx][yy]=true;
                  if (!match[xx][yy] || dfs(result[xx][yy].first,result[xx][yy].second))
                  {
                      match[xx][yy]=true;
                      result[xx][yy] = make_pair(x,y);
                      return true;
                  }
              }
          }
          return false;
      }
      int resu(int n,int m)
      {
          memset(match,false,sizeof(match));
          int ans=0;
          for (int a=0;a<n;a++)
              for (int b=0;b<m;b++)
                  if ((a+b)%2==0 && !broken[a][b])
                  {
                      memset(use,false,sizeof(use));
                      if (dfs(a,b)) ans++;
                  }
          return ans;
      }
  public:
      int domino(int n, int m, vector<vector<int>>& bro) {
          nn=n;mm=m;
          memset(broken,false,sizeof(broken));
          for (int a=0;a<bro.size();a++)
              broken[bro[a][0]][bro[a][1]]=true;
          return resu(n,m);
      }
  };
  ```

* 二分匹配当然也可以网络流

* ```c++
  namespace dinic {
  
  	using F = int;
  	const F INF = 1000000000;
  
  	const int N = 220000;
  	const int M = 1100000;
  
  	int fst[N], nxt[M], to[M];
  	F cap[M];
  	int dis[N], q[N], ptr[N];
  	int V, E;
  
  	void init(int n) {
  		memset(fst, -1, sizeof fst);
  		V = n;
  		E = 0;
  	}
  	
  	inline void add_edge(int u, int v, F c, F d = 0) {
  		to[E] = v, cap[E] = c, nxt[E] = fst[u], fst[u] = E++;
  		to[E] = u, cap[E] = d, nxt[E] = fst[v], fst[v] = E++;
  	}
  	inline bool bfs(int S, int T, int n) {
  		memset(dis, -1, sizeof(int) * n);
  		int h = 0, t = 0;
  		dis[S] = 0, q[t++] = S;
  		while (h < t) {
  			int u = q[h++];
  			for (int e = fst[u]; ~e; e = nxt[e]) if (cap[e] > 0 && dis[to[e]] == -1) {
  				dis[to[e]] = dis[u] + 1, q[t++] = to[e];
  				if (to[e] == T) return 1;
  			}
  		}
  		return (dis[T] != -1);
  	}
  	F dfs(int u, int T, F f) {
  		if (u == T) return f;
  		for (int &e = ptr[u]; ~e; e = nxt[e]) if (cap[e] > 0 && dis[to[e]] > dis[u]) {
  			F ret = dfs(to[e], T, min(f, cap[e]));
  			if (ret > 0) {
  				cap[e] -= ret, cap[e ^ 1] += ret;
  				return ret;
  			}
  		}
  		return 0;
  	}
  	F max_flow(int S, int T, int n = V) {
  		F ret = 0;
  		while (bfs(S, T, n)) {
  			memcpy(ptr, fst, sizeof(int) * n);
  			for (F cur; (cur = dfs(S, T, INF)) > 0; ret += cur);
  		}
  		return ret;
  	}
  }
  
  class Solution {
  public:
      int domino(int n, int m, vector<vector<int>>& broken) {
          vector<vector<int>> a(n, vector<int>(m));
          for (auto e : broken)
          {
              a[e[0]][e[1]] = 1;
          }
          int dx[] = {-1, 1, 0, 0};
          int dy[] = {0, 0, -1, 1};
          
          int S = n*m+1, T = n*m+2;
          dinic::init(n*m+5);
          
          auto place = [&](int x, int y)
          {
              return x*m+y+1;
          };
          
          for (int i = 0; i < n; ++ i)
              for (int j = 0; j < m; ++ j)
              {
                  if ((i+j)%2)
                  {
                      dinic::add_edge(place(i, j), T, 1);
                      continue;
                  }
                  dinic::add_edge(S, place(i, j), 1);
                  for (int k = 0; k < 4; ++ k)
                  {
                      int x = i+dx[k], y = j+dy[k];
                      if (0 <= x && x < n && 0 <= y && y < m && !a[i][j] && !a[x][y])
                      {
                          dinic::add_edge(place(i, j), place(x, y), 1);
                      }
                  }
              }
          return dinic::max_flow(S, T, n*m+5);
      }
  };
  
  ```

* 