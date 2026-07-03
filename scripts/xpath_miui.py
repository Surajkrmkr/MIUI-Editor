
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.common.exceptions import TimeoutException
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
fileDrag = "/html/body/div[3]/div/div[2]/div/div[1]/div/div[2]/div[1]/input"
desc = "//textarea[contains(@placeholder,'Describe this theme')]"
tags = "//input[contains(@placeholder,'tags')]"
tagError = "//div[contains(text(),'no such')]"
copyrightFile = "//input[contains(@accept,'.zip')]"
finalBtn = "//span[contains(@slot,'footer')]/button"

# ── Update Theme flow ────────────────────────────────────────────────────────

searchInput = "/html/body/div[1]/section/div[2]/div[1]/div[1]/div/div[2]/div/div/input" 
themeCardByName = "//p[contains(.,'{name}')]"  # clickable card/title for a theme in the search results; use {name}
withdrawBtn = "//button[.//span[contains(text(),'Withdraw')]]" 
withdrawConfirmBtn = "/html/body/div[1]/section/div[2]/div/div[2]/div[1]/div[4]/div/div[3]/span/button[2]"
updateBtn = "//button[.//span[contains(text(),'Update')]]" 
updateHyperOS3File = "(//strong[normalize-space(text())='Xiaomi HyperOS 3']/following::input[@type='file'])[1]"
whatsNew = "//div[@role='dialog' and @aria-label='Update']//div[contains(@class,'product-info-form')]//textarea"
removeOneTag = "//div[contains(@class,'select-tags')]//span[contains(@class,'select-tags-item') and contains(normalize-space(.), 'Suraj')]/i[contains(@class,'el-tag__close')]"
updateConfirmBtn = "//div[@role='dialog' and @aria-label='Update']//button[.//span[normalize-space(.)='Submit']]"


def uploadSingleMtz(webBrowser, wait, file: str, base_path: str, description: str):
    sep = data.get_Path_Separator()
    tag_path       = data.get_Tag_Path(base_path.replace("/V2", ""))
    copyright_path = data.get_Copyright_Path(base_path.replace("/V2", ""))

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


def _searchTheme(webBrowser, themes_url: str, theme_name: str) -> bool:
    """Search for `theme_name` on the Manage Themes page and click into its
    detail page. Returns False if no matching card shows up (new theme)."""
    # The tab is already navigated to `themes_url` by the caller (see
    # script_update.py); re-navigating here would restart that page load
    # right on top of it and could eat into the search-input wait below.
    if webBrowser.current_url.split("?")[0] != themes_url.split("?")[0]:
        webBrowser.get(themes_url)

    short_wait = WebDriverWait(webBrowser, 30)
    short_wait.until(EC.presence_of_element_located((By.XPATH, searchInput)))
    search_box = webBrowser.find_element(By.XPATH, searchInput)
    search_box.clear()
    search_box.send_keys(theme_name)
    search_box.send_keys(Keys.ENTER)
    time.sleep(2)

    card_xpath = themeCardByName.format(name=theme_name)
    try:
        short_wait.until(EC.presence_of_element_located((By.XPATH, card_xpath)))
    except TimeoutException:
        return False

    webBrowser.find_element(By.XPATH, card_xpath).click()
    return True


def updateSingleMtz(webBrowser, wait, file: str, v2_path: str, description: str,
                     home_url: str, themes_url: str):
    """Search a theme by name, then withdraw+resubmit (pending) or update
    (released) with the matching file from `v2_path`. If no theme with that
    name exists yet, upload it as a fresh submission instead."""
    sep = data.get_Path_Separator()
    theme_name = file.replace(".mtz", "")

    print(f"[UPDATE] Searching for theme: {theme_name}", flush=True)
    found = _searchTheme(webBrowser, themes_url, theme_name)

    if not found:
        print(f"[UPDATE] '{theme_name}' not found, uploading as a fresh theme...", flush=True)
        webBrowser.get(home_url)
        uploadSingleMtz(webBrowser, wait, file, v2_path, description)
        return

    # Wait for the detail page to settle on either the "pending" (Withdraw)
    # or "released" (Update) state before branching, since checking right
    # after the click can race the SPA route transition.
    status_wait = WebDriverWait(webBrowser, 15)
    try:
        status_wait.until(lambda d: d.find_elements(By.XPATH, withdrawBtn)
                           or d.find_elements(By.XPATH, updateBtn))
    except TimeoutException:
        pass

    is_pending = bool(webBrowser.find_elements(By.XPATH, withdrawBtn))

    if is_pending:
        print(f"[UPDATE] '{theme_name}' is pending review, withdrawing...", flush=True)
        webBrowser.find_element(By.XPATH, withdrawBtn).click()

        wait.until(EC.presence_of_element_located((By.XPATH, withdrawConfirmBtn)))
        webBrowser.find_element(By.XPATH, withdrawConfirmBtn).click()
        time.sleep(2)

        print(f"[UPDATE] Resubmitting '{theme_name}' as a fresh upload...", flush=True)
        webBrowser.get(home_url)
        uploadSingleMtz(webBrowser, wait, file, v2_path, description)
        return

    print(f"[UPDATE] '{theme_name}' is released, using Update flow...", flush=True)
    wait.until(EC.presence_of_element_located((By.XPATH, updateBtn)))
    webBrowser.find_element(By.XPATH, updateBtn).click()

    print(f"[UPDATE] Attaching HyperOS 3 file: {file}", flush=True)
    wait.until(EC.presence_of_element_located((By.XPATH, updateHyperOS3File)))
    webBrowser.find_element(By.XPATH, updateHyperOS3File).send_keys(v2_path + sep + file)
    time.sleep(3)

    print(f"[UPDATE] Filling what's new for: {theme_name}", flush=True)
    # Wait briefly for the field to render; skip if it never shows up.
    try:
        WebDriverWait(webBrowser, 10).until(
            EC.presence_of_element_located((By.XPATH, whatsNew)))
        webBrowser.find_element(By.XPATH, whatsNew).send_keys("Bugs & issues fixed")
    except TimeoutException:
        pass

    print(f"[UPDATE] Removing a tag for: {theme_name}", flush=True)
    # Wait briefly for the tag to render; skip if there's none to remove.
    try:
        WebDriverWait(webBrowser, 10).until(
            EC.presence_of_element_located((By.XPATH, removeOneTag)))
        webBrowser.find_element(By.XPATH, removeOneTag).click()
    except TimeoutException:
        pass

    print(f"[UPDATE] Confirming update for: {theme_name}", flush=True)
    wait.until(EC.presence_of_element_located((By.XPATH, updateConfirmBtn)))
    webBrowser.find_element(By.XPATH, updateConfirmBtn).click()
