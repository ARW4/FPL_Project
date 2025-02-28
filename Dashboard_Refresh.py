# Import modules and packages
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from webdriver_manager.core.os_manager import ChromeType
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
import time
import os

# Set driver
chrome_options = Options()
chrome_options.add_argument('--headless')  # Example: Headless mode
driver_path = Service(ChromeDriverManager(chrome_type=ChromeType.CHROMIUM).install())
driver = webdriver.Chrome(service=driver_path, options=chrome_options)

# Setting the wait function
wait = WebDriverWait(driver,20)

# provide website
website = "https://public.tableau.com/app/discover"
dashboard = "https://public.tableau.com/app/profile/alexrwood/viz/FPLDashboard_17254712584930/FPL-Standings"

driver.get(website)

# Click on accept cookies in button
wait.until(
    EC.element_to_be_clickable(
        (By.ID,
         "onetrust-accept-btn-handler",
         )
    )
).click()

# Click Signin button
wait.until(
    EC.element_to_be_clickable(
        (By.CSS_SELECTOR,
         '[data-testid="AuthSection-sign-in-button"]',
         )
    )
).click()


# Enter Email
input_element = driver.find_element(By.ID, "email")
environ_email = os.environ["TABLEAU_EMAIL"]
input_element.send_keys (environ_email)

# Enter Password
input_element = driver.find_element(By.ID, "password ")
environ_email = os.environ["TABLEAU_EMAIL"]
input_element.send_keys (environ_email)

# Click on accept cookies in button
wait.until(
    EC.element_to_be_clickable(
        (By.ID,
         "signInButton",
         )
    )
).click()

driver.get(dashboard)

# Click Refresh button
wait.until(
    EC.element_to_be_clickable(
        (By.CSS_SELECTOR,
         'button[aria-label="Request Data Refresh"]',
         )
    )
).click()

time.sleep(20)

driver.quit()
