-- Cleaning, house and senate tables and querying all of Nancy Pelosi's unique tickers

		-- 1 Appending and then cleaning senate and house raw tables
		
		CREATE TABLE politician_raw as (
		with house as (
			SELECT
				*
			FROM
				house_raw
			WHERE
				ticker is NOT NULL
		), senator as (
			SELECT
				*
			FROM
				senate_raw
			WHERE
				type is NOT NULL
		)
		SELECT
			transaction_date, disclosure_date, ticker, asset_description, type, amount, representative as politician, party, district, state, industry, sector
		FROM
			house
		UNION ALL
		SELECT
			transaction_date, disclosure_date, ticker, asset_description, type, amount, senator, party, NULL AS district , state, industry, sector
		FROM
			senator
		)
		
		
			-- 1.a Cleaning the descriptions and dollar amount 
		
		CREATE TABLE politician as (
			with cte1 AS (
				SELECT
					DISTINCT ON (p1.ticker)
					p1.ticker, 
					CASE 
						WHEN LENGTH(p1.asset_description) < LENGTH(p2.asset_description) THEN p1.asset_description 
						ELSE p2.asset_description END as shorter_description
				FROM
					politician_raw p1
				JOIN
					politician_raw p2 ON p1.ticker = p2.ticker
			), cte2 AS (
				SELECT
					transaction_date, disclosure_date, p.ticker, shorter_description, type, amount, politician, party, district, state, industry, sector
				FROM
					politician_raw p
				JOIN
					cte1 c ON c.ticker = p.ticker
			)
			SELECT
				row_number () over () as transaction_id,
				transaction_date,
				disclosure_date,
				UPPER(ticker) ticker,
				shorter_description,
				CASE
					WHEN LOWER(type) = 'exchange' THEN 'exchange'
					WHEN type = 'purchase' THEN 'purchase'
					WHEN type LIKE 'sale%' THEN 'sale'
					ELSE NULL END as type_1,
				CASE 
					WHEN amount = '$1,001 -' THEN (1000)::integer
					WHEN amount = '$1,001 - $15,000' THEN (15000)::integer 
					WHEN amount = '$1,000 - $15,000' THEN (15000)::integer
					WHEN amount = '$15,001 - $50,000' THEN (50000)::integer
					WHEN amount = '$15,000 - $50,000' THEN (50000)::integer
					WHEN amount = '$50,001 - $100,000' THEN (100000)::integer
					WHEN amount = '$100,001 - $250,000' THEN (250000)::integer
					WHEN amount = '$250,001 - $500,000' THEN (500000)::integer
					WHEN amount = '$500,001 - $1,000,000' THEN (1000000)::integer
					WHEN amount = '$1,000,000 - $5,000,000' THEN (5000000)::integer
					WHEN amount = '$1,000,001 - $5,000,000' THEN (5000000)::integer
					WHEN amount = '$5,000,001 - $25,000,000' THEN (25000000)::integer
					WHEN amount = '$25,000,001 - $50,000,000' THEN (50000000)::integer
					ELSE NULL END as amount,
				politician,
				party,
				district,
				state,
				industry,
				sector
			FROM
				cte2
		)
		
		
		ALTER TABLE politician
		RENAME COLUMN type_1 to "type"
		
			-- 1.2 Deleting rows where the type is exchange since it's an unknown transaction type
		
		DELETE FROM politician
		WHERE "type" = 'exchange'
		
			-- 1.3 Delete senators that only have sale transactions since there's no purchase entry for those stocks
		
		DELETE FROM politician
		WHERE politician IN (
			with cte as (
				SELECT
					politician, 
					CASE WHEN (SUM(CASE WHEN type = 'sale' THEN 1 END)) = COUNT(*) THEN 1 END flag
				FROM
					politician
				GROUP BY
					politician
			)
			SELECT
				politician
			FROM
				cte
			WHERE
				flag = 1
		)
		
			-- 1.4 Getting rid of all the '-usd' string values in the crypto trades
		
		SELECT
			REPLACE(ticker, '-USD', '')
		FROM
			politician
		WHERE
			ticker LIKE '%-%'
			and
			LOWER(ticker) LIKE '%usd%'

			
SELECT
	DISTINCT ticker -- Using this output to create a list in Python to then loop over and pull stock information using Alpha Vantage
FROM
	politician
WHERE
	politician = 'Nancy Pelosi' 


----------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT
	COUNT(*)
FROM
	politician
WHERE
	politician = 'Nancy Pelosi' 

			
SELECT
	ticker, MAX(close)
FROM
	nancy_tickers
GROUP BY
	ticker
 

			
-- (total_amount_sold + (remaining shares * current price) - total_amount_purchase / total_amount_purchase)
-- ((count_of_shares * current price) - total_amount_purchase / total_amount_purchase)
			
with return_cte as (		
	SELECT
		p.transaction_date date, p.ticker, p.type, p.amount, n.close
	FROM
		politician p 
	JOIN
		nancy_tickers n ON p.ticker = n.ticker and p.transaction_date = n.date
	WHERE
		p.politician = 'Nancy Pelosi' 
), return_cte2 as (
	SELECT	
		ticker, 
		type, 
		SUM(CASE WHEN type = 'purchase' THEN (amount / close) END) shares_purchase,
		SUM(CASE WHEN type = 'sale' THEN (amount / close) END) shares_sale,
		SUM(CASE WHEN type = 'purchase' THEN amount END) total_amount_purchase,
		SUM(CASE WHEN type = 'sale' THEN -amount END) total_amount_sale
	FROM
		return_cte
	GROUP BY
		ticker, type
), return_cte3 as (
	SELECT
		r.ticker,
		SUM(total_amount_purchase) total_amount_purchase, 
		SUM(total_amount_sale) total_amount_sale, 
		SUM(shares_purchase) shares_purchase,
		SUM(shares_sale) shares_sale,
		(SUM(shares_purchase) - SUM(shares_sale)) remaining_shares,
		COALESCE(((SUM(total_amount_sale) + ((SUM(shares_purchase) - SUM(shares_sale)) * MAX(n.close)) - SUM(total_amount_purchase)) / SUM(total_amount_purchase)),
		CASE WHEN SUM(total_amount_sale) is null THEN (((SUM(shares_purchase) * MAX(n.close)) - SUM(total_amount_purchase)) / SUM(total_amount_purchase)) END) return_purchase,
		CASE 
			WHEN SUM(shares_purchase) - SUM(shares_sale) < 0 THEN 0
			WHEN SUM(shares_purchase) - SUM(shares_sale) is null THEN SUM(shares_purchase)
		ELSE 
			SUM(shares_purchase) - SUM(shares_sale)
		END shares
	FROM
		return_cte2 r
	RIGHT JOIN
		nancy_tickers n ON r.ticker = n.ticker
	GROUP BY
		r.ticker
), final_cte as (
	SELECT
		ticker, return_purchase, shares, (shares / SUM(shares) OVER(ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) * 100) weight,
		return_purchase * (shares / SUM(shares) OVER(ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) * 100) final_return
	FROM
		return_cte3
	WHERE
		ticker is not null
		and
		total_amount_purchase is not null
)
SELECT
	SUM(final_return)
FROM
	final_cte
