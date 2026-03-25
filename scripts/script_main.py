import argparse
import os
import sys
import time

import data
import xpath_miui
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait


def log(tag, msg):
    print(f"[{tag}] {msg}", flush=True)


def main():
    parser = argparse.ArgumentParser(description="MIUI Theme Deployment Automation")
    parser.add_argument("--base-path",    required=True,              help="Path to folder containing .mtz files")
    parser.add_argument("--max-tab",      type=int, default=9,        help="Max browser tabs per batch (default: 9)")
    parser.add_argument("--email",        required=True,              help="Login email or phone number")
    parser.add_argument("--password",     required=True,              help="Login password")
    parser.add_argument("--description",  default="",                 help="Theme description text")
    args = parser.parse_args()

    base_path   = args.base_path
    max_tab     = args.max_tab
    description = args.description

    # ── Print run config ───────────────────────────────────────────────────────
    log("CONFIG", f"Base Path   : {base_path}")
    log("CONFIG", f"Max Tabs    : {max_tab}")
    log("CONFIG", f"Email       : {args.email}")
    log("CONFIG", f"Description : {description or '(none)'}")
    print(flush=True)

    # ── Scan for .mtz files ────────────────────────────────────────────────────
    log("SCAN", f"Scanning for .mtz files in: {base_path}")
    mtz_list = []
    for (root, dirs, files) in os.walk(base_path):
        for f in files:
            if f.endswith(".mtz"):
                mtz_list.append(f)
    mtz_list.sort()

    if not mtz_list:
        log("ERROR", "No .mtz files found in the given path. Aborting.")
        sys.exit(1)

    log("SCAN", f"Found {len(mtz_list)} .mtz file(s):")
    for f in mtz_list:
        log("SCAN", f"  -> {f}")
    print(flush=True)

    # ── Build upload batches ───────────────────────────────────────────────────
    sequence_list = []
    count = len(mtz_list) // max_tab
    if len(mtz_list) % max_tab != 0:
        count += 1
    for i in range(count):
        sequence_list.append(mtz_list[i * max_tab:(i + 1) * max_tab])

    log("BATCH", f"Total files  : {len(mtz_list)}")
    log("BATCH", f"Batch count  : {count}")
    log("BATCH", f"Max per batch: {max_tab}")
    print(flush=True)

    # ── Launch browser ─────────────────────────────────────────────────────────
    brave_path = data.get_Brave_Path()
    log("BROWSER", f"Launching Brave: {brave_path}")
    options = Options()
    options.binary_location = brave_path
    options.add_experimental_option("excludeSwitches", ["enable-logging"])
    web_browser = webdriver.Chrome(options=options)
    web_browser.maximize_window()
    log("BROWSER", "Browser window opened")

    home_url = "https://in.zhuti.designer.intl.xiaomi.com/"
    log("BROWSER", f"Navigating to: {home_url}")
    web_browser.get(home_url)

    wait = WebDriverWait(web_browser, 300)

    # ── Login ──────────────────────────────────────────────────────────────────
    log("LOGIN", "Waiting for sign-in button...")
    wait.until(EC.presence_of_element_located((By.XPATH, xpath_miui.signIn)))
    web_browser.find_element(By.XPATH, xpath_miui.signIn).click()

    log("LOGIN", "Entering credentials...")
    wait.until(EC.presence_of_element_located((By.XPATH, xpath_miui.emailId)))
    web_browser.find_element(By.XPATH, xpath_miui.emailId).send_keys(args.email)
    wait.until(EC.presence_of_element_located((By.NAME, xpath_miui.pw)))
    web_browser.find_element(By.NAME, xpath_miui.pw).send_keys(args.password)
    wait.until(EC.presence_of_element_located((By.XPATH, xpath_miui.agree)))
    web_browser.find_element(By.XPATH, xpath_miui.agree).click()

    log("LOGIN", "Submitting login form...")
    wait.until(EC.presence_of_element_located((By.XPATH, xpath_miui.submit)))
    web_browser.find_element(By.XPATH, xpath_miui.submit).click()

    log("LOGIN", "Waiting for 2FA code entry...")
    wait.until(EC.presence_of_element_located((By.XPATH, xpath_miui.sendEmail)))
    web_browser.find_element(By.XPATH, xpath_miui.sendEmail).click()

    wait.until(EC.presence_of_element_located((By.XPATH, xpath_miui.cookieBtn)))
    web_browser.find_element(By.XPATH, xpath_miui.cookieBtn).click()
    log("LOGIN", "Handling post-login dialogs...")
    wait.until(EC.presence_of_element_located((By.XPATH, xpath_miui.dialogOkBtn)))
    web_browser.find_element(By.XPATH, xpath_miui.dialogOkBtn).click()

    log("LOGIN", "Again navigating to landing page...")
    web_browser.get(home_url)

    log("LOGIN", "Login successful!")
    print(flush=True)

    main_window = web_browser.current_window_handle
    total    = len(mtz_list)
    uploaded = 0

    # ── Upload batches ─────────────────────────────────────────────────────────
    for i, batch in enumerate(sequence_list):
        log("UPLOAD", f"---- Batch {i + 1}/{len(sequence_list)} | {len(batch)} file(s) ----")

        # Open one tab per file in this batch
        for j in range(len(batch)):
            web_browser.execute_script(f"window.open('about:blank',{j});")
            web_browser.switch_to.window(str(j))
            web_browser.get(home_url)
            log("UPLOAD", f"Tab {j + 1} ready")

        # Upload each file
        for j, mtz_file in enumerate(batch):
            uploaded += 1
            log("UPLOAD", f"({uploaded}/{total}) Uploading: {mtz_file}")
            web_browser.switch_to.window(str(j))
            xpath_miui.uploadSingleMtz(
                web_browser, wait, mtz_file, base_path, description
            )
            log("OK", f"({uploaded}/{total}) Done: {mtz_file}")
            time.sleep(3)
            web_browser.close()

        web_browser.switch_to.window(main_window)
        log("UPLOAD", f"Batch {i + 1} complete")
        print(flush=True)

    # ── Finish ─────────────────────────────────────────────────────────────────
    log("DONE", f"All {total} theme(s) uploaded successfully!")
    web_browser.switch_to.window(main_window)
    web_browser.close()
    log("DONE", "Browser closed. Deployment finished.")


if __name__ == "__main__":
    main()
