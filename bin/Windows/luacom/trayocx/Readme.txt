
IDI Tray Control v1.0
Copyright (c) 1999 - SpectSoft

--------------------------
I. Pseudo-Freeware Notice.

This software is limited to "non-profit" or evaluation use. By "non-profit" we mean that as soon as you earn money by using this software, you have to register it! This allows anybody who wishes to use this software for their private hobby projects to do so. Also students can use this version for any educational projects. It is even ok to use this version in a commercial environment as long as you just want to evaluate the program. As soon as you start using it for commercial projects, you will have to register it.

Registration information is at the bottom of this document.

--------------------------
II. Limitation of Liability

SpectSoft disclaims any liability for damages arising from the use of this product or any other damage, including (but not limited to) lost of revenue or data, special, incidental, or other claims, even if SpectSoft has been specially advised of the possibility of such claims.

--------------------------
III. Now the Cool Stuff!

The Tray control is a very easy to use and easy to implement control.  It is a true 32-bit ActiveX control (OCX) and can be flawlessly brought into most 32-bit development environments.  Included with this software is a Visual Basic 5 sample of how to use this control in your software.  To run the EXE you will need the VB5 runtimes available from ftp://ftp.microsoft.com.

There are few properties with this control; all of them are only available during runtime.

Properties
Add - Add your icon to the system tray.
Delete - Delete your icon on the system tray.
Modify - Modify your currently loaded system tray icon.
SetPicture - Sets the picture location of the icon you will load onto the system tray
SetTip - Sets the Tool Tip of your icon on the system tray.

Events
MouseClick (Button as Integer)


Button breakdown:
0 - Left button is down on tray icon
1 - Right button is down on tray icon.
2 - Left button has double clicked tray icon
3 - Right button has double clicked tray icon.
4 - Right button is up on tray icon
5 - Left button is up on tray icon
6 - Mouse is over the tray icon.

--------------------------
IV. Registration Information

The commercial registration of this software cost is only $10.00, sent to SpectSoft at the following address:

SpectSoft
375 Johnson Ave
Oakdale, CA  95361

You can visit SpectSoft on the World Wide Web at the following address: http://www.spectsoft.com
Or you can email SpectSoft at one of the following address:
Products@spectsoft.com - For information or comments on any of our products
Support@spectsoft.com - For help or to report bugs on any of our software.
Info@spectsoft.com - For general SpectSoft information.
Sales@spectsoft.com - For any sales related questions or comments.

Though only commercial registration is required, donations are always welcome!  I would enjoy hearing what people are using my controls for, feel free to drop me a line.

--------------------------
V. How to Register and OCX with the system.

Before you use this control you must first register with your computer. 

*** Note:  If you have a previous version of tray.ocx registered you must first unregister it with the following command "regsvr32 /u tray.ocx".  Then go ahead with the following.  

1. Move the OCX into the "/windows/system/" directory.
2. From a dos prompt DOS, go to the "/windows/system/" directory.
3. Type the following: "regsvr32 tray.ocx"
4. You will then see a message telling you that the OCX registered correctly.

ActiveX, Visual Basic, and most everything else are trademarks of the Microsoft Corp.
All others are trademarks of their respective companies.
