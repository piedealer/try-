from pyautogui import *
import pyautogui
import time
import keyboard
import random
import win32api, win32con
import time



while 1:
    
    if pyautogui.locateOnScreen('pic.png', confidence=0.8) != None:
        time.sleep(10)
#Locate bot window
        print("I will try locate the stop bot now")
        if pyautogui.locateOnScreen('stop.png', confidence=0.9) != None:
            x, y = pyautogui.locateCenterOnScreen('stop.png', confidence=0.9)
#Stop the bot
            print("Lets stop the bot")
            pyautogui.moveTo(x, y, duration=1)
            pyautogui.click()
            print("I should have pressed stop bot")
            time.sleep(5)
#Dissmiss the error message
        print("Time to dismiss error")
        if pyautogui.locateOnScreen('Error Alt.png', confidence=0.9) != None:
            x, y = pyautogui.locateCenterOnScreen('Error Alt.png', confidence=0.9)
            pyautogui.moveTo(x, y, duration=1)
            pyautogui.click()
        time.sleep(3)
        print("Pressing Alt also just incase")
        pyautogui.press('altleft')
#Move to the the Password Field
        print("Move to password field")
        if pyautogui.locateOnScreen('password.png', confidence=0.9) != None:
            x, y = pyautogui.locateCenterOnScreen('password.png', confidence=0.9)
            pyautogui.moveTo(x, y, duration=1)
            pyautogui.click()
        time.sleep(3)
#Enter the password
        print("Entering Password")
        pyautogui.typewrite('Kostamosta00!!')
        time.sleep(3)
        pyautogui.press('enter')
#Sleep for enough time to log in in char select screen
        print("I will now wait to load up character select screen. This will work only if Templar")
        time.sleep(120)
        if pyautogui.locateOnScreen('Templar.png', confidence=0.8) != None:
            time.sleep(10)
        
#Dismiss event window if there is one
        #print("Closing potential event windows")
        #pyautogui.press('E')
                   
#Select the character
            print("We are on character select screen. Will try to load up char.")
            x, y = pyautogui.locateCenterOnScreen('Templar.png', confidence=0.9)
            pyautogui.moveTo(x, y, duration=1)
            pyautogui.click()
            pyautogui.press('enter')
            time.sleep(120)
            if pyautogui.locateOnScreen('Templar.png', confidence=0.8) != None:
                time.sleep(10)
                print("We are on character select screen. Will try to load up char.")
                x, y = pyautogui.locateCenterOnScreen('Templar.png', confidence=0.9)
                pyautogui.moveTo(x, y, duration=1)
                pyautogui.click()
                pyautogui.press('enter')
#Close up Notifiucation
        print("We should be in game by now. I will look for the notifications and close them.")
        if pyautogui.locateOnScreen('notification.png', confidence=0.8) != None:
            pyautogui.press('altleft')
            time.sleep(3)
            pyautogui.press('E')
            time.sleep(3)

#Free mouse from game
        pyautogui.press('Esc')
        time.sleep(3)

#Locate bot window
        print("I will try locate the start buttin now")
        if pyautogui.locateOnScreen('start.png', confidence=0.9) != None:
            x, y = pyautogui.locateCenterOnScreen('start.png', confidence=0.9)
#Start the bot
            print("Lets start the bot")
            pyautogui.moveTo(x, y, duration=1)
            pyautogui.click()
        
            print("I should have pressed start bot")
            time.sleep(5)

        print("Relog should be succesfull")
        time.sleep(0.5)
        
    else:
        print("I am playing")
        time.sleep(60)