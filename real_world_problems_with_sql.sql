--

WITH productdescriptivestats AS (
    SELECT
        p.productname,
        EXTRACT(month FROM orderdate) AS ordermonth,
        SUM(revenue) AS total_monthly_revenue
    FROM
        subscriptions s JOIN products p ON s.productid = p.productid
    WHERE
        EXTRACT(year FROM orderdate) = '2022'
    GROUP BY
        p.productname, EXTRACT(month FROM orderdate)
    ORDER BY
        p.productname, ordermonth
)

SELECT
    productname,
    MIN(total_monthly_revenue) AS min_rev,
    MAX(total_monthly_revenue) AS max_rev,
    AVG(total_monthly_revenue) AS avg_rev,
    STDDEV(total_monthly_revenue) AS std_dev_rev
FROM
    productdescriptivestats
GROUP BY
    productname;
   
--
  
 WITH eventclicks AS (
    SELECT
        COUNT(*) AS num_link_clicks
    FROM
        users u JOIN frontendeventlog fe ON u.userid = fe.userid
    WHERE
        eventid = 5
    GROUP BY
        u.userid
)

SELECT
    num_link_clicks,
    COUNT(num_link_clicks) AS num_users
FROM
    eventclicks
GROUP BY
    num_link_clicks;
    
--

WITH maxstatus AS (
	SELECT
		s.subscriptionid,
		MAX(statusid) AS maxstatus
	FROM
		subscriptions s LEFT JOIN paymentstatuslog ps ON s.subscriptionid = ps.subscriptionid
	GROUP BY
		s.subscriptionid
), paymentfunnelstages AS (
	SELECT
		s.subscriptionid,
		maxstatus,
		currentstatus,
		CASE
		WHEN maxstatus IS NULL THEN 'User did not start payment process'
		WHEN maxstatus = 1 THEN 'PaymentWidgetOpened'
		WHEN maxstatus = 2 THEN 'PaymentEntered'
		WHEN maxstatus = 3 AND currentstatus = 0 THEN 'User Error with Payment Submission'
		WHEN maxstatus = 3 AND currentstatus != 0 THEN 'Payment Submitted'
		WHEN maxstatus = 4 AND currentstatus = 0 THEN 'Payment Processing Error with Vendor'
		WHEN maxstatus = 4 AND currentstatus != 0 THEN 'Payment Success'
		WHEN maxstatus = 5 THEN 'Complete'
		END AS paymentfunnelstage
	FROM
		subscriptions s JOIN maxstatus ms ON s.subscriptionid = ms.subscriptionid
)

SELECT
	paymentfunnelstage,
	COUNT(subscriptionid) AS subscriptions
FROM
	paymentfunnelstages
GROUP BY
	paymentfunnelstage;
	
--

SELECT
    customerid,
    COUNT(productid) AS num_products,
    SUM(numberofusers) AS total_users,
    CASE
    WHEN COUNT(productid) = 1 OR SUM(numberofusers) >= 5000 THEN 1
    ELSE 0
    END AS upsell_opportunity
FROM
    subscriptions
GROUP BY
    customerid;
    
--
   
SELECT
    userid,
    SUM(CASE WHEN fel.eventid = 1 THEN 1 ELSE 0 END) AS viewedhelpcenterpage,
    SUM(CASE WHEN fel.eventid = 2 THEN 1 ELSE 0 END) AS clickedfaqs,
    SUM(CASE WHEN fel.eventid = 3 THEN 1 ELSE 0 END) AS clickedcontactsupport,
    SUM(CASE WHEN fel.eventid = 4 THEN 1 ELSE 0 END) AS submittedticket
FROM
    frontendeventlog fel JOIN frontendeventdefinitions fed ON fel.eventid = fed.eventid
WHERE
    eventtype = 'Customer Support'
GROUP BY
    userid;
    
--
   
WITH allsubscriptions AS (
	SELECT
		subscriptionid,
		customerid,
		active,
		expirationdate
	FROM
		subscriptionsproduct1
	WHERE
		active = 1
		
	UNION ALL

	SELECT
		subscriptionid,
		customerid,
		active,
		expirationdate
	FROM
		subscriptionsproduct2
	WHERE
		active = 1
)

SELECT
	DATE_TRUNC('year', expirationdate) AS exp_year,
	COUNT(subscriptionid) AS subscriptions
FROM
	allsubscriptions
GROUP BY
	DATE_TRUNC('year', expirationdate);
	
--

WITH allcancelationreasons AS (
    SELECT
        subscriptionid,
        cancelationreason1 as cancelationreason
    FROM
        cancelations
    UNION ALL
    SELECT
        subscriptionid,
        cancelationreason2 as cancelationreason
    FROM
        cancelations
    UNION ALL
    SELECT
        subscriptionid,
        cancelationreason3 as cancelationreason
    FROM
        cancelations
)

SELECT 
    CAST(SUM(CASE WHEN cancelationreason = 'Expensive' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(DISTINCT subscriptionid) AS percent_expensive
FROM
    allcancelationreasons;
    
--
   
SELECT
    e.employeeid AS employeeid,
    e.name AS employee_name,
    m.name AS manager_name,
    CASE
    WHEN m.email IS NOT NULL THEN m.email
    ELSE e.email 
    END AS contact_email 
FROM
    employees e LEFT JOIN employees m ON e.managerid = m.employeeid
WHERE
    e.department = 'Sales';
    
--
   
WITH monthlyrevenue AS (
    SELECT
        DATE_TRUNC('month', orderdate) AS ordermonth,
        SUM(revenue) AS total_monthly_revenue
    FROM
        subscriptions
    GROUP BY
        DATE_TRUNC('month', orderdate)
)

SELECT
    c.ordermonth AS current_month,
    p.ordermonth AS previous_month,
    c.total_monthly_revenue AS current_revenue,
    p.total_monthly_revenue AS previous_revenue
FROM
    monthlyrevenue c JOIN monthlyrevenue p ON 
    c.total_monthly_revenue > p.total_monthly_revenue AND 
    c.ordermonth - p.ordermonth = '30';
    
--
   
SELECT
    salesemployeeid,
    saledate,
    saleamount,
    SUM(saleamount) OVER (PARTITION BY salesemployeeid ORDER BY saledate) AS running_total,
    CAST(SUM(saleamount) OVER (PARTITION BY salesemployeeid ORDER BY saledate) AS FLOAT) / quota AS percent_quota
FROM
    sales s JOIN employees e ON s.salesemployeeid = e.employeeid
ORDER BY
    salesemployeeid, saledate;
    
--
   
SELECT
    statusmovementid,
    subscriptionid,
    statusid,
    movementdate,
    LEAD(movementdate, 1) OVER (ORDER BY movementdate) AS nextstatusmovementdate,
    LEAD(movementdate, 1) OVER (ORDER BY movementdate) - movementdate AS timeinstatus
FROM
    paymentstatuslog
WHERE
    subscriptionid = '38844';