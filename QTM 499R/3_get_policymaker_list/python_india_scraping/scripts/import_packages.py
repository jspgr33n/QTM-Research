
#-------------------------------------------------------------------------------------------------------------------------

import pandas as pd # To store scraped data
import re # Use regular expressions
import os # To get user/storage paths
import getpass


#--------DISPLAY SETTINGS FOR THE NOTEBOOK--------
# from IPython.core.interactiveshell import InteractiveShell
# InteractiveShell.ast_node_interactivity = 'all' #to see all outputs of a cell, as opposed to only the last one
# from IPython.display import display, HTML # Alejandro-Note: Changed from IPython.display
# display(HTML("<style>.container { width:100% !important; }</style>")) #make the notebook take up more screen space (default is 60%)

#-------------------------------------------------------------------------------------------------------------------------

#-------SCRAPING SPECIFIC MODULES--------
import requests #to conduct different forms of HTTP requests
import html5lib #to construct tree structure of HTML data
from bs4 import BeautifulSoup as soup #to parse the html data obtained from the scrape
import time # to add wait time, to keep the website from kicking us out and also to let the page load before grabbing data
from selenium import webdriver #to automate the navigating within the browser
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select #to select the features we want on the website via the scraper
from selenium.webdriver.support.ui import WebDriverWait #again, to add wait times more 'implicitly'
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options #to use properties of the chrome webbrowser
from selenium.webdriver.remote.command import Command # Use to check whether the web driver is active

#-------------------------------------------------------------------------------------------------------------------------


#-------SCRAPING SPECIFIC MODULES--------
import requests #to conduct different forms of HTTP requests
import html5lib #to construct tree structure of HTML data
from bs4 import BeautifulSoup as soup #to parse the html data obtained from the scrape
import time # to add wait time, to keep the website from kicking us out and also to let the page load before grabbing data
from selenium import webdriver #to automate the navigating within the browser
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select #to select the features we want on the website via the scraper
from selenium.webdriver.support.ui import WebDriverWait #again, to add wait times more 'implicitly'
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options #to use properties of the chrome webbrowser
from selenium.webdriver.remote.command import Command # Use to check whether the web driver is active

#-------------------------------------------------------------------------------------------------------------------------

import random
from joblib import Parallel, delayed # for parallelizing
from tqdm import tqdm # this provides a visual progress tracker for loops

import concurrent.futures
from concurrent.futures import ThreadPoolExecutor, wait
import threading, queue
from itertools import repeat
from concurrent import futures
from multiprocessing import Pool  # This is a CPU-based Pool
from multiprocessing import cpu_count