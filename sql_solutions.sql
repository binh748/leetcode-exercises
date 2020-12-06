/* Contains my solutions to various SQL problems on LeetCode that I find
particularly instructive. For some problems, I've writen multiple answers where one is usually the
more elegant version. */

-- 1454. Active Users
-- This is a difficult problem that took me some time to understand.
-- Here are links to resources that helped me figure out this problem:
-- https://leetcode.com/problems/active-users/discuss/644070/100-Faster-than-Submissions-Window-Functions-Documentation-Linked
-- https://mattboegner.com/improve-your-sql-skills-master-the-gaps-islands-problem/
-- https://stackoverflow.com/questions/26117179/sql-count-consecutive-days
-- https://leetcode.com/problems/active-users/discuss/642956/Simple-MySQL-solution-without-window-function

WITH dense_rank_cte AS (
    SELECT id, login_date,
           DENSE_RANK() OVER(PARTITION BY id ORDER BY login_date) AS dense_rank_num 
      FROM Logins
),
grouping_cte AS (
    SELECT id, login_date, dense_rank_num,
           DATE_ADD(login_date, INTERVAL -dense_rank_num DAY) AS groupings
      FROM dense_rank_cte
),
grouping_info_cte AS (
    SELECT id, MIN(login_date) AS start_date, MAX(login_date) AS end_date,
           dense_rank_num, groupings, COUNT(*),
           DATEDIFF(MAX(login_date), MIN(login_date)) + 1 AS duration
      FROM grouping_cte
     GROUP BY id, groupings
    HAVING DATEDIFF(MAX(login_date), MIN(login_date)) + 1 >= 5
    ORDER BY id, start_date
)
SELECT DISTINCT g.id, a.name
  FROM grouping_info_cte AS g
  JOIN Accounts AS a
 USING(id)
 ORDER BY g.id;

-- The below is an alternative solution, which does not use a window function
-- This solution, though, is slower because it creates a cross join between the two tables
-- which is costly, especially for larger tables.

/* The below solution works by doing a self-join (which createa a cross join of the table with itself)
and then filtering that cross join for only records where the difference between dates is between 0 and 4,
so only l2.login_dates that meet that criteria will be in the result set. That then allows
us to do a group by id and login_date so then we can see which of those groupings have a count
of distinct l2.login_dates that equals 5 (5 is the right number here because that represents
5 consecutive dates). The distinct id and name from that grouping is the right answer. */

 SELECT DISTINCT l1.id, a.name
   FROM Logins AS l1
   JOIN Logins AS l2
     ON l1.id = l2.id AND DATEDIFF(l2.login_date, l1.login_date) BETWEEN 0 AND 4
   JOIN Accounts AS a
     ON l1.id = a.id
  GROUP BY l1.id, l1.login_date
 HAVING COUNT(DISTINCT l2.login_date) = 5;
