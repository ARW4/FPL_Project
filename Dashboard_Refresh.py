#pip install selenium
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from webdriver_manager.core.os_manager import ChromeType
from selenium.webdriver.chrome.options import Options
import os
import time

#https://sites.google.com/chromium.org/driver/

# Ensure that the driver .exe file is saved in the some directory as the code
#service = Service(executable_path="chromedriver.exe")
#driver = webdriver.Chrome(service=service)
chrome_options = Options()
chrome_options.add_argument('--no-sandbox')
chrome_options.add_argument('--headless')
chrome_options.add_argument('--disable-dev-shm-usage')
driver_path = Service(ChromeDriverManager(chrome_type=ChromeType.CHROMIUM).install())
driver = webdriver.Chrome(service=driver_path, options=chrome_options)

driver.maximize_window()

# URL to navigate to
website = "https://public.tableau.com/app/profile/alexrwood/viz/FPLDashboard_17254712584930/FPL-Standings"
driver.get(website)

# Create delay until element is an option
wait = WebDriverWait(driver, 30)

# Click on Reject Cookies
wait.until(
    EC.element_to_be_clickable(
        (
            By.XPATH,
            "//*[@id='onetrust-reject-all-handler']",
        )
    )
).click()

# Click on Sign in button
wait.until(
    EC.element_to_be_clickable(
        (
            By.XPATH,
            "//*[@id='root']/div/header/div/div[2]/div/button",
        )
    )
).click()

# Type in email
input_element = driver.find_element(By.XPATH, "//*[@id='email']")
input_element.send_keys ("alexrobinwood@icloud.com")

# Type in password
input_element = driver.find_element(By.XPATH, "//*[@id='password']")
input_element.send_keys ("tovdod-zafXaj-4kokwu")
#wait.until(EC.text_to_be_present_in_element((By.XPATH, "//*[@id='password']"), "tovdod-zafXaj-4kokwu"))

# Click signin button
input_element = driver.find_element(By.XPATH, "//*[@id='signInButton']")
input_element.click()

# Click profile avatar
wait.until(
    EC.element_to_be_clickable(
        (
            By.XPATH,
            "//*[@id='root']/div/header/div/div[2]/div/div/img",
        )
    )
).click()

# Click my profile
wait.until(
    EC.element_to_be_clickable(
        (
            By.XPATH,
            "//*[@id='vizCardMenu']/ul/li[1]/div/span",
        )
    )
).click()

# Click dashboard
wait.until(
    EC.element_to_be_clickable(
        (
            By.XPATH,
            "//*[@id='root']/div/div[4]/div[3]/div/div/div/div/div[1]/div[1]/div/div/a/img",
        )
    )
).click()

# Click refresh data button
wait.until(
    EC.element_to_be_clickable(
        (
            By.XPATH,
            "//*[@id='root']/div/div[4]/div[3]/div[2]/div[2]/div[2]/button",
        )
    )
).click()

time.sleep(20)

#close down the browser#
driver.quit()
