
#-------------------------------------------------------------------------------------------------------------------------

#--- This function extracts the page url for a specific sector + page number
def get_page_url(sector_url, page_num):
    # page_url = sector_url.split('?',1)[0][:-1]+f'{page_num}?per_page=100'
    page_url = sector_url.split('?',1)[0][:-1]+f'{page_num}?per_page=20' # for shorter tests
    return page_url

#-------------------------------------------------------------------------------------------------------------------------

#--- This function creates a sector-specific URL
def get_sector_urls(base_url): 
    driver.get(base_url)
    sector_urls = [url.get_attribute('href') for url in driver.find_elements(By.CLASS_NAME, 'bluelink11px')]
    # sector_urls = [url+'?per_page=100' for url in sector_urls]
    sector_urls = [url+'?per_page=20' for url in sector_urls] # for shorter tests
    return sector_urls

#-------------------------------------------------------------------------------------------------------------------------

#--- This function captures the number of pages per sector
def get_num_of_pages_for_sector(sector_num,driver): 
    sector_url = sector_urls[sector_num]
    driver.get(sector_url)
    list_buttonlast = driver.find_elements(By.PARTIAL_LINK_TEXT, 'Last')
    # If there are more than 10 pages, extract the link from the "last page".
    # Otherwise count how many page buttons there are (excluding the "previous" and "next" buttons)
    if len(list_buttonlast) > 0:
        driver.find_elements(By.PARTIAL_LINK_TEXT, 'Last')[0].click()
        last_page_url = driver.current_url
        total_pages = int(last_page_url.split('?')[0].rsplit('/',1)[1])
    else:
        list_page_nums = driver.find_elements(By.XPATH, "//ul[@class='pagination']//li") # updated this code as previous version did not work
        if len(list_page_nums) == 0:
            total_pages = 1
        else:
            total_pages = len(list_page_nums)-2
    return total_pages

#-------------------------------------------------------------------------------------------------------------------------

