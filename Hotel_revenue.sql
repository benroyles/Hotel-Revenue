# Combining the yearly information into 1 table
CREATE TABLE combined as (
SELECT * FROM t2018
UNION
SELECT * FROM t2019
UNION 
SELECT * FROM t2020);

SELECT *
FROM combined;

SELECT *
FROM market_segment;
	
    ### Having two columns with the same name may cause issues later so i will rename the column in the market segment table
 
 ALTER TABLE market_segment
 RENAME COLUMN market_segment TO segment;


SELECT *
FROM meal_cost;

# Is Revenue increasing each year?
SELECT  hotel, arrival_date_year, ROUND(SUM((stays_in_week_nights+stays_in_weekend_nights)*adr)) AS YearRevenue
FROM combined
GROUP BY  hotel, arrival_date_year
ORDER BY hotel;

		### yearly revenue increased between 2018 and 2019 but dropped between 2019 and 2020, this is likely due to incomplete data for 2020

SELECT  hotel, arrival_date_month,  arrival_date_year,  ROUND(SUM((stays_in_week_nights+stays_in_weekend_nights)*adr)) AS MonthRevenue
FROM combined
GROUP BY  hotel, arrival_date_year, arrival_date_month
ORDER BY hotel, arrival_date_month;
		
        ### Only July and August have data for all three years, 2019 appears to be complete but 2018 and 2020 are both missing certain months

SELECT  hotel, arrival_date_year, ROUND(SUM((stays_in_week_nights+stays_in_weekend_nights)*adr)) AS YearRevenue
FROM combined
WHERE arrival_date_month = 'July' OR arrival_date_month = 'August'
GROUP BY  hotel, arrival_date_year
ORDER BY hotel;

		### Yearly revenue does appear to be increasing for city hotel but has actually decreased for Resort hotel betwen 2019 and 2020

SELECT  hotel, arrival_date_year, arrival_date_month, ROUND(SUM((stays_in_week_nights+stays_in_weekend_nights)*adr)) AS YearRevenue
FROM combined
WHERE arrival_date_month = 'July' OR arrival_date_month = 'August'
GROUP BY  hotel, arrival_date_year, arrival_date_month
ORDER BY hotel, arrival_date_month;


# Which month is the busiest?

SELECT arrival_date_month, SUM(stays_in_week_nights+stays_in_weekend_nights) AS NumberOfStays
FROM combined
GROUP BY arrival_date_month
ORDER BY NumberOfStays DESC;

# Which month generates the most revenue?

SELECT arrival_date_month, ROUND(SUM((stays_in_week_nights+stays_in_weekend_nights)*adr)) AS MonthlyRevenue
FROM combined
GROUP BY arrival_date_month
ORDER BY MonthlyRevenue DESC;

# How long do people typically stay for?

SELECT ROUND(AVG(stays_in_week_nights+stays_in_weekend_nights)) AS avgNumOfNights
FROM combined;

		# does it vary trough the year?
SELECT arrival_date_month ,ROUND(AVG(stays_in_week_nights+stays_in_weekend_nights)) AS avgNumOfNights
FROM combined
GROUP BY  arrival_date_month
ORDER BY avgNumOfNights DESC;

# How far in advanced do people book their stay?

SELECT MIN(lead_time)/7 as minBookingTime, ROUND(max(lead_time)/7) as maxBookingTimeInWeeks, ROUND(AVG(lead_time)/7) as avgBookingTimeInweeks
FROM combined;

# How much do the ADR rates change throughout the year?

SELECT arrival_date_year, arrival_date_month, MIN(adr) as minADR, MAX(adr) as maxADR, AVG(adr), MAX(adr)-MIN(adr) as DifferenceInADR
FROM combined
group by arrival_date_year, arrival_date_month;

		## Each month has a minimum ADR of 0 which does not seem correct

SELECT *
FROM combined
WHERE adr = 0;

		### grouping by day
SELECT hotel, arrival_date_year, arrival_date_month, arrival_date_day_of_month, MIN(adr) as minADR, MAX(adr) as maxADR, AVG(adr), MAX(adr)-MIN(adr) as DifferenceInADR
FROM combined
group by hotel, arrival_date_year, arrival_date_month, arrival_date_day_of_month;

SELECT hotel, arrival_date_year,  COUNT(adr)
FROM combined
WHERE adr=0
group by hotel, arrival_date_year;
		
        ### There are a lot of days with an ADR of 0, this doesn't seem correct but as I do not have access to the original data source or contact with the owner of the data it is unclear why this is occuring

# What percentage of clients need a parking space?

SELECT (SUM(required_car_parking_spaces)/COUNT(required_car_parking_spaces))*100 as PercentageOfCustomerParking
FROM combined;

# What room type is the most popular?

SELECT hotel, reserved_room_type, COUNT(reserved_room_type) as ReservedRoomType, COUNT(assigned_room_type) as AssignedRoomType, COUNT(reserved_room_type)-COUNT(assigned_room_type) as DifferentFromBooking
FROM combined
GROUP BY hotel, reserved_room_type
ORDER BY ReservedRoomType DESC;

# What is the most common way customers book?

SELECT hotel, market_segment, COUNT(market_segment) as NumberOfBookings
FROM combined
GROUP BY hotel, market_segment
ORDER BY NumberOfBookings DESC;

# How much money was "lost" through discounts?

SELECT discount.hotel, discount.arrival_date_year, ROUND(SUM(adr)) AS TotalRevenue, ROUND(SUM((adr*discount.Discount))) AS TotalDiscounts, ROUND((SUM((adr*discount.Discount))/SUM(adr))*100) AS PCTofDiscount
FROM	
    (SELECT *
	FROM combined
	INNER JOIN market_segment ON combined.market_segment = market_segment.segment) AS discount
GROUP BY discount.hotel, discount.arrival_date_year
ORDER BY PCTofDiscount DESC;

# How much was the total food cost each month?
		### Assuming that cost is per adult/per night.

SELECT costs.hotel, costs.arrival_date_year, ROUND(SUM(costs.Nights*costs.adults*costs.cost)) AS FoodCost
FROM 
    (SELECT combined.hotel, combined.arrival_date_year, combined.stays_in_week_nights+combined.stays_in_weekend_nights as Nights, combined.adults, combined.meal, meal_cost.cost
	FROM combined
	JOIN meal_cost ON combined.meal = meal_cost.meal) AS costs
GROUP BY costs.hotel, costs.arrival_date_year
ORDER BY costs.hotel;


