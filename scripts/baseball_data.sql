-- Use SQL queries to find answers to the Initial Questions. If time permits, choose one (or more) of the Open-Ended Questions. Toward the end of the bootcamp, we will revisit this data if time allows to combine SQL, Excel Power Pivot, and/or Python to answer more of the Open-Ended Questions.

-- Initial Questions

-- 1. What range of years for baseball games played does the provided database cover?

-- This database contains pitching, hitting, and fielding statistics for Major League Baseball from 1871 through 2016.

SELECT 
	DISTINCT yearid 
FROM teams;

SELECT 
	MIN(yearid), 
	MAX(yearid)
FROM teams;

-- A1: "This database contains pitching, hitting, and fielding statistics for Major League Baseball from 1871 through 2016." - data dictionary
-- Confirmed through queries above

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT 
	namefirst, 
	namelast, 
	height
FROM people
ORDER BY height
LIMIT 1;

SELECT 
	namefirst, 
	namelast, 
	height
FROM people
ORDER BY height
LIMIT 1;

SELECT *
FROM people
ORDER BY height
LIMIT 1;

SELECT * FROM teams

SELECT 
	namefirst, 
	namelast, 
	height,
	teams.name
FROM people
	INNER JOIN batting
	USING (playerid)
	INNER JOIN teams
	ON batting.teamid = teams.teamid
ORDER BY height
LIMIT 1;

-- Eddie Gaelel, 43 inches, St. Louis Browns

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT 
	playerid,
	schoolname, 
	namefirst,
	namelast,
	SUM(salary) AS salary_sum
FROM schools
	LEFT JOIN collegeplaying
	USING (schoolid)
	LEFT JOIN people
	USING (playerid)
	LEFT JOIN salaries
	USING (playerid)
	LEFT JOIN managers
	USING (playerid)
WHERE schoolname LIKE '%Vanderbilt University%'
	And salary IS NOT NULL
GROUP BY playerid, schoolname, namefirst, namelast
ORDER BY salary_sum DESC

-- 3A: David Price

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT *
FROM fielding

SELECT  
	SUM(po) AS putouts,
	CASE WHEN pos = 'SS' OR pos = '1B' OR pos = '2B' OR pos = '3B' THEN 'Infield'
		WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos = 'P' OR pos = 'C' THEN 'Battery'
		END pos_type
FROM fielding
WHERE yearid = '2016'
GROUP BY pos_type
ORDER BY putouts DESC;

-- Infield: 58934
-- Outfield: 29560
-- Battery: 41424

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

--divide by the home games games table?
SELECT 
	yearid, 
	so, 
	g,
	(SELECT so/g) AS avg_so
FROM teams;

--roll up rows into decade
--group by presents an issue

--THINGS TO CONSIDER
--1. what are the data types of so and g/how might that affect numbers
	--they're integers
--2. what is the teams table doing? for every team for every year, how many games did they play? step missing


SELECT
	FLOOR((yearid/10)*10) AS decade, --FLOOR came from a classmate; I'm not sure it changes anything
	ROUND(AVG(so/g), 2) AS avg_so,
	ROUND(AVG(hr/g), 2) AS avg_hr
FROM teams
WHERE yearid >= 1920
GROUP BY decade 
ORDER BY decade;

-- 6. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.

WITH stolen_bases AS (
	SELECT 
	playerID,
	SUM(sb::numeric) AS stolen_bases,
	SUM(cs::numeric) AS caught_stealing,
	(((SUM(sb))/((SUM(sb::numeric))+(SUM(cs::numeric))))*100) AS percent_stolen
FROM batting
WHERE sb IS NOT NULL
AND cs IS NOT NULL
AND yearid = 2016
GROUP BY playerID
HAVING (SUM(sb) + SUM(cs)) > 19
)
SELECT 
	namefirst,
	namelast,
	stolen_bases,
	caught_stealing,
	percent_stolen
FROM people AS p
INNER JOIN stolen_bases AS s
USING (playerid)
ORDER BY percent_stolen DESC

-- Chris Owings: 91.30% stolen

-- 7. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

SELECT
	yearid,
	name,
	SUM(w) AS wins
FROM teams
WHERE wswin = 'N'
	AND yearid BETWEEN 1970 AND 2016
GROUP BY name, yearid
ORDER BY SUM(w) DESC;
-- 2001 Seattle Mariners: 116 wins

SELECT
	yearid,
	name,
	SUM(w) AS wins
FROM teams
WHERE wswin = 'Y'
	AND yearid BETWEEN 1970 AND 2016
GROUP BY name, yearid
ORDER BY SUM(w);
-- 1981 is the outlier with only 63 wins by the LA Dodgers
-- digging into 1981 below
SELECT 
	SUM(g) AS total_games, 
	yearid AS year
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
GROUP BY yearid
ORDER BY SUM(g)
-- We see there are far fewer games from 1981. A quick Google search reveals: "At 12:30 A.M on June 12th, union chief Marvin Miller announced the player's strike beginning the longest labor action to date in American sports history. By the time the season finally resumed on August 10th, seven-hundred six games (38 percent of the Major League schedule) had been canceled." (Source: Baseball Almanac)

