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

try:  # Overall try-except block
    # Step 1: "Navigate to Dashboard"
    try:
        driver.get(dashboard)
        print("Step 1: Dashboard opened.")
    except Exception as e:
        print(f"Step 1 failed {str(e)}")
        raise  # Raise the exception to be caught by the outer try-except

    # Step 2: Click "Accept Cookies"
    try:
        wait.until(
            EC.element_to_be_clickable(
                (By.ID, "onetrust-accept-btn-handler")
            )
        ).click()
        print("Step 2: Cookies accepted.")
    except Exception as e:
        print(f"Step 2 failed {str(e)}")
        raise  # Raise the exception to be caught by the outer try-except

    # ... (rest of the steps) ...

    # Step 10: Quit the driver
    try:
        driver.quit()
        print("Step 10: Driver quit successfully.")
    except Exception as e:
        print(f"Step 10 failed {str(e)}")
        raise  # Raise the exception to be caught by the outer try-except

except Exception as overall_e:  # Overall exception handling
    print(f"An overall error occurred: {overall_e}")
    if 'driver' in locals():
        driver.quit()  # Ensure driver closes even if there is an error

finally:  # Finally block for cleanup
    try:
        shutil.rmtree(temp_user_data_dir)  # Remove the temporary directory
        print("Temporary directory removed.")
    except OSError as e:
        print(f"Error removing temporary directory: {e.filename} - {e.strerror}")
