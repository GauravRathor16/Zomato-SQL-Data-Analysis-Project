Create Database P6_Zomato;

use P6_Zomato;
select * from zomato;
select name, ROUND(rate, 2) as Rating, votes from zomato_VR;

select COUNT(*)
from zomato;

sp_help zomato;

--Data Cleaning
    --Delete unuse Column
Alter table zomato
drop column rate;

Alter table zomato
drop column votes;

Alter table zomato
drop column dish_liked;

Alter table zomato
drop column rate;


--correct Column name

EXEC sp_rename 'zomato.approx_cost(for two people)', 'Cost_two_People', 'COLUMN';

EXEC sp_rename 'zomato.listed_in(type)', 'listed_in_type', 'COLUMN';

EXEC sp_rename 'zomato.listed_in(city)', 'listed_in_city', 'COLUMN';


--Find Null and blanks value

Select * 
from zomato
where name is null or name = ' '
  and online_order is null or online_order = ' '
  and book_table is null or book_table = ' '
  and rest_type is null or rest_type= ' '
  and cuisines is null or cuisines = ' '
  and Cost_two_People is null or Cost_two_People = ' ' 
  and listed_in_city is null or listed_in_city = ' '
  and listed_in_type is null or listed_in_type = ' ';




  --Delete All  Null and blanks value Rows

  delete
  from zomato
  where name is null or name = ' '
  and online_order is null or online_order = ' '
  and book_table is null or book_table = ' '
  and rest_type is null or rest_type= ' '
  and cuisines is null or cuisines = ' '
  and Cost_two_People is null or Cost_two_People = ' '
  and listed_in_city is null or listed_in_city = ' '
  and listed_in_type is null or listed_in_type = ' ';


  --Find Duplicates
  
    --Table zomato
  Select name, COUNT(*)
  from zomato
  group by name
  Having Count(*) > 1;

   -- Table Zomato_vr

   Select name, rate, votes, Count(*)
   from zomato_VR 
   group by name, rate, votes
   Having COUNT(*) > 1 ;


     --table location
   select name, Count(*) as FD
   from Location
   group by name
   Having COUNT(*) > 1;

  --Delete Duplicates
       --Table zomato
  with DDIZT as (
          Select *,
		     ROW_NUMBER() 
			 over
			 (partition by name
			 order by name)
			 as rn
		 from zomato
		 )

Delete 
from DDIZT
where rn > 1;

       -- Table Zomato_vr
 with DDIZVT as ( 
               select *,
			    ROW_NUMBER() over (partition by name order by name) as CRN
			  from zomato_VR
			  )
Delete 
from DDIZVT
where CRN > 1;

          --table location 
with DDILT as ( Select * ,
                 ROW_NUMBER() over ( Partition by name order by name ) as DU
				From Location
			   )
Delete from DDILT
where DU > 1;

 -- Data CLeaning is Done


  --SQL problems based on Zomato Data Analysis

--1.List all restaurants in Bangalore.

select name as Restaurants, Location as City
from Location
where Location = 'Bangalore';


--2.Find all restaurants that offer online delivery.


select name as Restaurants, online_order
from zomato
Where online_order = 'Yes';


--3.Show top 10 restaurants by votes.

select Top 10 name as Restaurants, MAX(votes) as Votes
from zomato_VR
Group by name
order by Votes desc;

--4.Find all restaurants that serve North Indian cuisine.

Select name as Restaurants, cuisines
from zomato
where cuisines Like '%North Indian%';

--5.List restaurants with a rating above 4.5.

Select DISTINCT(z.name) as Restaurants, Round(v.rate , 2) Rating
from zomato z
join zomato_VR v on z.name = v.name
where v.rate > 4.5;


--6.Find the average cost for two for each city.

select  listed_in_city, AVG(cost_two_People) as Average_Cost
from zomato
Group by listed_in_city;


--7.Which cuisines are offered most frequently?

select cuisines, COUNT(*) as Offered_most_frequently
from zomato
group by cuisines
order by COUNT(*) desc;

--8.Top 5 locations in  Bangalore with highest average rating.


With CLR as (select l.Location as City,  z.listed_in_city as location, ROUND( vr.rate, 2) as Rating
from zomato z
join zomato_VR vr on vr.name = z.name
inner join Location l on z.name = l.name
where l.Location = 'Banglore'
)
Select Top 5 City, location, Round(Avg(Rating), 2) as average_Rating
from CLR
Group by location, City
order by average_Rating desc;

--9.Find restaurants with inconsistent data (votes = 0 and rating > 4).

Select z.name as Restaurent, vr.votes, round(vr.rate, 2) Rating
from zomato z
inner join zomato_VR vr on z.name = vr.name
where vr.rate > 4 and Vr.votes=0;


--10.Count of restaurants offering table booking city-wise.

Select listed_in_city, book_table, COUNT(name) as Count_of_restaurants
from zomato
where book_table = 'yes'
group by listed_in_city, book_table;

--11.Rank restaurants in Bangalore by rating within each location.

