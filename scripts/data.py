import platform

isMac     = platform.system() == 'Darwin'
isWindows = platform.system() == 'Windows'


def get_Chrome_Path():
    if isMac:
        return "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    elif isWindows:
        return "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
    return ""


def get_Chrome_Selenium_Profile_Dir():
    import os
    if isMac:
        return os.path.expanduser("~/.miui-editor-chrome-profile")
    elif isWindows:
        return os.path.join(os.environ.get("USERPROFILE", ""), ".miui-editor-chrome-profile")
    return ""


def get_Path_Separator():
    return "\\" if isWindows else "/"


def get_Tag_Path(base_path: str) -> str:
    sep = get_Path_Separator()
    return base_path + sep + "1tags" + sep


def get_Copyright_Path(base_path: str) -> str:
    sep = get_Path_Separator()
    return base_path + sep + "1copyright" + sep
