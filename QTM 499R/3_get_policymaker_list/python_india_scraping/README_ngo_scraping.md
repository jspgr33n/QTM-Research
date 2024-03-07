# NGO Scraping Task

## Files: 

The prototype consists of the following files: 

1. requirements_ngo.txt
2. prototype_ngo_scraping_single_ngo.ipynb
3. prototype_ngo_scraping_parallelized.ipynb
4. prototype_scraping_unsuccessful_pages.ipynb



### requirements_ngo.txt

This file lists out all the python packages and their versions used to create the virtual environment used for the scraping. This file can be used to create a virtual environment using anaconda or miniconda with the following command in the terminal:

```
conda env create --file requirements_ngo.txt
```

Note that if *requirements_ngo.txt* is not in the current directory, then the full path to the file has to be specified in the above command in order to employ it for restoring the environment. This step assumes that you are already working with conda for python. If not, it's highly recommended to manage python environments using conda. Instructions for installing (mini)conda on different systems can be found [here](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html). 

This [page](https://docs.microsoft.com/en-us/visualstudio/python/managing-required-packages-with-requirements-txt?view=vs-2022#:~:text=The%20most%20common%20command%20is,txt.&text=If%20you%20want%20to%20install,use%20the%20Install%20from%20requirements.) illustrates how to use a .txt file to restore an environment using the Windows UI. 

### prototype_ngo_scraping_single_ngo.ipynb

This file is a jupyter notebook that demonstrates how to scrape data for a single, randomly-chosen NGO on the website. It is primarily used to try out different ways of extracting data. It's useful as a prototype but has limited functionality as an end-product. It is set-up to run in "non-headless" mode, that is when the script is running you can observe the actions on the browser. This notebook is useful for understanding the order in which things are happening, additonally out of all the files in the prototype, this one is most heavily annotated and consequently, most illustrative of the task in hand. 



### prototype_ngo_scraping_parallelized.ipynb

This file extends _prototype_ngo_scraping_parallelized.ipynb_ in the following ways: 

1. it provides code for scraping information for NGOs from mutliple pages and mutiple sectors; 
2. it organizes the code into functions, thus making it more modular; 
3. it provides a way to parallelize the execution of the scraping functions. 

This jupyter notebook is closest to an end-product, it is set-up to run with minimal changes. 



### prototype_scraping_unsuccessful_pages.ipynb

The way the parallelized script works is that it saves the URLs to the pages that glitched (see: Key Challenges below) into a separate.csv to retry later. This notebook provides code for loading and running the scraper for just these pages. Additionally, this notebook also provides code for removing curly brackets from the "dictionary" columns to get a comma-separated list instead of a dictionary. 







## Key Challenges: 

The key challenge arises from the fact that the information for individual NGOs is contained in a pop-up box. So, scraping information from a single NGO and then moving on to the next, requires closing the pop-up box, which in and of itself is easily achieved, however, each time a pop-up box opens it is overlaid with a "Please wait" banner which interferes with the close-button. Here are the steps I've tried to circumvent this: 

1. I've added code for the scraped to wait for the close-button to become clickable before clicking on it, however, the close-button becomes clickable but the overlaid banner sometimes prevents it from being interactable, making the output tentative at best. 
2. I've added an hard-coded wait time after the close-button becomes clickable. While this works, I currently use a sleep time of 2 seconds (which already is a little high given the volumne of data to be scraped), and 2 seconds hasn't proved to be fool-proof in my experiments. After scraping data for around 500 or so firms my internet slows down enough for the "Please wait" banner to outlast the 2-second sleep time. So a fool-proof sleep-time would probably vary with internet speed. 

I am not using try-except blocks to keep the code running even when it runs into this problem. The script tries to run the scraper, if the scraper runs into an error/exception, it notes the page at which it occurred and continutes on to the next page. The erroneous pages then can be scraped at a later point after the script has finished running. 