-- ## Lahman Baseball Database Exercise
-- this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
-- A data dictionary is included with the files for this project.


-- 1. What range of years for baseball games played does the provided database cover? 
-- A - 1871 through 2016
SELECT MIN(year) AS first_year,
	   MAX(year) AS last_year
FROM homegames;


-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
-- shortest player is Eddie Gaedel and his height was 43" and played 1 total gamea for the St. Louis Browns

SELECT CONCAT(namefirst, ' ', namelast) AS full_name, g_all AS total_games, name AS team, height
FROM people
	INNER JOIN appearances USING(playerid)
	INNER JOIN teams USING(teamid, yearid)
WHERE height = (SELECT MIN(height) FROM people);

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order
-- by the total salary earned. Which Vanderbilt player earned the most money in the majors?

-- ANSWER: David Price has the highest career earnings that came from the Vanderbilt University Baseball program with $81 Million career earnings


--- Vandy Player CTE
WITH vandy_players AS (
SELECT DISTINCT playerid
FROM collegeplaying
	INNER JOIN schools USING(schoolid)
WHERE schoolname = 'Vanderbilt University')
----------------------------------------------------
SELECT namefirst AS first_name, namelast AS last_name, SUM(salary)::text::numeric::money AS total_salary
FROM vandy_players
	LEFT JOIN salaries USING(playerid)
	LEFT JOIN people USING(playerid)
WHERE salary IS NOT NULL
GROUP BY namefirst, namelast
ORDER BY total_salary DESC;




-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
-- Determine the number of putouts made by each of these three groups in 2016.
SELECT 
	CASE WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
		 WHEN pos IN ('OF') THEN 'Outfield'
		 WHEN pos IN ('P', 'C') THEN 'Battery'
		 END AS position_group,
SUM(po) AS total_putouts
FROM fielding
WHERE yearid = 2016
GROUP BY position_group
ORDER BY total_putouts DESC;

   
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

-- TRENDS: Homeruns peaked in the 200's and generally increased over time. Strikeouts also steadily increased every year since 1920's.

