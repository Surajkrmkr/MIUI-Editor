import platform

isMac     = platform.system() == 'Darwin'
isWindows = platform.system() == 'Windows'


def get_Brave_Path():
    if isMac:
        return "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
    elif isWindows:
        return "C:\\Program Files\\BraveSoftware\\Brave-Browser\\Application\\brave.exe"
    return ""


def get_Brave_Selenium_Profile_Dir():
    import os
    if isMac:
        return os.path.expanduser("~/.miui-editor-brave-profile")
    elif isWindows:
        return os.path.join(os.environ.get("USERPROFILE", ""), ".miui-editor-brave-profile")
    return ""


def get_Path_Separator():
    return "\\" if isWindows else "/"


def get_Tag_Path(base_path: str) -> str:
    sep = get_Path_Separator()
    return base_path + sep + "1tags" + sep


def get_Copyright_Path(base_path: str) -> str:
    sep = get_Path_Separator()
    return base_path + sep + "1copyright" + sep
