use portfolio;

select 
	* 
from 
	portfolio.nashville_housing_data;
    
/*************************
-- Standardize Sale Date
************************/

    -- Step 1: Preview the conversion by selecting SaleDate and the converted date
SELECT 
    SaleDate,
    STR_TO_DATE(SaleDate, '%M %d, %Y') AS converted_sale_date
FROM 
    nashville_housing_data;



-- Step 2: Disable SQL Safe Updates to allow updates without restrictions
SET SQL_SAFE_UPDATES = 0;

-- Step 3: Update the 'sale_date_converted' column with the converted date from 'SaleDate'
UPDATE 
    nashville_housing_data
SET 
    SaleDate = STR_TO_DATE(SaleDate, '%M %d, %Y')
WHERE
    SaleDate IS NOT NULL;
-- Show Output
select 
	* 
from 
	nashville_housing_data;
    
/*************************
-- Populate Propert Address
************************/

select 
	*
from 
	nashville_housing_data
order by 
	ParcelID;
	-- trim(PropertyAddress) = '';
    
select ParcelID, count(*)
from nashville_housing_data
group by ParcelID
having count(*)>1;


    
UPDATE nashville_housing_data AS a
JOIN nashville_housing_data AS b
  ON a.ParcelID = b.ParcelID
  AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = b.PropertyAddress
where
	a.PropertyAddress = a.ParcelID;


/*************************
-- Breaking Out Address into Individual columns (Address, City, State)
************************/
select OwnerAddress
from
	nashville_housing_data;

-- Breaking out PropertAddress
select 
	PropertyAddress,
	substring(PropertyAddress, 1, locate(',', PropertyAddress)-1) as street,
    substring(PropertyAddress, locate(',', PropertyAddress)+1) as City
from nashville_housing_data;

-- Breaking out OwnerAddress
SELECT 
  OwnerAddress,

  -- Get street (before first comma)
  SUBSTRING(OwnerAddress, 1, LOCATE(',', OwnerAddress) - 1) AS street,

  -- Get city (between first and second comma)
  SUBSTRING(
    OwnerAddress,
    LOCATE(',', OwnerAddress) + 2,
    LOCATE(',', OwnerAddress, LOCATE(',', OwnerAddress) + 1) - LOCATE(',', OwnerAddress) - 2
  ) AS city,

  -- Get state (after second comma)
  SUBSTRING(
    OwnerAddress,
    LOCATE(',', OwnerAddress, LOCATE(',', OwnerAddress) + 1) + 2
  ) AS state,
  
  -- Optional: alternative logic for state (duplicated, possibly for debugging)
    SUBSTRING(
        OwnerAddress, 
        LOCATE(',', OwnerAddress, LOCATE(',', OwnerAddress) + 1) + 2, 
        LENGTH(OwnerAddress) - LOCATE(',', OwnerAddress, LOCATE(',', OwnerAddress) + 1) + 2
    ) AS state2

FROM 
  nashville_housing_data;

ALter table nashville_housing_data
add ownercity char(255),
add ownerstreet char(255),
add ownerstate char(255);

select *
from nashville_housing_data;

update 
	nashville_housing_data
set 
	ownerstreet =  SUBSTRING(OwnerAddress, 1, LOCATE(',', OwnerAddress) - 1) ,
    ownercity= SUBSTRING(
    OwnerAddress,
    LOCATE(',', OwnerAddress) + 2,
    LOCATE(',', OwnerAddress, LOCATE(',', OwnerAddress) + 1) - LOCATE(',', OwnerAddress) - 2
  ) ,
  ownerstate = SUBSTRING(
        OwnerAddress, 
        LOCATE(',', OwnerAddress, LOCATE(',', OwnerAddress) + 1) + 2, 
        LENGTH(OwnerAddress) - LOCATE(',', OwnerAddress, LOCATE(',', OwnerAddress) + 1) + 2
    );

-- Second Way to Parsing Address
select
    OwnerAddress,
	substring_index(OwnerAddress,',',1) as street,
    substring_index(OwnerAddress,',',-1) as state,
	substring_index(substring_index(OwnerAddress,',',2),',',-1) as city
    
from 
	nashville_housing_data;
	
/*************************
-- Change Y and N to Yes and No in "SoldAsVacant" field
************************/

select distinct(SoldAsVacant), count(SoldAsVacant)
from
	nashville_housing_data
Group by SoldAsVacant;

update nashville_housing_data
set Soldasvacant2 = SoldAsVacant;

update nashville_housing_data 
set SoldAsVacant = case
		when SoldAsVacant = 'Yes' then 'Y'
        when SoldAsVacant = 'No' then 'N'
        else 'Unknown'
	End;
    
/*************************
-- Remove Duplication
************************/
with Remove_Duplication_CTE as(
Select 
	*,
	Row_number() over (partition by 
							ParcelID, 
							LandUse, 
                            PropertyAddress, 
                            SaleDate, 
                            SalePrice
						order by ParcelID) as row_num 
from nashville_housing_data
-- order by row_num desc
)
Delete from nashville_housing_data
where UniqueID In(
select UniqueID from Remove_Duplication_CTE
where row_num > 1)
;

-- Check to see if duplication has been removed
with Remove_Duplication_CTE as(
Select 
	*,
	Row_number() over (partition by 
							ParcelID, 
							LandUse, 
                            PropertyAddress, 
                            SaleDate, 
                            SalePrice
						order by ParcelID) as row_num 
from nashville_housing_data
-- order by row_num desc
)
select * 
from Remove_Duplication_CTE
where row_num > 1;

/*************************
-- Delete Unused Column
************************/
Alter table nashville_housing_data
drop column  OwnerAddress;