------city dataset--------------------
SELECT TOP (1000) [city_id]
      ,[city_name]
      ,[country]
      ,[continent]
      ,[population]
      ,[regulatory_status]
      ,[market_competition]
      ,[number_of_drivers]
      ,[number_of_rides]
      ,[avg_fare]
      ,[avg_wait_time_min]
      ,[uber_services]
      ,[major_competitors]
  FROM [siri1].[dbo].[city_dataset2$]
-------driver dataset---------------------
  SELECT TOP (1000) [driver_id]
      ,[driver_name]
      ,[age]
      ,[gender]
      ,[city_id]
      ,[vehicle_type]
      ,[avg_driver_rating]
      ,[total_rides]
      ,[total_earnings]
      ,[driver_status]
      ,[employment_type]
      ,[years_of_experience]
      ,[ride_acceptance_rate]
  FROM [siri1].[dbo].['driver_dataset3 (2)$']
  -----------payment dataset-------------
  SELECT TOP (1000) [payment_id]
      ,[ride_id]
      ,[driver_id]
      ,[passenger_id]
      ,[fare]
      ,[surge_multiplier]
      ,[payment_method]
      ,[driver_earnings]
      ,[uber_commission]
      ,[transaction_status]
      ,[payment_date]
  FROM [siri1].[dbo].['payment_dataset 4 (1)$']
  ----------------riders dataset-------------------------
  SELECT TOP (1000) [ride_id]
      ,[start_city]
      ,[end_city]
      ,[ride_date]
      ,[start_time]
      ,[end_time]
      ,[distance_km]
      ,[fare]
      ,[dynamic_pricing]
      ,[driver_id]
      ,[passenger_id]
      ,[rating]
      ,[payment_method]
      ,[ride_status]
  FROM [siri1].[dbo].['rides_dataset1 (1)$']
  
  -----1st query---------------
  SELECT TOP 3 
  c.city_name, 
  c.population, 
  c.number_of_drivers, 
  c.avg_fare, 
  r.rating
FROM 
   [siri1].[dbo].[city_dataset2$] c
  LEFT JOIN [siri1].[dbo].['rides_dataset1 (1)$'] r ON c.city_id = r.start_city
GROUP BY 
  c.city_name, 
  c.population, 
  c.number_of_drivers, 
  c.avg_fare, 
  r.rating
ORDER BY 
  c.number_of_drivers DESC, 
  c.avg_fare DESC, 
  r.rating DESC;


  ------2nd query-----------------
  select r.ride_id, r.ride_status from [siri1].[dbo].['rides_dataset1 (1)$'] as r
  left join [siri1].[dbo].['payment_dataset 4 (1)$'] as p on r.ride_id=p.ride_id
  where r.ride_status='completed' and p.payment_id is null

 --------------3rd query-----------------
  SELECT 
  c.city_name, 
  SUM(p.driver_earnings) AS revenue
FROM 
  [siri1].[dbo].['payment_dataset 4 (1)$'] p
  JOIN  [siri1].[dbo].['rides_dataset1 (1)$'] r ON p.ride_id = r.ride_id
  JOIN [siri1].[dbo].[city_dataset2$] c ON r.start_city = c.city_id
WHERE 
  r.ride_status = 'completed'
GROUP BY 
  c.city_name
