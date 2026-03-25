
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
import time
import data

# signIn = "//*[@id=\"app\"]/div/div[2]/div/button[1]"
signIn = "/html/body/div[1]/section/div[1]/div[1]/div[2]/button"
signInUsingPw = "//*[@id='rc-tabs-0-panel-login']/form/div[1]/div[3]/div/a"
emailId = "//input[@name='account']"
pw = "password"
agree = "/html/body/div[1]/div/div/div[2]/div[1]/div/div[2]/div/div[2]/div/div[2]/div/div[1]/form/div[1]/div[3]/label/span[1]/input"
submit = "//button[@type='submit']"
sendEmail = "/html/body/div[1]/div/div/div/div/div/div/div/div/div/div/form/div[2]/div/button"
submitBtn = "//*[@id=\"app\"]/section/div[2]/div[1]/div[1]/div/div[2]/button"
cookieBtn = "//*[@id=\"__cookie_tip\"]/div"
dialogOkBtn = '//*[@id="app"]/section/div[2]/div[2]/div/div[3]/div/button'
fileDrag = "/html/body/div[3]/div/div[2]/div/div[1]/div/div[1]/div[1]/input"
desc = "//textarea[contains(@placeholder,'Describe this theme')]"
tags = "//input[contains(@placeholder,'tags')]"
tagError = "//div[contains(text(),'no such')]"
copyrightFile = "//input[contains(@accept,'.zip')]"
finalBtn = "//span[contains(@slot,'footer')]/button"


def uploadSingleMtz(webBrowser, wait, file: str, base_path: str, description: str):
    sep = data.get_Path_Separator()
    tag_path       = data.get_Tag_Path(base_path)
    copyright_path = data.get_Copyright_Path(base_path)

    time.sleep(3)
    print(f"[UPLOAD] Clicking submit button for: {file}", flush=True)
    wait.until(EC.presence_of_element_located((By.XPATH, submitBtn)))
    webBrowser.execute_script(
        "arguments[0].click();", webBrowser.find_element(By.XPATH, submitBtn))

    time.sleep(3)
    print(f"[UPLOAD] Attaching .mtz file: {file}", flush=True)
    wait.until(EC.presence_of_element_located((By.XPATH, fileDrag)))
    webBrowser.find_element(By.XPATH, fileDrag).send_keys(
        base_path + sep + file)

    print(f"[UPLOAD] Filling description...", flush=True)
    wait.until(EC.presence_of_element_located((By.XPATH, desc)))
    webBrowser.find_element(By.XPATH, desc).send_keys(description)

    webBrowser.execute_script("scroll(350, 0)")

    print(f"[UPLOAD] Attaching copyright file: {file.replace('.mtz', '.zip')}", flush=True)
    webBrowser.find_element(By.XPATH, copyrightFile).send_keys(
        copyright_path + file.replace(".mtz", ".zip"))

    time.sleep(5)

    print(f"[UPLOAD] Adding tags for: {file}", flush=True)
    while True:
        webBrowser.find_element(By.XPATH, tags).clear()
        tag_file = tag_path + file.replace(".mtz", ".txt")
        with open(tag_file) as f:
            line = f.read().split(",")
        for tag in line:
            webBrowser.find_element(By.XPATH, tags).send_keys(tag)
            time.sleep(2)
            webBrowser.find_element(By.XPATH, tags).send_keys(Keys.ENTER)
        try:
            webBrowser.find_element(By.XPATH, tagError)
            print(f"[WARN] Tag error detected, retrying tags...", flush=True)
        except Exception:
            break

    print(f"[UPLOAD] Submitting final form for: {file}", flush=True)
    webBrowser.find_element(By.XPATH, finalBtn).click()
