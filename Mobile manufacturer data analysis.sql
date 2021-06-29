use db_SQLCaseStudies
select * from DIM_Customer 
select * from DIM_DATE 
select * from DIM_Location 
select * from DIM_MODEL 
select * from DIM_MANUFACTURER
select * from FACT_TRANSACTIONS 

--Q1. List all the states in which we have customers who have bought cell phones from 2005 till today
SELECT DISTINCT T1.State FROM DIM_LOCATION as T1
inner join FACT_TRANSACTIONS as T2 on  T1.IDLocation = T2.IDLocation 
WHERE year(T2.Date) between 2005 and getdate()

--Q2: What state in the US is buying more 'Samsung' cell phones?
select top 1 T1.State from DIM_Location as T1
inner join Fact_transactions as T2 on T1.IDLocation = T2.IdLocation 
inner join DIM_Model as T3 on T2.IDModel = T3.IDModel  
inner join DIM_MANUFACTURER as T4 on T3.IDManufacturer = T4.IDManufacturer 
where T1.Country = 'US' and T4.Manufacturer_Name='Samsung'
group by T1.State, T3.Model_Name,T4.Manufacturer_Name
order by count(T2.Quantity) desc

--Q3: Show the number of transactions for each model per zip code per state. 
select T3.IDModel,T3.Model_Name,Zipcode,state,count(T3.IDModel)as Number_of_Transactions from DIM_LOCATION as T1 
inner join FACT_TRANSACTIONS as T2 on T1.IDLocation = T2.IDLocation 
inner join DIM_Model as T3 on T2.IDModel = T3.IDModel
group by T3.Model_name,T3.IDModel,T1.ZipCode,T1.State

--Q4: Show the cheapest Phone
select top 1  min(T2.TotalPrice) as Cheapest_Price,T3.Manufacturer_Name as Cheapest_Phone from DIM_MODEL as T1
inner join FACT_TRANSACTIONS as T2 on T1.IDModel=T2.IDModel
inner join DIM_MANUFACTURER as T3 on T1.IDManufacturer = T3.IDManufacturer
group by T1.Model_Name, T3.Manufacturer_Name
order by min(T2.TotalPrice)

--Q5: Find out the average price for each model in top5 manufacturers in terms of sales quantity and order by average price
select  T1.Model_name,count(T2.Quantity) as Max_QTY,T3.Manufacturer_Name,avg(T2.TotalPrice)as Avg_Price from DIM_MODEL as T1
inner join FACT_TRANSACTIONS as T2 on T1.IDModel=T2.IDModel
inner join DIM_MANUFACTURER as T3 on T1.IDManufacturer = T3.IDManufacturer
group by T1.Model_Name,T3.Manufacturer_Name 
order by avg(T2.TotalPrice) desc 

--Q6: List the names of the customers and the average amount spent in 2009, where the average is higher than 500.
select T1.Customer_Name, avg(T2.TotalPrice) as Avg_Price from DIM_CUSTOMER as T1
inner join FACT_TRANSACTIONS as T2 on T1.IDCustomer=T2.IDCustomer where year(T2.Date)='2009' 
group by T1.Customer_Name 
having avg(T2.TotalPrice)>500
order by avg(T2.TotalPrice) desc 

--Q7: List if there is any model that was in the top 5 quantity, simultaneaously in 2008,2009,2010.
select top 5 T1.Model_name, count(T2.Quantity) as CNT_QTY ,year(T2.Date) as Year from DIM_MODEL as T1
inner join FACT_TRANSACTIONS as T2 on T1.IDModel = T2.IDModel
where year(T2.Date) between '2008' and '2010'
group by T1.Model_Name,year(T2.Date) 
order by count(T2.Quantity) desc

--Q8: Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.
select X.Manufacturer_name as Manufacturer_name_09,Y.Manufacturer_name as Manufacturer_name_10
 from 
    (
            SELECT Manufacturer_name,row_number() over(order by SUM (TotalPrice)) as rn1
            FROM Fact_Transactions FT
            LEFT JOIN DIM_Model DM ON FT.IDModel = DM.IDModel
            LEFT JOIN DIM_MANUFACTURER MFC  ON MFC.IDManufacturer = DM.IDManufacturer
            Where DATEPART(Year,date)=2009
            group by Manufacturer_name 

    )X inner join
    (

        SELECT Manufacturer_name,row_number() over(order by SUM (TotalPrice)) as rn2
            FROM Fact_Transactions FT
            LEFT JOIN DIM_Model DM ON FT.IDModel = DM.IDModel
            LEFT JOIN DIM_MANUFACTURER MFC  ON MFC.IDManufacturer = DM.IDManufacturer
            Where DATEPART(Year,date)=2010 
            group by Manufacturer_name 

    )Y on X.rn1=Y.rn2  and rn1 in (1,2) and rn2 in (1,2) 

--Q9: Show the manufacturers that sold cellphone in 2010 but didn't in 2009.
select  distinct(t1.IDManufacturer),t3.Manufacturer_Name from  DIM_MANUFACTURER as T3 
inner join DIM_MODEL as T1 on T1.IDManufacturer = T3.IDManufacturer 
inner join FACT_TRANSACTIONS as T2 on T1.IDModel=T2.IDModel
where year(T2.Date) = '2010'  except
(select distinct(t1.IDManufacturer),t3.Manufacturer_Name from DIM_MANUFACTURER as T3 
inner join dim_model t1 on T1.IDManufacturer = T3.IDManufacturer
inner join FACT_TRANSACTIONS as T2 on T1.IDModel=T2.IDModel 
where year(T2.Date) = '2009' );

--Q10: Find the top 100 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend.
select top 100 T1.Customer_Name, avg(T2.TotalPrice)as Avg_Spend,avg(T2.Quantity) as Avg_Qty, year(T2.Date) as Year, 
- 100* (1 - LEAD(avg(T2.TotalPrice)) OVER (ORDER BY T1.IDCustomer) / avg(T2.TotalPrice)) AS Per_diff
from DIM_CUSTOMER as T1
inner join FACT_TRANSACTIONS as T2 on T1.IDCustomer = T2.IDCustomer
group by T1.Customer_Name,year(T2.Date),T2.TotalPrice,T1.IDCustomer
order by avg(T2.TotalPrice)desc ,avg(T2.Quantity) desc,Lead(T2.TotalPrice) over (order by T1.IDCustomer)
