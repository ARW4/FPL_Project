# Import necessary modules & packages:
import sys
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from webdriver_manager.core.os_manager import ChromeType
from selenium.webdriver.chrome.options import Options
import time
import os

# Set driver location and provide website URL:
# service = Service(executable_path="/usr/local/bin/chromedriver")
chrome_options = Options()
chrome_options.add_argument('--no-sandbox')
chrome_options.add_argument('--headless')
chrome_options.add_argument('--disable-dev-shm-usage')
driver_path = Service(ChromeDriverManager(chrome_type=ChromeType.CHROMIUM).install())
driver = webdriver.Chrome(service=driver_path, options=chrome_options)

website = "https://public.tableau.com/app/discover"

try:
    driver.get(website)
    wait = WebDriverWait(driver, 10)

    # Verify page load (example: check for a specific element or title)
    try:
        wait.until(EC.element_to_be_clickable((By.XPATH,"//*[@id='root']/div/header/div/div[2]/div/div/img",))).click()
        print("::notice::Successfully navigated to website.")
        print(f"::notice::Page title: {driver.title}")
    except Exception as element_error:
        print(f"::error::Page load verification failed: {element_error}")
        sys.exit(1) #indicate failure.

except Exception as e:
    print(f"::error::Failed to navigate to website: {e}")
    sys.exit(1) #indicate failure.

finally:
    if 'driver' in locals():
        driver.quit()

sys.exit(0) #indicate success.
