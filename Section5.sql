USE mavenfuzzyfactory;
-- Section 5.34: Finding Top Website Pages
SELECT
	pageview_url,
	COUNT(DISTINCT website_pageview_id) as sessions
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY pageview_url
ORDER BY 2 DESC
;

-- Section 5.36: Finding Top Entry Pages
-- STEP 1: Find the first pageview for each session
-- STEP 2: find the url the customer saw on that first pageview
CREATE TEMPORARY TABLE entry_page_table
SELECT 
	website_session_id,
    MIN(website_pageview_id) as first_pv
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY 1;

SELECT
	w.pageview_url as landing_page,
    COUNT(DISTINCT w.website_session_id) as sessions_hitting_this_landing_page
FROM website_pageviews w
	LEFT JOIN entry_page_table e
    ON e.first_pv = w.website_pageview_id
WHERE created_at < '2012-06-12'
GROUP BY 1
ORDER BY 2 DESC;

-- Section 5.39: Calculating Bounce Rate
-- STEP 1: find the first website_pageview_id for relevant session
-- STEP 2: identify the landing page of each session
-- STEP 3: counting pageviews for each session, to identify bounces
-- STEP 4: summarizing total sessions and bounce sessions, by LP
CREATE TEMPORARY TABLE landing_page
SELECT 
	website_session_id,
	MIN(website_pageview_id) as first_pageview
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY 1
;
-- SELECT * from landing_page;
CREATE TEMPORARY TABLE sessions_w_home_landing_page;
SELECT
	w.website_session_id,
	w.pageview_url
FROM website_pageviews w
	LEFT JOIN landing_page l
    ON l.first_pageview = w.website_pageview_id
;


CREATE TEMPORARY TABLE count_pg
SELECT
	w.website_session_id,
	COUNT(DISTINCT w.pageview_url) as cnt
FROM website_pageviews w
	LEFT JOIN landing_page l
    ON l.first_pageview = w.website_pageview_id
WHERE created_at < '2012-06-14'
GROUP BY 1
;

SELECT
	COUNT(DISTINCT website_session_id) as sessions,
	SUM(CASE WHEN cnt = 1 then 1 ELSE 0 END) as bounced_sessions,
    SUM(CASE WHEN cnt = 1 then 1 ELSE 0 END)/ COUNT(DISTINCT website_session_id) as bounce_rate
FROM count_pg
;
-- Section 5.41: Analyzing Landing Page Tests
-- finding the first instance of /lander-1 to set analysis timeframe
select MIN(created_at)
FROM website_pageviews
WHERE pageview_url = '/lander-1';

SELECT *
FROM website_pageviews
WHERE created_at >= '2012-06-18 22:35:54'
	AND created_at < '2012-07-28'
;