With NLR as (
             select DISTINCT(z.name) as Restaurants, 
			 l.Location as City, 
			 ROUND( vr.rate, 2) as Rating
             from zomato z
             join zomato_VR vr on vr.name = z.name
             inner join Location l on z.name = l.name
             where l.Location = 'Banglore'
)
select Restaurants,
       City,
	   Rating,
	   Row_Number()over ( Partition by City order by Rating desc) as Rating_Rank
	   from NLR
	   order by Rating_Rank;

-- bonus tips You use Rank and Dense_Rank funcation as well

--12.Find top-rated restaurant in each city.

With TRC as (Select z.name as Restaurants,
             l.location as City,
	   Round(vr.rate, 2) as Rating,
	   ROW_NUMBER() OVER (PARTITION BY l.Location ORDER BY vr.rate DESC) AS Rank_In_City
from zomato z
join zomato_VR vr on z.name = vr.name
inner join Location l on vr.name = l.name
)
Select Restaurants,
       City,
	   Round(Rating, 2) Top_Rating
from TRC
Where Rank_In_City = 1
and City IS not null
order by City;


--13.Find the most common cost for two range per city.

WITH CostFrequency AS (
    SELECT 
        l.Location AS City,
        TRY_CAST(REPLACE(z.Cost_two_People, ',', '') AS INT) AS Cost_For_Two,
        COUNT(*) AS Frequency,
        ROW_NUMBER() OVER (
            PARTITION BY l.Location 
            ORDER BY COUNT(*) DESC
        ) AS RankInCity
    FROM zomato z
    INNER JOIN Location l ON z.name = l.name
    WHERE z.Cost_two_People IS NOT NULL
    GROUP BY l.Location, REPLACE(z.Cost_two_People, ',', '')
)

SELECT 
    City,
    Cost_For_Two,
    Frequency
FROM CostFrequency
WHERE RankInCity = 1
and City is not null
ORDER BY City;



--14.Restaurants with rating higher than city average.



 with City_Rating as(
                  Select l.Location as City,
	              Round(Avg(vr.rate), 3)  as City_AVG_Rating
                  from zomato z
                  Inner join zomato_VR vr on vr.name = z.name
                  Inner join Location l on l.name = vr.name
                  Group by l.Location)

Select z.name as Restaurants,
       Round(vr.rate, 3)  as Rating,
       l.location as City,
	   Round(cr.City_AVG_Rating, 2) as City_Rating
from zomato z
Inner join zomato_VR vr on vr.name = z.name
Inner join Location l on l.name = vr.name
join City_Rating cr on cr.City = l.location
where vr.rate > cr.City_AVG_Rating
and vr.rate is not null;



--15.Which city has the most high-end restaurants (cost > ₹1000 & rating > 4)?


with MHER as (
Select  z.name as Restaurants, Round(v.rate, 2) as Rating, z.Cost_two_People as Cost, l.Location as City
from zomato z
 Inner join zomato_VR v on z.name = v.name
 Inner join Location l on v.name = l.name
Where v.rate is not null and z.name is not null
and v.rate > 4
and z.Cost_two_People > 1000
) 
Select City,  COUNT(*) as Number_of_Restaurants
From MHER
group by City
order by Number_of_Restaurants desc;

--16.Which cuisine has the highest average rating across all restaurants?

With Cuisine_Avg_Rating as (
                             Select z.name as Restaurants,
							 TRIM(Value) as Cuisine,
							 ROUND(v.rate, 2) as Rating
							 From zomato z
							 inner join zomato_VR v on z.name = v.name
							 CROSS APPLY STRING_SPLIT(z.cuisines, ',')
							 where v.rate IS not Null
							 )
select DISTINCT(Cuisine), Rating
from Cuisine_Avg_Rating
order by Rating desc;


--17.Identify restaurants with poor ratings (<3.0) but high votes (>500).

Select z.name as Restaurants, Round(v.rate, 2) as Ratings, v.votes 
from zomato z
inner join zomato_VR v on z.name = v.name
Where v.rate is not null and v.rate < 3.0
      and v.votes > 500;



--18.Find restaurants that have the same name but are in different cities (franchise check).
select z.name, Count( DISTINCT l.Location) as City_Count
from zomato z
inner join Location l on z.name = l.name
group by z.name
having Count( DISTINCT l.Location) > 1
ORDER BY City_Count DESC;


--19.Suggest cities where Zomato could promote delivery services (cities with many restaurants but low online delivery %).

Select l.location as City,
       Count(z.name) as Total_Restaurants,
	   Sum( Case When z.online_order = 'Yes' Then 1 Else 0 End) as Online_Delivery_Count,
	   Round
	        (Cast
			     (Sum(Case when z.online_order = 'Yes' Then 1 Else 0 END) as Float) / Count(z.name) * 100, 2) as Online_Delivery_Percent
from zomato z
inner join Location l  on z.name = l.name
Where l.Location Is Not Null
group by l.location
Having Count(z.name) > 20 
      AND Round (Cast(Sum( Case when z.online_order = 'Yes' Then 1 Else 0 End) as Float) / Count(z.name) * 100, 2 ) < 50
	  order by online_Delivery_Percent asc;


-------------------------------------------------------------------------------------------------------------------------------------------------------
                                                                       -- Thank You  ---
---------------------------------------------------------------------------------------------------------------------------------------------------------