#--- This function takes a list of NGO's per page, clicks through them sequentially,
#--- and extracts information from pop-up.
def scrape_a_single_page(sector_num, page_num): 
    
    # The following code selects a web_driver from the dictionary.
    # Both "drivers_dict" and "max_workers are defined in the environment."
    #driver = drivers_dict[page_num % max_workers_num]
    
    try:
        thread_name= threading.current_thread().name
        #print(threading.current_thread().name)
        #sometime we are going to have different thread name in each iteration so a little regex might help
        # This code avoids leaving additional threads running whenever "ThreadPoolExecutor" is run
        thread_name = re.sub("ThreadPoolExecutor-(\d*)_(\d*)", r"ThreadPoolExecutor-0_\2", thread_name)
        #print(f"re.sub -> {thread_name}")
        driver = drivers_dict[thread_name]
    except KeyError:
        drivers_dict[threading.current_thread().name] = webdriver.Chrome(options=options)
        driver = drivers_dict[threading.current_thread().name]    
    
    sector_url = sector_urls[sector_num]
    page_url = get_page_url(sector_url, page_num)
    driver.get(page_url)
    time.sleep(3)
    ngos_on_page = driver.find_elements(By.XPATH, "//a[contains(@onclick,'show_ngo_info')]")
    page_df = pd.DataFrame()

    for i in range(0, len(ngos_on_page)):
        print(f'scraping NGO number {i+1}')
        ngo = ngos_on_page[i]
        time.sleep(3)
        ngo.click()
        time.sleep(3)

        name = driver.find_element(By.ID, 'ngo_name_title').get_attribute('innerHTML')
        uid = driver.find_element(By.ID, 'UniqueID').get_attribute('innerHTML')
        reg_with = driver.find_element(By.ID, 'reg_with').get_attribute('innerHTML')
        ngo_type = driver.find_element(By.ID, 'ngo_type').get_attribute('innerHTML')
        ngo_regno = driver.find_element(By.ID, 'ngo_regno').get_attribute('innerHTML')
        rc_upload = driver.find_element(By.ID, 'rc_upload').get_attribute('innerHTML')
        pc_upload = driver.find_element(By.ID, 'pc_upload').get_attribute('innerHTML')
        act_name = driver.find_element(By.ID, 'ngo_act_name').get_attribute('innerHTML')
        city_reg = driver.find_element(By.ID, 'ngo_city_p').get_attribute('innerHTML')
        state_reg = driver.find_element(By.ID, 'ngo_state_p').get_attribute('innerHTML')
        reg_date = driver.find_element(By.ID, 'ngo_reg_date').get_attribute('innerHTML')
        key_issues = driver.find_element(By.ID, 'key_issues').get_attribute('innerHTML')
        operational_states = driver.find_element(By.ID, 'operational_states').get_attribute('innerHTML')
        operational_districts = driver.find_element(By.ID, 'operational_district').get_attribute('innerHTML')
        fcra_details = driver.find_element(By.ID, 'FCRA_details').get_attribute('innerHTML')
        fcra_regno = driver.find_element(By.ID, 'FCRA_reg_no').get_attribute('innerHTML')
        details_achievement = driver.find_element(By.ID, 'activities_achieve').get_attribute('innerHTML')
        contact_address = driver.find_element(By.ID, 'address').get_attribute('innerHTML')
        contact_city = driver.find_element(By.ID, 'city').get_attribute('innerHTML')
        contact_state = driver.find_element(By.ID, 'state_p_ngo').get_attribute('innerHTML')
        contact_telephone = driver.find_element(By.ID, 'phone_n').get_attribute('innerHTML')
        contact_mobile = driver.find_element(By.ID, 'mobile_n').get_attribute('innerHTML')
        contact_website = driver.find_element(By.ID, 'ngo_web_url').get_attribute('innerText')
        contact_email = driver.find_element(By.ID, 'email_n').get_attribute('innerHTML')

        members_table = driver.find_element(By.ID, 'member_table')
        member_names = [i.get_attribute('innerHTML') for i in members_table.find_elements(By.XPATH, './/tr//td')[::4]]
        member_designations = [i.get_attribute('innerHTML') for i in members_table.find_elements(By.XPATH, './/tr//td')[1::4]]
        member_pan = [i.get_attribute('innerHTML') for i in members_table.find_elements(By.XPATH, './/tr//td')[2::4]]
        member_aadhar = [i.get_attribute('innerHTML') for i in members_table.find_elements(By.XPATH, './/tr//td')[3::4]]

        member_name_designation_dict = dict(zip(member_names, member_designations))
        member_name_pan_dict = dict(zip(member_names, member_pan))
        member_name_aadhar_dict = dict(zip(member_names, member_aadhar))

        sof_table = driver.find_element(By.ID, 'source_table')
        dept_name = [i.get_attribute('innerHTML') for i in sof_table.find_elements(By.XPATH, './/tr//td')[::5]]
        source = [i.get_attribute('innerHTML') for i in sof_table.find_elements(By.XPATH, './/tr//td')[1::5]]
        financial_year = [i.get_attribute('innerHTML') for i in sof_table.find_elements(By.XPATH, './/tr//td')[2::5]]
        amount_sanctioned = [i.get_attribute('innerHTML') for i in sof_table.find_elements(By.XPATH, './/tr//td')[3::5]]
        purpose = [i.get_attribute('innerHTML') for i in sof_table.find_elements(By.XPATH, './/tr//td')[4::5]]

        year_amount_dict = dict(zip(financial_year, amount_sanctioned))
        year_dept_dict = dict(zip(financial_year, dept_name))
        year_source_dict = dict(zip(financial_year, source))
        year_purpose_dict = dict(zip(financial_year, purpose))

        df = pd.DataFrame({
            'ngo_name': [name],
            'unique_id': [uid],
            'registered_with': [reg_with],
            'type_of_ngo': [ngo_type],
            'registration_number': [ngo_regno],
            'copy_of_registration_certificate': [rc_upload],
            'copy_of_pan_card': [pc_upload],
            'act_name': [act_name],
            'city_of_registration': [city_reg],
            'state_of_registration': [state_reg],
            'registration_date': [reg_date],
            'key_issues': [key_issues],
            'operational_areas_states': [operational_states],
            'operational_areas_districts': [operational_districts],
            'FCRA_details': [fcra_details],
            'FCRA_registration_num': [fcra_regno],
            'details_of_achievement': [details_achievement],
            'contact_details_address': [contact_address],
            'contact_details_city': [contact_city],
            'contact_details_state': [contact_state],
            'contact_details_telephone': [contact_telephone],
            'contact_details_website': [contact_website],
            'contact_details_email': [contact_email],
            'members_names_designations': [member_name_designation_dict],
            'members_names_pan_availability': [member_name_pan_dict],
            'members_names_aadhar_availability': [member_name_aadhar_dict],
            'source_of_funds_amount_sanctioned': [year_amount_dict],
            'source_of_funds_department_name': [year_dept_dict],
            'source_of_funds_source': [year_source_dict],
            'source_of_funds_purpose': [year_purpose_dict],
            'sector_number': [sector_num],
            'ngo_num': [i],
            'page_num': [page_num],
            'page_num_total': [len(ngos_on_page)]
        })

        page_df = pd.concat([page_df, df])

        page_df.to_csv(f'{store_directory}/sectorno_{sector_num}_pageno_{page_num}_ngo_scraping.csv', index=False)

        close_button = WebDriverWait(driver, 30).until(EC.element_to_be_clickable((By.CSS_SELECTOR, '#ngo_info_modal > div.modal-dialog.modal-lg > div > div.modal-header > button')))
        time.sleep(3)
        close_button.click()
    # drivers_dict[threading.current_thread().name].quit()
    return page_df

