/* Contains my solutions to various SQL problems on LeetCode that I find
particularly instructive. For some problems, I've writen multiple answers where one is usually the
more elegant version. */

-- 1454. Active Users
-- This is a difficult problem that took me some time to understand.
-- This type of problem is called the gaps and islands problem.
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

/* The below solution works by doing a self-join (it's not a cross join because of the two ON conditions)
and filtering that self-join for records where the difference between dates is between 0 and 4,
so only l2.login_dates that meet that criteria will be joined with the original table. Doing so allows
us to do a group by id and login_date so then we can see which of those groupings have a count
of distinct l2.login_dates that equals 5 (5 because that represents
5 consecutive dates). The distinct id and name from that grouping is the right answer. */

 SELECT DISTINCT l1.id, a.name
   FROM Logins AS l1
   JOIN Logins AS l2
     ON l1.id = l2.id AND DATEDIFF(l2.login_date, l1.login_date) BETWEEN 0 AND 4
   JOIN Accounts AS a
     ON l1.id = a.id
  GROUP BY l1.id, l1.login_date
 HAVING COUNT(DISTINCT l2.login_date) = 5;

SUM(CASE WHEN "Status" LIKE '*cancelled*' THEN 1 END)

-- 601. Human Traffic of Stadium

-- This is another gaps and islands problem.
-- The thing I learned here is that it's possible to coincidentally have the
-- same grouping number for your two categories; that means I have to add another layer
-- to differentiate my groupings, which I did using a letter: H to indicate
-- high traffic grouping and L to indicate low traffic.

WITH status_cte AS (
    SELECT *,
           CASE WHEN people >= 100 THEN 'high_traffic' ELSE 'low_traffic' END AS status
      FROM Stadium
     ORDER BY id
),
dense_rank_cte AS (
    SELECT *, DENSE_RANK() OVER(PARTITION BY status ORDER BY id) AS rankings
      FROM status_cte
     ORDER BY id
),
grouping_cte AS (
    SELECT *, id - rankings AS groupings
      FROM dense_rank_cte
     ORDER BY id
),
grouping_differentiated_cte AS (
    SELECT *, CASE WHEN status = 'high_traffic' THEN CONCAT(CAST(groupings AS char), 'H')
                   ELSE CONCAT(CAST(groupings AS char), 'L') END AS groupings_diff
      FROM grouping_cte
     ORDER BY id
),
agg_cte AS (
    SELECT groupings_diff, SUM(CASE WHEN people >= 100 THEN 1 ELSE 0 END) AS num_days_high_traffic
      FROM grouping_differentiated_cte
     GROUP BY 1
    HAVING SUM(CASE WHEN people >= 100 THEN 1 ELSE 0 END) >= 3
)
SELECT id, visit_date, people
  FROM grouping_differentiated_cte
 WHERE groupings_diff IN (SELECT groupings_diff FROM agg_cte)
 ORDER BY visit_date;

-- Alternatively, I can make sure to only count the records that are the high_traffic
-- records when I do my aggregation and only show the records that are high_traffic
-- in my answer. This doesn't get rid of the problem of the groupings potentially
-- mixing low_traffic and high_traffic records together; this just allows me to filter
-- out the low_traffic records from groupings that have both types of records.

 WITH status_cte AS (
    SELECT *,
           CASE WHEN people >= 100 THEN 'high_traffic' ELSE 'low_traffic' END AS status
      FROM Stadium
     ORDER BY id
),
dense_rank_cte AS (
    SELECT *, DENSE_RANK() OVER(PARTITION BY status ORDER BY id) AS rankings
      FROM status_cte
     ORDER BY id
),
grouping_cte AS (
    SELECT *, id - rankings AS groupings
      FROM dense_rank_cte
     ORDER BY id
),
agg_cte AS (
    SELECT groupings, SUM(CASE WHEN people >= 100 THEN 1 ELSE 0 END) AS num_days_high_traffic
      FROM grouping_cte
     WHERE status = 'high_traffic'
     GROUP BY 1
    HAVING SUM(CASE WHEN people >= 100 THEN 1 ELSE 0 END) >= 3
)
SELECT id, visit_date, people
  FROM grouping_cte
 WHERE groupings IN (SELECT groupings FROM agg_cte) AND status = 'high_traffic'
 ORDER BY visit_date;
