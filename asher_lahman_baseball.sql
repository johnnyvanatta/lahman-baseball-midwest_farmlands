-- 1. What range of years for baseball games played does the provided database cover? 
SELECT MIN(year) AS first_year, 
       MAX(year) AS last_year
FROM homegames;

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
   WITH shortest AS(
   	SELECT *
   	FROM people
   		LEFT JOIN appearances USING (playerid)
	ORDER BY height
	LIMIT 1)
	SELECT name AS team, SUM(g) AS total_games_played
	FROM shortest
	LEFT JOIN teams ON shortest.teamid = teams.teamid
	GROUP BY name;
	
-- 3. Find all players in the database who played at Vanderbilt University. 
SELECT DISTINCT(playerid), schoolname
FROM collegeplaying
	LEFT JOIN schools USING (schoolid)
	WHERE schoolname = 'Vanderbilt University';
	
-- Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
-- Sort this list in descending order by the total salary earned. 
-- Which Vanderbilt player earned the most money in the majors?
WITH vandy_players AS (
SELECT DISTINCT playerid, schoolname
FROM collegeplaying
	LEFT JOIN schools USING (schoolid)
	WHERE schoolname = 'Vanderbilt University')

SELECT CONCAT(namefirst, ' ', namelast)AS full_name, SUM(salary::text::integer::money) AS total_salary
FROM vandy_players
	LEFT JOIN salaries USING (playerid)
	LEFT JOIN people USING (playerid)
	GROUP BY full_name
	ORDER BY total_salary DESC NULLS LAST;
	
--4. Using the fielding table, group players into three groups based on their position: \
-- label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", 
-- and those with position "P" or "C" as "Battery". 
-- Determine the number of putouts made by each of these three groups in 2016.
SELECT CASE 
			WHEN f.pos = 'SS' OR f.pos= '1B' OR f.pos= '2B' OR f.pos = '3B' THEN 'Infield'
			WHEN f.pos = 'OF' THEN 'Outfield'
			WHEN f.pos = 'P' OR f.pos = 'C' THEN 'Battery'
			END AS position_categories,
		SUM(po) AS total_po_per
FROM fielding AS f
WHERE f.yearid = '2016'
GROUP BY position_categories
ORDER BY total_po_per DESC;

--5. Find the average number of strikeouts per game by decade since 1920. 
-- Round the numbers you report to 2 decimal places. 
-- Do the same for home runs per game. Do you see any trends?
SELECT CASE
			WHEN yearid BETWEEN 1920 AND 1929 THEN '1920s'
			WHEN yearid BETWEEN 1930 AND 1939 THEN '1930s'
			WHEN yearid BETWEEN 1940 AND 1949 THEN '1940s'
			WHEN yearid BETWEEN 1950 AND 1959 THEN '1950s'
			WHEN yearid BETWEEN 1960 AND 1969 THEN '1960s'
			WHEN yearid BETWEEN 1970 AND 1979 THEN '1970s'
			WHEN yearid BETWEEN 1980 and 1989 THEN '1980s'
			WHEN yearid BETWEEN 1990 AND 1999 THEN '1990s'
			WHEN yearid BETWEEN 2000 AND 2009 THEN '2000s'
			WHEN yearid BETWEEN 2010 AND 2019 THEN '2010s'
			END AS decades,
			ROUND(SUM(so)::numeric/SUM(g)::numeric, 2)
FROM pitching
GROUP BY decades
ORDER BY decades DESC NULLS LAST; 

SELECT CASE
			WHEN yearid BETWEEN 1920 AND 1929 THEN '1920s'
			WHEN yearid BETWEEN 1930 AND 1939 THEN '1930s'
			WHEN yearid BETWEEN 1940 AND 1949 THEN '1940s'
			WHEN yearid BETWEEN 1950 AND 1959 THEN '1950s'
			WHEN yearid BETWEEN 1960 AND 1969 THEN '1960s'
			WHEN yearid BETWEEN 1970 AND 1979 THEN '1970s'
			WHEN yearid BETWEEN 1980 and 1989 THEN '1980s'
			WHEN yearid BETWEEN 1990 AND 1999 THEN '1990s'
			WHEN yearid BETWEEN 2000 AND 2009 THEN '2000s'
			WHEN yearid BETWEEN 2010 AND 2019 THEN '2010s'
			END AS decades,
			ROUND(SUM(HR)*100::numeric/SUM(G)::numeric, 2)||'%' AS percent_hr_per_game