ORDER BY 
  revenue DESC;
  ----------------4th query------------
  ---cancellation rate by hour of day
 SELECT 
  datepart(hour,(r.start_time))AS hour_of_day, 
  COUNT(r.ride_id) AS total_rides, 
  SUM(CASE WHEN r.ride_status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_rides, 
  (SUM(CASE WHEN r.ride_status = 'cancelled' THEN 1 ELSE 0 END) * 1.0 / COUNT(r.ride_id)) AS cancellation_rate
FROM 
    [siri1].[dbo].['rides_dataset1 (1)$'] as r
GROUP BY 
  datepart(HOUR,(r.start_time))
ORDER BY 
  cancellation_rate DESC;
  ------revenue impact-------------------
  SELECT 
  datepart(HOUR,(r.start_time)) AS hour_of_day, 
  SUM(p.driver_earnings) AS revenue, 
  SUM(CASE WHEN r.ride_status = 'cancelled' THEN p.driver_earnings ELSE 0 END) AS lost_revenue
FROM 
   [siri1].[dbo].['payment_dataset 4 (1)$'] as p
  JOIN [siri1].[dbo].['rides_dataset1 (1)$'] as r ON p.ride_id = r.ride_id
GROUP BY 
  datepart(hour,r.start_time)
ORDER BY 
  lost_revenue DESC;
  -------------------------5th query-----------------------------
  ----------------------significant trends in fare distribution-------------------
 
SELECT datepart(month,fare) AS month,fare FROM [siri1].[dbo].['payment_dataset 4 (1)$']


SELECT 
      CASE 
        WHEN datepart(month,fare) IN (12, 1, 2) THEN 'Winter'
        WHEN datepart(month,fare) IN (3, 4, 5) THEN 'Spring'
        WHEN datepart(month,fare) IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
      END AS season,
      fare
    FROM 
      [siri1].[dbo].['payment_dataset 4 (1)$']

-----------------6th query------------------
---------------average ride duration---------------------
select 
start_city,avg(datediff(MINUTE,start_time,end_time)) as 
avg_ride_duration,avg(rating) as 
avg_customer_satisfaction from  [siri1].[dbo].['rides_dataset1 (1)$']
group by start_city
order by start_city

----customer satisfaction------------
 select corr(avg_ride_duration,avg_customer_satisfaction)
from
(select 
start_city,avg(datediff(MINUTE,start_time,end_time)) as 
avg_ride_duration,avg(rating) as 
avg_customer_satisfaction from  [siri1].[dbo].['rides_dataset1 (1)$']
group by start_city) as subquery

----------7th query----------------
CREATE INDEX idx_ride_date ON [siri1].[dbo].['rides_dataset1 (1)$'] (ride_date)
select * from [siri1].[dbo].['rides_dataset1 (1)$'] 
where ride_id>'2024-03-05' and ride_date<='2022-04-05'
---------------8th query------------------------
create view  vw_avg_fare as
select start_city,avg(fare) as avg_fare from  [siri1].[dbo].['rides_dataset1 (1)$'] 
group by start_city
 
 select * from vw_avg_fare

-----------9th query-------------
CREATE TABLE RideStatusAudit (
  AuditID INT IDENTITY(1,1) PRIMARY KEY,
  RideID INT,
  OldStatus VARCHAR(50),
  NewStatus VARCHAR(50),
  ChangedBy VARCHAR(50),
  ChangedDate DATETIME
)


CREATE TRIGGER trg_RideStatusChangeLogging
ON [siri1].[dbo].['rides_dataset1 (1)$']
AFTER UPDATE
AS
BEGIN
  IF UPDATE(ride_status)
  BEGIN
    INSERT INTO RideStatusAudit (RideID, OldStatus, NewStatus, ChangedBy, ChangedDate)
    SELECT i.RideID, d.ride_status, i.ride_status, SUSER_NAME(), GETDATE()
    FROM inserted i
    INNER JOIN deleted d ON i.RideID = d.RideID
  END
END
---------------10th query------------------------
CREATE VIEW ViewForDriverPerformanceMetrics AS
SELECT 
  driver_id,
  AVG(datediff(second,start_time,end_time)) AS avg_ride_completion_time,
  AVG(distance_km) AS avg_distance_per_ride,
  AVG(fare) AS avg_fare_per_ride,
  SUM(CASE WHEN ride_status = 'accepted' THEN 1 ELSE 0 END) AS ride_acceptance_rate,
  SUM(CASE WHEN ride_status = 'cancelled' THEN 1 ELSE 0 END)AS ride_cancellation_rate,
  AVG(rating) AS avg_rating,
  SUM(CASE WHEN start_time <= end_time THEN 1 ELSE 0 END) AS on_time_arrival_rate
FROM 
  [siri1].[dbo].['rides_dataset1 (1)$']
GROUP BY 
  driver_id
select * from ViewForDriverPerformanceMetrics

-------------------11 th query-------------------
CREATE INDEX idx_payment_method1 
ON [siri1].[dbo].['rides_dataset1 (1)$'] (payment_method)

select * from [siri1].[dbo].['rides_dataset1 (1)$']
where payment_method='cash' 





   
