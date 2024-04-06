
#-------------------------------------------------------------------------------------------------------------------------

# page_num = 1
# try:
#     thread_name= threading.current_thread().name
#     #print(threading.current_thread().name)
#     #sometime we are going to have different thread name in each iteration so a little regex might help
#     # This code avoids leaving additional threads running whenever "ThreadPoolExecutor" is run
#     thread_name = re.sub("ThreadPoolExecutor-(\d*)_(\d*)", r"ThreadPoolExecutor-0_\2", thread_name)
#     #print(f"re.sub -> {thread_name}")
#     driver = drivers_dict[thread_name]
# except KeyError:
#     drivers_dict[threading.current_thread().name] = webdriver.Chrome(ChromeDriverManager().install(), options=options)
#     driver = drivers_dict[threading.current_thread().name]  

# sector_url = sector_urls[sector_num]
# page_url   = get_page_url(sector_url, page_num)
# driver.get(page_url)
# time.sleep(2)
# ngos_on_page = driver.find_elements_by_xpath("//a[contains(@onclick,'show_ngo_info')]")
# page_df = pd.DataFrame()

# # This command extracts the table of ngos + some extraneous information
# # The second row subsets the first 500 elements (100 organizations x 5 attributes)
# ngolist_table = driver.find_element_by_xpath(".//table[contains(@class,'table table-striped table-bordered table-hover Tax')]");
# raw_table = [i.get_attribute('innerHTML') for i in ngolist_table.find_elements_by_xpath('//tbody//tr//td')][0:500]

# ngo_numinpage    = raw_table[0::5]
# ngo_hyperlink    = raw_table[1::5]
# ngo_registration = raw_table[2::5]
# ngo_address      = raw_table[3::5]
# ngo_sectors      = raw_table[4::5]
# ngo_names = [i.split("<")[1].split(">")[1] for i in ngo_hyperlink]

# page_df['numinpage'] = ngo_numinpage
# page_df['ngo_names'] = [sector_num for i in range(0,len(ngo_numinpage))]
# page_df['ngo_names']   = ngo_names
# page_df['ngo_hyperlink'] = ngo_hyperlink
# page_df['ngo_registration'] = ngo_registration
# page_df['ngo_address'] = ngo_address
# page_df['ngo_sectors'] = ngo_sectors

# # page_df

# page_df.to_csv(f'{store_directory}/list_sectorno_{sector_num}_page{page_num}_ngo_scraping.csv', index=False)    

#-------------------------------------------------------------------------------------------------------------------------

# sector_urls[9]
# get_num_of_pages_for_sector(1,driver)

# scrape_list_ngo_sector(1)

#-------------------------------------------------------------------------------------------------------------------------


# print(f"Inititate Multithreading for Extracting List of NGOs")
# max_workers_num = 10

# with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers_num) as executor:
#     result = executor.map(lambda sector_num_parallel: scrape_list_ngo_sector(sector_num_parallel), range(0,len(sector_urls)))

#-------------------------------------------------------------------------------------------------------------------------


# Command to compute the cumulative count of a dataset

# list_allngos = pd.DataFrame()

# #for sector_num in range(0,len(sector_urls)):
# for sector_num in range(1,3):
#     sector_df = pd.read_csv(f'{store_directory}/list_sectorno_{sector_num}_ngo_scraping.csv')
#     list_allngos = pd.concat([list_allngos,sector_df])

# # Create dianostic variables for possible duplicates in the list.
# list_allngos['duplicates_index'] = list_allngos.groupby(["ngo_hyperlink","ngo_registration"]).cumcount()+1
# list_allngos['total_duplicates'] = list_allngos.groupby(["ngo_hyperlink","ngo_registration"])["ngo_name"].transform('size')

# list_allngos.to_csv(f'{store_directory}/list_all_ngo_scraping.csv', index=False)    
        
# list_allngos


#-------------------------------------------------------------------------------------------------------------------------


# ## This code creates initiates a list of web drivers used for multi-threading
# ## Intuitively, this is like opening multiple tabs on Chrome web browser.

# max_workers_num = 10
# drivers_dict={}

# for i in range(0,max_workers_num-1):
#     drivers_dict[i] = webdriver.Chrome(ChromeDriverManager().install(), options=options)