FROM batting
GROUP BY decades
ORDER BY decades DESC NULLS LAST;

--6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

--7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
SELECT yearid AS year,teamid AS team,w AS wins,WSWin AS world_series_win
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'N'
ORDER BY w DESC
LIMIT 1;
-- What is the smallest number of wins for a team that did win the world series? 
SELECT yearid, teamid, w,WSWin
FROM teams
WHERE wswin = 'Y'
ORDER BY w
LIMIT 1;
-- Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case.
-- ANSWER: PLAYER STRIKE IN 1981 CAUSED HALF THE SEASON TO BE CANCELLED.

-- Then redo your query, excluding the problem year. 
SELECT yearid, teamid, w,WSWin
FROM teams
WHERE yearid <> 1981
	AND wswin = 'Y'
ORDER BY w
LIMIT 1;
-- How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 
WITH no_wsw AS (
	SELECT MAX(w) AS no_wsw_max, yearid
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'N'
	GROUP BY yearid
	ORDER BY yearid),

yes_wsw AS(
SELECT MAX(w) AS yes_wsw_max, yearid
FROM teams 
WHERE yearid BETWEEN 1970 AND 2016
GROUP BY yearid
ORDER BY yearid),

first_final_table AS(
SELECT *, CASE WHEN yes_wsw_max>no_wsw_max THEN '1'
		       ELSE '0'
			   END AS most_wins_wsw
FROM yes_wsw
	FULL JOIN no_wsw USING (yearid)),

final_table AS(
	SELECT most_wins_wsw::numeric AS most_wins_wsw
	FROM first_final_table)

SELECT SUM(most_wins_wsw) AS most_wins_and_wsw_count
FROM final_table;

-- What percentage of the time?
WITH no_wsw AS (
	SELECT MAX(w) AS no_wsw_max, yearid
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'N'
	GROUP BY yearid
	ORDER BY yearid),

yes_wsw AS(
SELECT MAX(w) AS yes_wsw_max, yearid
FROM teams 
WHERE yearid BETWEEN 1970 AND 2016
GROUP BY yearid
ORDER BY yearid),

first_final_table AS(
SELECT *, CASE WHEN yes_wsw_max>no_wsw_max THEN '1'
		       ELSE '0'
			   END AS most_wins_wsw
FROM yes_wsw
	FULL JOIN no_wsw USING (yearid)),

final_table AS(
	SELECT most_wins_wsw::numeric AS most_wins_wsw
	FROM first_final_table)

SELECT ROUND(SUM(most_wins_wsw)*100/COUNT(*),2)||'%' AS percent_most_wins_and_wsw_count
FROM final_table;

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 
-- (where average attendance is defined as total attendance divided by number of games). 
-- Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
SELECT team, park, SUM(attendance)/SUM(games) AS avg_attendance
FROM homegames
WHERE year = 2016
	AND games >=10
GROUP BY team, park
ORDER BY avg_attendance DESC
LIMIT 5;

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
-- Give their full name and the teams that they were managing when they won the award.
WITH nl_winners AS(
SELECT *
FROM awardsmanagers
WHERE awardid = 'TSN Manager of the Year'
	AND lgid = 'NL'),

al_winners AS(
SELECT *
FROM awardsmanagers
WHERE awardid = 'TSN Manager of the Year'
	AND lgid ='AL'),

al_and_nl_winners AS(
SELECT *
FROM awardsmanagers
WHERE playerid IN (SELECT playerid
				   FROM awardsmanagers
				   WHERE awardid = 'TSN Manager of the Year'
				   AND lgid ='AL')
	AND playerid IN (SELECT playerid
				     FROM awardsmanagers
					 WHERE awardid = 'TSN Manager of the Year'
				   	 AND lgid = 'NL')
	AND awardid = 'TSN Manager of the Year')

SELECT DISTINCT(namefirst), namelast, name, al_and_nl_winners.yearid, al_and_nl_winners.lgid
FROM al_and_nl_winners
	LEFT JOIN people USING (playerid)
	LEFT JOIN managers USING (playerid, yearid)
	LEFT JOIN teams ON managers.teamid=teams.teamid
	WHERE teams.yearid>1900
ORDER BY yearid DESC;
	
-- 10. Find all players who hit their career highest number of home runs in 2016. 
-- Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. 
-- Report the players' first and last names and the number of home runs they hit in 2016.

-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
-- Does there appear to be any correlation between attendance at home games and number of wins?
-- Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? 


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

  
