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
    parser = argparse.ArgumentParser(description="MIUI Theme Update Automation")
    parser.add_argument("--v2-path",      required=True,              help="Path to folder containing V2 .mtz files")
    parser.add_argument("--max-tab",      type=int, default=9,        help="Max browser tabs per batch (default: 9)")
    parser.add_argument("--email",        required=True,              help="Login email or phone number")
    parser.add_argument("--password",     required=True,              help="Login password")
    parser.add_argument("--description",  default="",                 help="Theme description text (used only if a pending theme needs to be resubmitted)")
    args = parser.parse_args()

    v2_path     = args.v2_path
    max_tab     = args.max_tab
    description = args.description

    # ── Print run config ───────────────────────────────────────────────────────
    log("CONFIG", f"V2 Path     : {v2_path}")
    log("CONFIG", f"Max Tabs    : {max_tab}")
    log("CONFIG", f"Email       : {args.email}")
    log("CONFIG", f"Description : {description or '(none)'}")
    print(flush=True)

    # ── Scan for .mtz files ────────────────────────────────────────────────────
    log("SCAN", f"Scanning for .mtz files in: {v2_path}")
    mtz_list = []
    for (root, dirs, files) in os.walk(v2_path):
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

    # ── Build batches ───────────────────────────────────────────────────────────
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
    options.add_argument(f"--user-data-dir={data.get_Brave_Selenium_Profile_Dir()}")
    web_browser = webdriver.Chrome(options=options)
    for handle in web_browser.window_handles[1:]:
        web_browser.switch_to.window(handle)
        web_browser.close()
    web_browser.switch_to.window(web_browser.window_handles[0])
    log("BROWSER", "Browser window opened")

    home_url   = "https://in.zhuti.designer.intl.xiaomi.com/"
    themes_url = "https://in.zhuti.designer.intl.xiaomi.com/?productState=ALL&perPage=30&currentPage=1"
    log("BROWSER", f"Navigating to: {home_url}")
    web_browser.get(home_url)

    wait = WebDriverWait(web_browser, 300)

    # ── Login ──────────────────────────────────────────────────────────────────
    log("LOGIN", "Waiting for sign-in button...")
    wait.until(EC.presence_of_element_located((By.XPATH, xpath_miui.signIn)))
    web_browser.find_element(By.XPATH, xpath_miui.signIn).click()

    log("LOGIN", "Handling post-login dialogs...")
    wait.until(EC.presence_of_element_located((By.XPATH, xpath_miui.dialogOkBtn)))
    web_browser.find_element(By.XPATH, xpath_miui.dialogOkBtn).click()

    log("LOGIN", "Again navigating to landing page...")
    web_browser.get(home_url)
    log("LOGIN", "Login successful!")
    print(flush=True)

    main_window = web_browser.current_window_handle
    total     = len(mtz_list)
    processed = 0

    # ── Process batches ────────────────────────────────────────────────────────
    for i, batch in enumerate(sequence_list):
        log("UPDATE", f"---- Batch {i + 1}/{len(sequence_list)} | {len(batch)} file(s) ----")

        # Open one tab per file in this batch
        for j in range(len(batch)):
            web_browser.execute_script(f"window.open('about:blank',{j});")
            web_browser.switch_to.window(str(j))
            web_browser.get(themes_url)
            log("UPDATE", f"Tab {j + 1} ready")

        # Process each file: search -> withdraw+resubmit, or update
        for j, mtz_file in enumerate(batch):
            processed += 1
            theme_name = os.path.splitext(mtz_file)[0]
            log("UPDATE", f"({processed}/{total}) Processing: {theme_name}")
            web_browser.switch_to.window(str(j))
            xpath_miui.updateSingleMtz(
                web_browser, wait, mtz_file, v2_path, description, home_url, themes_url
            )
            log("OK", f"({processed}/{total}) Done: {theme_name}")
            time.sleep(3)
            web_browser.close()

        web_browser.switch_to.window(main_window)
        log("UPDATE", f"Batch {i + 1} complete")
        print(flush=True)

    # ── Finish ─────────────────────────────────────────────────────────────────
    log("DONE", f"All {total} theme(s) processed successfully!")
    web_browser.switch_to.window(main_window)
    web_browser.close()
    log("DONE", "Browser closed. Update run finished.")


if __name__ == "__main__":
    main()
