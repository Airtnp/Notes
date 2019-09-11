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

* 









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