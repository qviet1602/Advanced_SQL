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
select 
	MIN(created_at),
	MIN(website_pageview_id)
FROM website_pageviews
WHERE pageview_url = '/lander-1'
	AND created_at IS NOT NULL;

CREATE TEMPORARY TABLE firstpage1
SELECT 
	p.website_session_id,
    MIN(p.website_pageview_id) as firstpage_id
FROM website_pageviews p
	INNER JOIN website_sessions w
    ON w.website_session_id = p.website_session_id
	AND w.created_at < '2012-07-28'
	AND p.website_pageview_id > 23504
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 1
;


CREATE TEMPORARY TABLE new_landing_page
SELECT 
	f.website_session_id,
    w.pageview_url as landing_page
FROM firstpage1 f
	LEFT JOIN website_pageviews w
    ON f.firstpage_id = w.website_pageview_id
WHERE w.pageview_url IN ( '/home', '/lander-1')
;


-- REPEAT STEP 3 above
CREATE TEMPORARY TABLE landing_cnt
SELECT
	l.website_session_id,
    l.landing_page,
    COUNT(w.pageview_url) as page_cnt
FROM new_landing_page l
	LEFT JOIN website_pageviews w
    ON l.website_session_id = w.website_session_id
GROUP BY 1,2
;

# STEP 4: Calculate bounce rate for two landing pages
SELECT
	landing_page,
    COUNT( DISTINCT website_session_id) as total_sessions,
	SUM( CASE WHEN page_cnt = 1 THEN 1 ELSE 0 END) as bounce_sessions,
    SUM( CASE WHEN page_cnt = 1 THEN 1 ELSE 0 END)/COUNT( DISTINCT website_session_id) as bounce_rate
FROM landing_cnt
GROUP BY 1;

-- Section 5.43: Landing Page Trend Analysis

CREATE TEMPORARY TABLE firstpage2
SELECT 
	p.website_session_id,
    p.created_at,
    MIN(p.website_pageview_id) as firstpage_id
FROM website_pageviews p
	INNER JOIN website_sessions w
    ON w.website_session_id = p.website_session_id
	AND w.created_at < '2012-08-31'
	AND w.created_at >= '2012-06-01'
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 1,2
;


CREATE TEMPORARY TABLE new_landing_page2
SELECT 
	f.website_session_id,
    w.pageview_url as landing_page
FROM firstpage2 f
	LEFT JOIN website_pageviews w
    ON f.firstpage_id = w.website_pageview_id
WHERE w.pageview_url IN ( '/home', '/lander-1')
;

CREATE TEMPORARY TABLE landing_cnt2
SELECT
	l.website_session_id,
    l.landing_page,
    l.created_at,
    COUNT(w.pageview_url) as page_cnt
FROM new_landing_page2 l
	LEFT JOIN website_pageviews w
    ON l.website_session_id = w.website_session_id
GROUP BY 1,2,3
;

SELECT
	MIN(DATE(created_at)) as week_start_date,
    COUNT( DISTINCT CASE WHEN landing_page = '/home' THEN website_session_id ELSE NULL END) as home_sessions,
	-- SUM( CASE WHEN page_cnt = 1 THEN 1 ELSE 0 END) as bounce_sessions,
    COUNT( DISTINCT CASE WHEN landing_page = '/lander-1' THEN website_session_id ELSE NULL END) as lander_sessions,
    SUM( CASE WHEN page_cnt = 1 THEN 1 ELSE 0 END)/COUNT( DISTINCT website_session_id) as bounce_rate
FROM landing_cnt2
GROUP BY 
	YEAR(created_at),
    WEEK(created_at)
;


-- Section 5.45: Building Conversion Funnels

-- Step 1: filter the data to gsearch only and date of interest
-- Step 2: identify each pageview as the specific funnel step
-- Step 3: calculate the clickthrough rate

-- Step 1 and 2

CREATE TEMPORARY TABLE count_pageview
SELECT
	website_session_id,
    pageview_url,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END as products,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END as mrfuzzy,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END as cart,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END as shipping,
    CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END as billing,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END as thankyou

