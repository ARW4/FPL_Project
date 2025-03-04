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
import tempfile  # Importing the tempfile module
import shutil  # Importing the shutil module

# Set Driver
chrome_options = Options()
chrome_options.add_argument("--headless")
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")
chrome_options.add_argument("--remote-debugging-port=9222")  # Adding a port for remote debugging

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
website = "https://public.tableau.com/app/discover"
dashboard = "https://public.tableau.com/app/profile/alexrwood/viz/FPLDashboard_17254712584930/FPL-Standings"

# Step 1: "Navigate to Dashboard"
try:
    driver.get(dashboard)
    print("Step 1: Dashboard opened.")
except Exception as e:
    print(f"Step 1 failed {str(e)}")
    driver.quit()
    exit()

# Step 2: Click "Accept Cookies"
#try:
#    wait.until(
#        EC.element_to_be_clickable(
#            (By.ID, "onetrust-accept-btn-handler")
#        )
#    ).click()
#    print("Step 2: Cookies accepted.")
#except Exception as e:
#    print(f"Step 2 failed {str(e)}")
#    driver.quit()
#    exit()

# Step 3: Click Sign-In button
try:
    wait.until(
        EC.element_to_be_clickable(
            (By.CSS_SELECTOR, '[data-testid="AuthSection-sign-in-button"]')
        )
    ).click()
    print("Step 3: Sign-In button clicked.")
except Exception as e:
    print(f"Step 3 failed {str(e)}")
    driver.quit()
    exit()

# Step 4: Enter Email
try:
    input_element = driver.find_element(By.ID, "email")
    environ_email = os.environ["TABLEAU_EMAIL"]
    input_element.send_keys(environ_email)
    print("Step 4: Email entered.")
except Exception as e:
    print(f"Step 4 failed {str(e)}")
    driver.quit()
    exit()

# Step 5: Enter Password
try:
    input_element = driver.find_element(By.ID, "password")
    environ_password = os.environ["TABLEAU_PASSWORD"]
    input_element.send_keys(environ_password)
    print("Step 5: Password entered.")
except Exception as e:
    print(f"Step 5 failed {str(e)}")
    driver.quit()
    exit()

# Step 6: Click remember me button
try:
    wait.until(
        EC.element_to_be_clickable(
            (By.ID, "rememberCheckbox")
        )
    ).click()
    print("Step 6: Sign-In submitted.")
except Exception as e:
    print(f"Step 6 failed {str(e)}")
    driver.quit()
    exit()

# Step 7: Click Sign-In button to submit
try:
    wait.until(
        EC.element_to_be_clickable(
            (By.ID, "signInButton")
        )
    ).click()
    print("Step 7: Sign-In submitted.")
except Exception as e:
    print(f"Step 7 failed {str(e)}")
    driver.quit()
    exit()

# Step 8: Click on the "Request Data Refresh" button
try:
    wait.until(
        EC.element_to_be_clickable(
            (By.CSS_SELECTOR, 'button[aria-label="Request Data Refresh"]')
        )
    ).click()
    print("Step 8: Data refresh button clicked.")
except Exception as e:
    print(f"Step 8 failed {str(e)}")
    driver.quit()
    exit()

# Step 9: Wait for some time to allow the data refresh to process
try:
    time.sleep(20)
    print("Step 9: Waited for 20 seconds.")
except Exception as e:
    print(f"Step 9 failed {str(e)}")
    driver.quit()
    exit()

# Step 10: Quit the driver
try:
    driver.quit()
    print("Step 10: Driver quit successfully.")
except Exception as e:
    print(f"Step 10 failed {str(e)}")
    driver.quit()
    exit()
