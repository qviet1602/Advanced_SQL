USE mavenfuzzyfactory;

SELECT *
FROM website_sessions;

SELECT *
FROM orders;

-- Section 4.21: Find Top Traffic Sources
SELECT utm_source, utm_campaign, http_referer, COUNT(DISTINCT website_session_id) as sessions 
FROM website_sessions
WHERE created_at < '2012-04-12'
GROUP BY utm_source, utm_campaign, http_referer
ORDER BY sessions DESC;

-- Section 4.23: Traffic Source Conversion Rate
SELECT 
	COUNT(DISTINCT w.website_session_id) as sessions ,
	COUNT(DISTINCT o.order_id) as orders,
	COUNT(DISTINCT o.order_id) /COUNT(DISTINCT w.website_session_id) as CVR
FROM website_sessions w
	LEFT JOIN  orders o 
    ON w.website_session_id = o.website_session_id
WHERE w.created_at < '2012-04-14'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
;

-- Section 4.26: Traffic Source Trending
SELECT
	YEAR(created_at),
    WEEK(created_at),
	MIN( DATE(created_at)) as week_start_date,
	COUNT( DISTINCT website_session_id) as sessions
FROM website_sessions
WHERE created_at < '2012-05-10'
	AND utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
GROUP BY 1,2;

-- Section 4.28: Bid Optimization for Paid Traffic

SELECT
	w.device_type,
	COUNT(DISTINCT w.website_session_id) as sessions,
    COUNT(DISTINCT o.order_id) as orders,
    COUNT(DISTINCT o.order_id)/COUNT(DISTINCT w.website_session_id) as CVR
FROM website_sessions w
	LEFT JOIN orders o
    ON w.website_session_id = o.website_session_id
WHERE w.created_at < '2012-05-11'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY w.device_type;

-- Section 4.30: Trending with Granular Segments
SELECT
    MIN(DATE(created_at)) as week_start_date,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN 1 ELSE NULL END) as desktop_sessions ,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN 1 ELSE NULL END) as mobile_sessions
    
FROM website_sessions
WHERE created_at BETWEEN '2012-04-15' AND '2012-06-09'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 
	YEAR(created_at),
    WEEK(created_at)
;


















