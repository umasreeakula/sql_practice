--

SELECT 
    Date, 
    PartySize,
    SUM(PartySize) OVER (ORDER BY Date) AS Total
FROM
    Reservations
WHERE
    EXTRACT(year FROM DATE) = '2022';
    
--
   
SELECT
    EmployeeID,
    Department,
    Position,
    WeeklyPay,
    SUM(WeeklyPay) OVER (PARTITION BY Department) AS DeptTotal
FROM
    Employees
ORDER BY
    Department, WeeklyPay;
    
--
   
SELECT
    Firstname,
    LastName,
    WeeklyPay,
    Department,
    DENSE_RANK() OVER (PARTITION BY Department ORDER BY WeeklyPay DESC) AS DeptRank
FROM
    Employees
ORDER BY
    Department, DeptRank;
    
--
   
SELECT
    O.OrderID,
    SUM(Price) AS ThisOrderPrice,
    SUM(Price) - LAG(SUM(Price), 1) OVER (ORDER BY O.OrderID) AS DiffFromPrev
FROM
    (Orders O JOIN OrdersDishes OD ON O.Orderid = OD.OrderID)
    JOIN Dishes D ON OD.DishID = D.DishID
WHERE
    EXTRACT(year FROM OrderDate) = '2022'
GROUP BY
    O.OrderID;
    
--
   
SELECT
    CustomerID,
    O.OrderID,
    SUM(Price) AS OrderTotal,
    ROUND(AVG(SUM(Price)) OVER (PARTITION BY CustomerID ORDER BY O.OrderID ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS MovingAvg
FROM
    (Orders O JOIN OrdersDishes OD ON O.OrderID = OD.OrderID)
    JOIN Dishes D ON OD.DishID = D.DishID
GROUP BY
    CustomerID, O.OrderID;