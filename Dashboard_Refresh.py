# Import modules and packages
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
import time
import os
import tempfile
import shutil

# Set Driver
chrome_options = Options()
chrome_options.add_argument("--headless")
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")
chrome_options.add_argument("--remote-debugging-port=9222")

# Create a temporary directory for user data
temp_user_data_dir = tempfile.mkdtemp()
chrome_options.add_argument(f"--user-data-dir={temp_user_data_dir}")

# Initialize the WebDriver
driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=chrome_options)

# Maximize Window
driver.maximize_window()

# Setting the wait function
wait = WebDriverWait(driver, 20)

# Provide website
dashboard = "https://public.tableau.com/app/profile/alexrwood/viz/FPLDashboard_17254712584930/FPL-Standings"

# Step 1: "Navigate to Dashboard"
try:
    driver.get(dashboard)
    print("Step 1: Dashboard opened.")
except Exception as e:
    print(f"Step 1 failed {str(e)}")
    driver.quit()
    exit()

# Step 1.2: Click "Accept Cookies" -- Only need this step if running on local device
#wait.until(
#    EC.element_to_be_clickable(
#        (By.ID, "onetrust-accept-btn-handler")
#    )
#).click()
#print("Step 1.2: Cookies accepted.")

# Step 2: Click Sign-In button

wait.until(
    EC.element_to_be_clickable(
        (By.CSS_SELECTOR, '[data-testid="AuthSection-sign-in-button"]')
    )
).click()
print("Step 2: Sign-In button clicked.")

# Step 3: Enter Email
input_element = driver.find_element(By.ID, "email")
environ_email = os.environ["TABLEAU_EMAIL"]
input_element.send_keys(environ_email)
print("Step 3: Email entered.")

# Step 4: Enter Password
input_element = driver.find_element(By.ID, "password")
environ_password = os.environ["TABLEAU_PASSWORD"]
input_element.send_keys(environ_password)
print("Step 4: Password entered.")

# Step 5: Click remember me button
wait.until(
     EC.element_to_be_clickable(
         (By.ID, "rememberCheckbox")
     )
).click()
print("Step 5: Sign-In submitted.")

# Step 6: Click Sign-In button to submit
wait.until(
      EC.element_to_be_clickable(
         (By.ID, "signInButton")
      )
   ).click()
print("Step 6: Sign-In submitted.")

# Step 7: Click on the "Request Data Refresh" button
wait.until(
     EC.element_to_be_clickable(
        (By.CSS_SELECTOR, 'button[aria-label="Request Data Refresh"]')
    )
).click()
print("Step 7: Data refresh button clicked.")

# Step 8: Wait for some time to allow the data refresh to process
time.sleep(20)
print("Step 8: Waited for 20 seconds.")

# Step 10: Quit the driver
driver.quit()
print("Step 10: Driver quit successfully.")