FROM(
SELECT 
p.website_session_id, 
p.website_pageview_id,
p.created_at,
p.pageview_url
FROM website_sessions w
	LEFT JOIN website_pageviews p
	ON p.website_session_id = w.website_session_id
WHERE w.utm_source = 'gsearch'
	AND w.utm_campaign = 'nonbrand'
	AND w.created_at < '2012-09-05'
    AND w.created_at > '2012-08-05'
) AS filter_website_pageview

;

SELECT * FROM count_pageview;
-- Step 3: first way
SELECT
    SUM(products)/COUNT(website_session_id) as lander_clickthry_rt,
    SUM(mrfuzzy)/SUM(products) as product_clickthru_rt,
    SUM(cart)/SUM(mrfuzzy) as mrfuzzy_clickthru_rt,
    SUM(shipping)/SUM(cart) as cart_clickthru_rt,
    SUM(billing)/ SUM(shipping) as shipping_clickthru_rt,
    SUM(thankyou)/SUM(billing) as billing_clickthru_rt
FROM (
SELECT
	website_session_id,
    MAX(products) as products,
    MAX(mrfuzzy) as mrfuzzy,
    MAX(cart) as cart,
    MAX(shipping) as shipping,
    MAX(billing) as billing,
    MAX(thankyou) as thankyou

FROM count_pageview
GROUP BY website_session_id

) as temp_table
;
-- Step3: second way
SELECT
    COUNT(DISTINCT CASE WHEN products = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) as lander__clickthry_rt,
    COUNT(DISTINCT CASE WHEN mrfuzzy= 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN products = 1 THEN website_session_id ELSE NULL END) as products_clickthry_rt,
    COUNT(DISTINCT CASE WHEN cart = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN mrfuzzy= 1 THEN website_session_id ELSE NULL END) as mrfuzzy__clickthry_rt,
    COUNT(DISTINCT CASE WHEN shipping = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN cart = 1 THEN website_session_id ELSE NULL END) as cart__clickthry_rt,
    COUNT(DISTINCT CASE WHEN billing = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN shipping = 1 THEN website_session_id ELSE NULL END) as shipping_clickthry_rt,
    COUNT(DISTINCT CASE WHEN thankyou = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN billing = 1 THEN website_session_id ELSE NULL END) as billing__clickthry_rt
FROM (
SELECT
	website_session_id,
    MAX(products) as products,
    MAX(mrfuzzy) as mrfuzzy,
    MAX(cart) as cart,
    MAX(shipping) as shipping,
    MAX(billing) as billing,
    MAX(thankyou) as thankyou

FROM count_pageview
GROUP BY website_session_id

) as temp_table2
;


-- Section 5.48: Analyzing Conversion Funnel Tests
-- Step 1: Filter to desired date and utm_source, campaign
-- Step 2: Filter to desired pageview
-- Step 3: Calculate clickthrough rate
-- Step 1
SELECT
	MIN(website_pageview_id),
	MIN(DATE(created_at))
    
FROM website_pageviews
WHERE pageview_url = '/billing-2'
;

-- Earliest pageview_id for billing-2 is 53550
SELECT 
	pageview_url,
	COUNT(distinct website_session_id) as sessions,
	SUM(thankyou) as orders,
	SUM(thankyou)  / COUNT(distinct website_session_id) as billing_ratio
FROM(
SELECT 
	p.website_session_id, 
	p.website_pageview_id,
	p.created_at,
	p.pageview_url,
    CASE WHEN w.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END as thankyou
FROM website_pageviews w
	JOIN website_pageviews p
	ON p.website_session_id = w.website_session_id
WHERE p.created_at < '2012-11-10'
    AND p.website_pageview_id >= 53550
    AND p.pageview_url IN ('/billing','/billing-2')
) as temp_table3
GROUP BY pageview_url
;


SELECT 
	p.website_session_id, 
	p.website_pageview_id,
	p.created_at,
	p.pageview_url,
    w.pageview_url,
    CASE WHEN w.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END as thankyou
FROM website_pageviews w
	JOIN website_pageviews p
	ON p.website_session_id = w.website_session_id
WHERE p.created_at < '2012-11-10'
    AND p.website_pageview_id >= 53550
    AND p.pageview_url IN ('/billing','/billing-2')
;