#-------------------------------------------------------------------------------------------------------------------------

def scrape_a_sector(sector_num, driver): 
    sector_url = sector_urls[sector_num]
    total_pages = get_num_of_pages_for_sector(sector_num, driver)
    sector_df = pd.DataFrame()
    unsuccessful_pages= pd.DataFrame()
    for page in tqdm(range(1, total_pages+1)):
        print(f'Scraping page number {page}')
        page_url = get_page_url(sector_url, page)
        print(f'Scraping {page_url}')
        try: 
            page_df = scrape_a_single_page(sector_num, page_num= page)
            sector_df = pd.concat([sector_df,page_df]) # Alejandro-note: Use pandas.concat instead. Old method deprecated. sector_df.append(page_df)
            print(f'Page number {page} of {total_pages} finished')
        except Exception as e: 
            print(f'Exception {e} occurred for sector number {0} and page number {page}' )
            temp_df = pd.DataFrame()
            temp_df['sector_num'] = [sector_num]
            temp_df['page_url'] =page_url
            unsuccessful_pages = unsuccessful_pages.append(temp_df)
            unsuccessful_pages.to_csv(f'{store_directory}/unsuccessfully_scraped_pages.csv', index=False)
            continue
    return sector_df

#-------------------------------------------------------------------------------------------------------------------------

# Scrape the list of ngos in each page
def scrape_list_singleplage(sector_num,page_num,driver): 
    
    sector_url = sector_urls[sector_num]
    page_url   = get_page_url(sector_url, page_num)
    driver.get(page_url)
    time.sleep(2)
    ngos_on_page = driver.find_elements(By.XPATH, "//a[contains(@onclick,'show_ngo_info')]") # CHANGING THIS
    page_df = pd.DataFrame()

    # This command extracts the table of ngos + some extraneous information
    # The second row subsets the first 500 elements (100 organizations x 5 attributes)
    ngolist_table = driver.find_elements(By.XPATH, ".//table[contains(@class,'table table-striped table-bordered table-hover Tax')]")
    raw_table = []
    for table in ngolist_table:
        tds = table.find_elements(By.XPATH, './/tbody//tr//td')
        raw_table.extend([td.get_attribute('innerHTML') for td in tds])

    # Limit to the first 500 elements if necessary
    raw_table = raw_table[:500]
    ngo_numinpage    = raw_table[0::5]
    ngo_hyperlink    = raw_table[1::5]
    ngo_registration = raw_table[2::5]
    ngo_address      = raw_table[3::5]
    ngo_sectors      = raw_table[4::5]
    ngo_names = [i.split("<")[1].split(">")[1] for i in ngo_hyperlink]

    page_df['sector_num']    = [sector_num for i in range(0,len(ngo_numinpage))]
    page_df['page_num']      = [page_num for i in range(0,len(ngo_numinpage))]
    page_df['index_in_page'] = [i for i in range(0,len(ngo_numinpage))]
    page_df['ngo_name']     = ngo_names
    page_df['ngo_hyperlink'] = ngo_hyperlink
    page_df['ngo_registration'] = ngo_registration
    page_df['ngo_address']  = ngo_address
    page_df['ngo_sectors']  = ngo_sectors

    # page_df.to_csv(f'{store_directory}/list_sectorno_{sector_num}_page{page_num}_ngo_scraping.csv', index=False)    
    
    return(page_df)


#-------------------------------------------------------------------------------------------------------------------------

