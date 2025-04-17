use portfolio;

-- Looking the count of data table 
select 
	count(*) as toatal_rows
from 
	covid_death;

/*
select *
from covid_vaccination
order by 3,4;
*/

select 
	location, date, total_cases, total_deaths, population
from 
	covid_death
order by 1,2;

-- looking at total cases vs total deaths
select 
	location, date, total_cases, total_deaths, (total_deaths/total_cases)  as death_percentage
from 
	covid_death
where 
	location like '%Br%'
order by 1,2;

-- looking at total cases vs population
select 
	location, date, total_cases, population, (total_cases / population) as case_Percentae
from 
	covid_death
order by 1,2;

-- looking at country with highest Infection
select 
	location, population,  max(total_cases) as Highest_Infection, 
    max( total_cases/ population) * 100 as Percent_Population_Infected
from 
	covid_death
group by 
	location, population
order by 
	Percent_Population_Infected Desc;

-- showing countries with highest death
select 
	location, population, max(total_deaths / population) * 100 as highest_death
from 
	covid_death
group by 
	location, population
order by 
	highest_death desc;


select 
	location, max(total_deaths) as highest_death
from 
	covid_death
where 
	continent is not null
group by 
	location
order by 
	highest_death desc;

-- Difference between HAVING & WHERE
select 
	location, sum(total_cases) as total_cases
from 
	covid_death
where 
	total_cases > 50
group by 
	location;

select 
	location, sum(total_cases) as total_cases
from 
	covid_death
group by 
	location
having 
	sum(total_cases) > 50;
/***********************
-- Join Two Tables
************************/

select * 
from 
	covid_death dea
	join covid_vaccination vac
	on dea.date = vac.date;


-- Looking at Total population vs vaccination
select 
	dea.location, Max(people_vaccinated )/ max(dea.population) * 100 as Vaccination_People
from 
	covid_death dea
	join covid_vaccination vac
	on dea.location = vac.location
    and dea.date = vac.date
where 
	dea.continent is not null
group by 
	dea.location
order by 
	Vaccination_People desc
;
/**********************************
-- Window Function
**********************************/
select 
	location, population, date, total_deaths, rn
from (
	select *, row_number() over (partition by location order by total_deaths desc) as rn
	from covid_death
	) sub
where rn =1
;

select 
	location, total_deaths, date, 
	row_number() over ( partition by continent order by total_deaths desc) as rank_index
from covid_death;


/*******************************
------------ Looking at total population vs Vaccination
********************************/

select distinct
	dea.continent, dea.location, dea.population, dea.date, vac.people_vaccinated,
    (people_vaccinated / population) * 100 as percentage_vaccinated,
    Max(people_vaccinated) over (partition by location) as max_vaccine_per_location
    
from 
	covid_death dea join covid_vaccination vac
on
	dea.location = vac.location
    and dea.date = vac.date
where 
	people_vaccinated is not null
    and trim(people_vaccinated) <> ''
order by 
	percentage_vaccinated desc

;
/*******************************
------------ CTE---------------
Looking at total population vs Vaccination
********************************/
with max_vaccinate_cte as(
select 
	dea.location, dea.date, people_vaccinated, population,
	max(people_vaccinated) over (partition by location) as max_vacc
from
	covid_vaccination vac
    join covid_death dea
    on dea.location = vac.location
    and dea.date = vac.date
where 
		people_vaccinated is not null
        and trim(people_vaccinated)<>''

)
select 
	vac.continent,vac.location, vac.date, vac.people_vaccinated, (cte.max_vacc/ population) * 100 as percentage_vaccine
from
	covid_vaccination vac
    join max_vaccinate_cte cte
on
	vac.location = cte.location
    and vac.date = cte.date
	and vac.people_vaccinated = cte.max_vacc
    order by percentage_vaccine desc
;


with max_vac_cte as (
select continent, location, Max(people_vaccinated) as max_vacc
from covid_vaccination
where 
Trim(people_vaccinated) <> ''
and people_vaccinated is not null
group by location, continent
)
select distinct c.continent, c.location
from covid_vaccination c join max_vac_cte cte
on c.people_vaccinated = cte.max_vacc
and c.location = cte.location
order by location
;

/*******************************
Create temp table 
********************************/
create table Percentage_Poulation_Vaccinated
(
	continent text,
	location text,
    population int,
    date text,
    people_vaccinated text,
    percentage_vaccine text

);

Insert into Percentage_Poulation_Vaccinated
(
select distinct
	dea.continent, dea.location, dea.population, dea.date, vac.people_vaccinated,
    (people_vaccinated / population) * 100 as percentage_vaccinated
   
    
from 
	covid_death dea join covid_vaccination vac
on
	dea.location = vac.location
    and dea.date = vac.date
where 
	people_vaccinated is not null
    and trim(people_vaccinated) <> ''
order by 
	percentage_vaccinated desc
)
;
/*******************************
Creating view to store data for later visulaization
********************************/

create view Percentage_Poulation_vs_Vaccinated as 
select distinct
	dea.continent, dea.location, dea.population, dea.date, vac.people_vaccinated,
    (people_vaccinated / population) * 100 as percentage_vaccinated
from 
	covid_death dea join covid_vaccination vac
on
	dea.location = vac.location
    and dea.date = vac.date
where 
	people_vaccinated is not null
    and trim(people_vaccinated) <> ''
order by 
	percentage_vaccinated desc
    ;
-- Run view
select * from Percentage_Poulation_vs_Vaccinated