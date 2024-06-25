# Nancy Pelosi Portfolio Performance

#### This is a separate, albeit, a more concise and organized branch from the main in which I am only analyzing and focusing on Nancy Pelosi's transactions. The reason I chose Nancy Pelosi is because Alpha Vantage only allows 25 API calls / day and Nancy Pelosi coincidentally has 25 distinct tickers, one ticker for each api call. She is also notoriously known her behemoth gains in the stock market. See [here](https://finance.yahoo.com/news/former-house-speaker-nancy-pelosi-095000785.html). 

#### This is an updated section on the main branch in which I 1) extracted stock/ticker information from the Alpha Vantage API instead of this [website](http://finance.jasonstrimpel.com/bulk-stock-download/) 2) Didn't delete any transactions that had no corresponding stock close information like I did on the main branch. This would give a more accurate view of Nancy Pelosi's portofolio performance without having to compromise on deleting transactions. I am also showcasing my Python skills with: Loops and the Pandas Libraries. 

#### The portoflio return calculation is in the sql file titled [final_output.sql](https://github.com/JasonSTLee/politician_project/blob/Nancy-Pelosi/final_output.sql) and the Python api extraction code is [api_politician.ipynb](https://github.com/JasonSTLee/politician_project/blob/Nancy-Pelosi/api_politician.ipynb) file.