# Will be used for 
def scrape_list_ngo_sector(sector_num): 
    print(f'Scraping sector number {sector_num}')  
    sector_url = sector_urls[sector_num]
    # print(f'Scraping sector number {sector_url}')
    #total_pages = total_pages_list[sector_num]
    #print(f'Scraping sector number {total_pages}')    
    #print(f'Initiating Web Driver') 
    try:
        thread_name= threading.current_thread().name
        #print(threading.current_thread().name)
        #sometime we are going to have different thread name in each iteration so a little regex might help
        # This code avoids leaving additional threads running whenever "ThreadPoolExecutor" is run
        thread_name = re.sub("ThreadPoolExecutor-(\d*)_(\d*)", r"ThreadPoolExecutor-0_\2", thread_name)
        #print(f"re.sub -> {thread_name}")
        driver = drivers_dict[thread_name]
        print(f"{thread_name}")
    except KeyError:
        drivers_dict[threading.current_thread().name] = webdriver.Chrome(options=options)
        driver = drivers_dict[threading.current_thread().name] 
    
    print(f'Obtaining total number of pages')    
    total_pages = get_num_of_pages_for_sector(sector_num,driver)
    
    time.sleep(4)
    print(f'Initiating Scraping of NGO lists')
    
    sector_df = pd.DataFrame()
    #unsuccessful_pages= pd.DataFrame()
    for page in tqdm(range(1, total_pages+1)):
        print(f'Scraping Sector {sector_num}, page number {page}')
        page_url = get_page_url(sector_url, page)
        #print(f'Scraping {page_url}')
        page_df = scrape_list_singleplage(sector_num, page_num= page,driver=driver)
        sector_df = pd.concat([sector_df,page_df])

    sector_df.to_csv(f'{store_directory}/list_sectorno_{sector_num}_ngo_scraping.csv', index=False)    
        
    return sector_df

#-------------------------------------------------------------------------------------------------------------------------

def scrape_multiple_pages(sector_num, start_page_num, end_page_num): 
    page_list = list(range(start_page_num, end_page_num+1))
    main_df = pd.DataFrame()
    unsuccessful_pages = pd.DataFrame()
    sector_url = sector_urls[sector_num]
    # The "tqdm" command helps us keep track of progress.
    for page in tqdm(page_list): 
        print(f'Scraping page number {page}')
        page_url = get_page_url(sector_url, page)
        print(f'Scraping {page_url}')
        try: 
            page_df = scrape_a_single_page(sector_num, page_num= page)
            main_df = pd.concat([main_df,page_df]) # Alejandro-note: Use pandas.concat instead. Old method deprecated. main_df.append(page_df)
        except Exception as e: 
            print(f'Exception {e} occurred for sector number {0} and page number {page}' )
            temp_df = pd.DataFrame()
            temp_df['sector_num'] = [sector_num]
            temp_df['page_url'] =page_url
            unsuccessful_pages = pd.concat([unsuccessful_pages,temp_df]) # Alejandro-note: Use pandas.concat instead. Old method deprecated. unsuccessful_pages.append(temp_df) 
            unsuccessful_pages.to_csv('./unsuccessfully_scraped_pages_sector{sector_num}_page{page}.csv', index=False)
            continue

#-------------------------------------------------------------------------------------------------------------------------

#--- Creating a function to compare NGOs to check for potentially missing information.
#--- This function uses scrape_list_singlepage and scrape_a_single_page then compares
#--- NGO names to see if some NGOs may have not been fully scraped/skipped.

#--- parameters are two dataframes. One from front page information and the other from clicked NGO information.
def compare_ngo_information(df_front, df_click):
    # df_front = scrape_list_singleplage(sector_num, page_num, driver) # only takes into account information without click
    # df_click = scrape_a_single_page(sector_num, page_num) # clicks NGO and scrapes information
    unsuccessful_ngo = pd.DataFrame()

    for index, row in df_front.iterrows():
        if row['ngo_name'] not in df_click['ngo_name'].values:
            new_row = row[['ngo_name', 'ngo_hyperlink', 'sector_num', 'page_num', 'index_in_page']] 
            unsuccessful_ngo = unsuccessful_ngo.append(new_row)
            # unsuccessful_ngo = pd.concat([unsuccessful_ngo, pd.DataFrame([row['ngo_name']])])
    
    if len(unsuccessful_ngo) == 0:
        print("All NGOs for this sector and page were properly scraped.")

    return unsuccessful_ngo