WITH decades AS (
	SELECT CONCAT((yearid/10 * 10)::text, '''s') AS decade, *
	FROM teams
	WHERE yearid >= 1920)

SELECT decade,
	ROUND(sum(hr)/(SUM(g)::numeric/2), 2) AS hr_per_game,
	ROUND(sum(so)/(SUM(g)::numeric/2), 2) AS so_per_game
FROM decades
GROUP BY decade
ORDER BY decade



-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) 
-- Consider only players who attempted _at least_ 20 stolen bases.

-- ANSWER: CHRIS OWINGS HAD THE HIGHEST STEAL SUCCESS RATE AT 91.3% IN 2016. 

SELECT CONCAT(namefirst, ' ', namelast) AS full_name, ROUND(sb::numeric / (cs + sb) * 100, 2)||'%' AS success_rate
FROM batting
	INNER JOIN people USING(playerid)
WHERE yearid = 2016
AND (sb+cs) >= 20
AND sb IS NOT NULL AND cs IS NOT NULL AND (sb + cs) > 0
ORDER BY success_rate DESC





-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an 
-- unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also 
-- won the world series? What percentage of the time?

-- MOST WINS WIHTOUT WOLRD SERIES WIN: Seattle Mariners had the most wins in a sesaon without winning a wolrd series. They did it in 2001 and had 116 wins and won 71.6% of their games
SELECT yearid, name, w, wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'N'
ORDER BY w DESC

--------------- with win % added in
SELECT yearid, name, w, wswin, ROUND((w::numeric/g) * 100, 2)||'%' AS win_percentage
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'N'
ORDER BY w DESC


-- LEAST WINS WITH A WORLD SERIES WIN: The Los Angeles Dodgers had the least amount of wins (63) to win a world series. They did it in 1981
SELECT yearid, name, w, wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'Y'
ORDER BY w ASC


-- Excluding the year 1981, the team with the least amount of wins to win a World Series was the 2006 St. Louis Cardinals who won the WS with only 83 wins. 1981 had to be excluded because players were on strike for the majority of the season. 
-- 1/3 of that 1981 season was canceled and therefor had less games and less wins to show for it
SELECT yearid, franchid, w, wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
AND yearid <> 1981
AND wswin = 'Y'
ORDER BY w ASC


-- How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

WITH most_wins AS (
	SELECT yearid, MAX(w) AS most_wins
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
		AND yearid <> 1981
		AND yearid <> 1994
	GROUP BY yearid)
---------------------------------------
SELECT 
	SUM(CASE WHEN wswin = 'Y' THEN 1 END) AS total_world_series_wins,
	ROUND(AVG(CASE WHEN wswin = 'Y' THEN 1 ELSE 0 END)* 100, 2) AS win_pct
FROM most_wins
	INNER JOIN teams USING(yearid)
WHERE w = most_wins



-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). 
-- Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

-- ANSWER: TOP 5 ATTENDANCE
-- Los Angeles Dodgers with the highest with 45,719

SELECT name, teams.park, homegames.attendance/games AS avg_attendance
FROM homegames 
	INNER JOIN teams ON team = teamid
	AND year = yearid
WHERE year = 2016
AND games >= 10
ORDER BY avg_attendance DESC
LIMIT 5


-- ANSWER: BOTTOM 5 ATTENDANCE
-- Tampa Bay Rays with the lowest at 15,878
SELECT name, teams.park, homegames.attendance/games AS avg_attendance
FROM homegames 
	INNER JOIN teams ON team = teamid
	AND year = yearid
WHERE year = 2016
AND games >= 10
ORDER BY avg_attendance ASC
LIMIT 5

--- SAME ANSWER IN UNION FORM

(SELECT name, teams.park, homegames.attendance/games AS avg_attendance, 'top_5' AS attendance_rank
FROM homegames 
	INNER JOIN teams ON team = teamid
	AND year = yearid
WHERE year = 2016
AND games >= 10
ORDER BY avg_attendance DESC
LIMIT 5)
UNION
(SELECT name, teams.park, homegames.attendance/games AS avg_attendance, 'bottom_5' AS attendance_rank
FROM homegames 
	INNER JOIN teams ON team = teamid
	AND year = yearid
WHERE year = 2016
AND games >= 10
ORDER BY avg_attendance 
LIMIT 5)
ORDER BY avg_attendance DESC





-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
-- Give their full name and the teams that they were managing when they won the award.

--ANSWER: DAVEY JOHNSON AND JIM LEYLAND

SELECT yearid AS year, CONCAT(namefirst, ' ', namelast) AS full_name, name AS team_name, awardid AS award, awardsmanagers.lgid AS league
FROM awardsmanagers
	INNER JOIN managers USING (playerid, yearid)
	INNER JOIN people USING(playerid)
	INNER JOIN teams USING(teamid, yearid)
WHERE playerid IN
		(SELECT playerid
		FROM awardsmanagers
			INNER JOIN managers USING(playerid, yearid)
		WHERE awardid LIKE 'TSN%'
			AND awardsmanagers.lgid IN ('AL', 'NL')
		GROUP BY playerid
		HAVING COUNT(DISTINCT awardsmanagers.lgid) = 2) AND awardid LIKE 'TSN%'
ORDER BY namelast





-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, 
-- and who hit at least one home run in 2016. 
-- Report the players' first and last names and the number of home runs they hit in 2016.


WITH most_hr AS (
	(SELECT playerid, MAX(hr) AS most_hr
	FROM batting
	GROUP BY playerid))
------------------------
SELECT namefirst, namelast, hr
FROM most_hr 
	INNER JOIN batting USING(playerid)
	INNER JOIN people USING(playerid)
WHERE hr = most_hr AND yearid = 2016 AND LEFT(debut, 4)::numeric <= 2007 AND hr > 0
ORDER BY most_hr DESC