SELECT
	yearid,
	name,
	SUM(w) AS wins
FROM teams
WHERE wswin = 'Y'
	AND yearid BETWEEN 1970 AND 2016
	AND yearid != 1981
GROUP BY name, yearid
ORDER BY SUM(w);
-- Now we get 2006 St. Louis Cardinals: 83

-- Final part: How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
-- SUM(CASE WHEN wswin= 'Y' THEN 1 ELSE 0 END)

SELECT
	yearid,
	name,
	SUM(w) AS wins
FROM teams
WHERE wswin = 'Y'
	AND yearid BETWEEN 1970 AND 2016
	AND yearid != 1981
GROUP BY name, yearid
ORDER BY SUM(w);

--- PLEASE NOTE: this code (for the final part of 7) came from classmates and is not the result of my own labor. I'd like to go back later to try to recreate the solution ---
WITH series_losers AS (SELECT yearid, MAX(w) AS maxwins_series_losers	
					FROM teams
						WHERE yearid BETWEEN 1970 AND 2016
								AND wswin='N'
					   			AND yearid <> 1981
					GROUP BY yearid
					ORDER BY yearid DESC),
series_winners AS (SELECT yearid, MIN(w) AS minwins_series_winners
					FROM teams
						WHERE yearid BETWEEN 1970 AND 2016
								AND wswin='Y'
				   				AND yearid <> 1981
					GROUP BY yearid
					ORDER BY yearid DESC)				
SELECT
	ROUND(SUM(CASE WHEN sl.maxwins_series_losers < sw.minwins_series_winners 							THEN 1.00 ELSE 0 END)/COUNT(sw.minwins_series_winners)*100,2) AS percent_of_greater_wins_of_series_winners,
	ROUND(SUM(CASE WHEN sl.maxwins_series_losers > sw.minwins_series_winners 							THEN 1.00 ELSE 0 END)/COUNT(sl.maxwins_series_losers)*100,2) AS percent_of_greater_wins_of_series_losers,
	ROUND(SUM(CASE WHEN sl.maxwins_series_losers = sw.minwins_series_winners 							THEN 1.00 ELSE 0 END)/COUNT(sw.minwins_series_winners)*100,2) AS percent_of_tie_between_losers_winners
FROM series_losers as sl
JOIN series_winners as sw
USING (yearid)

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

SELECT *
FROM homegames

SELECT *
FROM parks

SELECT 
	team, 
	SUM(attendance)/SUM(games) AS avg_attendance
FROM homegames AS h
INNER JOIN parks AS p
USING (park)
WHERE year = '2016'
AND games >= 10
GROUP BY team, games, park
ORDER BY avg_attendance DESC
LIMIT 5;


SELECT 
	team, 
	SUM(attendance)/SUM(games) AS avg_attendance
FROM homegames AS h
INNER JOIN parks AS p
USING (park)
WHERE year = '2016'
AND games >= 10
GROUP BY team, games, park
ORDER BY avg_attendance
LIMIT 5;

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

SELECT *
FROM awardsmanagers

-- this is the answer I get when I'm just pulling information from awardsmanagers via two CTEs. I believe this is correct.
WITH NL_wins AS (
	SELECT yearid, playerid AS NL_winners
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
		AND lgid = 'NL'),
AL_wins AS (
	SELECT yearid, playerid AS AL_winners
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
		AND lgid = 'AL')
SELECT DISTINCT 
	NL_winners AS winner_id
FROM NL_wins
INNER JOIN AL_wins -- using an inner joins seems to effectively filter down to the two people who won both
ON nl_winners = al_winners

-- But this is the actual solution!
SELECT p.namefirst, p.namelast, m.teamid AS team, am1.yearid AS am1_year, am1.lgid AS am1_league, am1.awardid AS am1_award, am2.yearid AS am2_year, am2.lgid AS am2_league, am2.awardid AS am2_award
FROM awardsmanagers AS am1
JOIN awardsmanagers AS am2
USING (playerid)
INNER JOIN people AS p
USING (playerid)
INNER JOIN managers AS m
USING (playerid)
WHERE am1.awardid = 'TSN Manager of the Year'
AND am2.awardid = 'TSN Manager of the Year'
AND ((am1.lgid = 'AL' AND am2.lgid = 'NL')
OR (am1.lgid = 'NL' AND am2.lgid = 'AL'))
AND (m.yearid = am1.yearid)


-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

SELECT *
FROM batting

WITH 2016_hrs AS( -- hrs in 2016 CTE
(SELECT 
	SUM(hr) AS home_runs, 
	playerid
FROM batting
LEFT JOIN people
USING (playerid)
WHERE yearid = 2016
GROUP BY playerid
HAVING SUM(hr) > 0),

ten_years AS ( -- players in league for 10+years CTE (is there a better way to get this info?)
SELECT playerid
FROM people
WHERE )

--well this is not working because of the calculation, but I'm thinking something like this:
SELECT playerid, (debut::date), (finalgame:: date)
FROM people
WHERE (finalgame - debut) = 10

-- still need a max hrs cte and a main query to stitch it together ... am I forgetting something

-- Open-ended questions

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.

-- i. Does there appear to be any correlation between attendance at home games and number of wins?

-- ii. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?