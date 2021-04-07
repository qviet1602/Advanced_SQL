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
FROM 
	entry_page_table e
	LEFT JOIN website_pageviews w
    ON e.first_pv = w.website_pageview_id
GROUP BY 1
ORDER BY 2 DESC;

-- Section 5.39: Calculating Bounce Rate
-- STEP 1: find the first website_pageview_id for relevant session
CREATE TEMPORARY TABLE first_pageview
SELECT 
	website_session_id,
	MIN(website_pageview_id) as first_pageview
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY 1;
SELECT * from first_pageview;

-- STEP 2: identify the landing page url of each session
CREATE TEMPORARY TABLE sessions_w_home_landing_page
SELECT
	w.website_session_id,
	w.pageview_url as landing_page
FROM first_pageview f
	LEFT JOIN website_pageviews w
    ON f.first_pageview = w.website_pageview_id
WHERE w.pageview_url = '/home'
;

-- STEP 3: counting pageviews for each session, to identify bounces

CREATE TEMPORARY TABLE pageview_cnt
SELECT
	w.website_session_id,
	COUNT(DISTINCT w.pageview_url) as pageview_cnt
FROM sessions_w_home_landing_page l
	LEFT JOIN website_pageviews w
    ON l.website_session_id = w.website_session_id
GROUP BY 1
;
-- STEP 4: summarizing total sessions and bounce sessions, by LP
SELECT
	COUNT(DISTINCT website_session_id) as sessions,
	SUM(CASE WHEN pageview_cnt = 1 then 1 ELSE 0 END) as bounced_sessions,
    SUM(CASE WHEN pageview_cnt = 1 then 1 ELSE 0 END)/ COUNT(DISTINCT website_session_id) as bounce_rate
FROM pageview_cnt
;
-- Section 5.41: Analyzing Landing Page Tests
-- finding the first instance of /lander-1 to set analysis timeframe
select MIN(created_at)
FROM website_pageviews
WHERE pageview_url = '/lander-1';

-- Repeat step 1,2 above but now we have 2 landing pages
CREATE TEMPORARY TABLE firstpage
SELECT 
	website_session_id,
    MIN(website_pageview_id) as firstpage_id
FROM website_pageviews
WHERE created_at >= '2012-06-18 22:35:54'
	AND created_at < '2012-07-28'
GROUP BY 1
;
CREATE TEMPORARY TABLE home_landing_page
SELECT 
	f.website_session_id,
    w.pageview_url as landing_page
FROM firstpage f
	LEFT JOIN website_pageviews w
    ON f.firstpage_id = w.website_pageview_id
WHERE w.pageview_url = '/home'
;
CREATE TEMPORARY TABLE lander1_landing_page
SELECT 
	f.website_session_id,
    w.pageview_url as landing_page
FROM firstpage f
	LEFT JOIN website_pageviews w
    ON f.firstpage_id = w.website_pageview_id
WHERE w.pageview_url = '/lander-1'
;

-- REPEAT STEP 3 above
CREATE TEMPORARY TABLE lander1_cnt
SELECT
	l.website_session_id,
    l.landing_page,
    COUNT(w.pageview_url) as page_cnt
FROM lander1_landing_page l
	LEFT JOIN website_pageviews w
    ON l.website_session_id = w.website_session_id
GROUP BY 1,2
;

CREATE TEMPORARY TABLE home_cnt
SELECT 	
	h.website_session_id,
    h.landing_page,
    COUNT(w.pageview_url) as page_cnt
FROM home_landing_page h
	LEFT JOIN website_pageviews w
    ON h.website_session_id = w.website_session_id
GROUP BY 1,2
;
# STEP 4: Calculate bounce rate for two landing pages
SELECT
    COUNT( DISTINCT website_session_id) as total_sessions,
	SUM( CASE WHEN page_cnt = 1 THEN 1 ELSE 0 END) as bounce_sessions,
    SUM( CASE WHEN page_cnt = 1 THEN 1 ELSE 0 END)/COUNT( DISTINCT website_session_id) as bounce_rate
FROM home_cnt
UNION
SELECT
    COUNT( DISTINCT website_session_id) as total_sessions,
	SUM( CASE WHEN page_cnt = 1 THEN 1 ELSE 0 END) as bounce_sessions,
    SUM( CASE WHEN page_cnt = 1 THEN 1 ELSE 0 END)/COUNT( DISTINCT website_session_id) as bounce_rate
FROM lander1_cnt;
