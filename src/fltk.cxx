/*

  murgaLua
  Copyright (C) 2006-12 John Murga
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the :
  
    Free Software Foundation, Inc.
    51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
  
*/

#include <stdlib.h>

#include <FL/Fl.h>
#include <FL/Fl_Adjuster.h>
#include <FL/Fl_BMP_Image.h>
#include <FL/Fl_Bitmap.h>
#include <FL/Fl_Box.h>
#include <FL/Fl_Browser.h>
#include <FL/Fl_Browser_.h>
#include <FL/Fl_Button.h>
#include <FL/Fl_Chart.h>
#include <FL/Fl_Check_Browser.h>
#include <FL/Fl_Check_Button.h>
#include <FL/Fl_Choice.h>
#include <FL/Fl_Clock.h>
#include <FL/Fl_Color_Chooser.h>
#include <FL/Fl_Counter.h>
#include <FL/Fl_Dial.h>
#include <FL/Fl_Double_Window.h>
#include <FL/Fl_File_Browser.h>
#include <FL/Fl_File_Chooser.h>
#include <FL/Fl_File_Icon.h>
#include <FL/Fl_File_Input.h>
#include <FL/Fl_Fill_Dial.h>
#include <FL/Fl_Fill_Slider.h>
#include <FL/Fl_Float_Input.h>
#include <FL/Fl_FormsBitmap.h>
#include <FL/Fl_FormsPixmap.h>
#include <FL/Fl_GIF_Image.h>
#include <FL/Fl_Group.h>
#include <FL/Fl_Help_Dialog.h>
#include <FL/Fl_Help_View.h>
#include <FL/Fl_Hold_Browser.h>
#include <FL/Fl_Hor_Fill_Slider.h>
#include <FL/Fl_Hor_Nice_Slider.h>
#include <FL/Fl_Hor_Slider.h>
#include <FL/Fl_Hor_Value_Slider.h>
#include <FL/Fl_Image.h>
#include <FL/Fl_Input.h>
#include <FL/Fl_Input_.h>
#include <FL/Fl_Int_Input.h>
#include <FL/Fl_JPEG_Image.h>
#include <FL/Fl_Light_Button.h>
#include <FL/Fl_Line_Dial.h>
#include <FL/Fl_Menu.h>
#include <FL/Fl_Menu_.h>
#include <FL/Fl_Menu_Bar.h>
#include <FL/Fl_Menu_Button.h>
#include <FL/Fl_Menu_Item.h>
#include <FL/Fl_Menu_Window.h>
#include <FL/Fl_Multi_Browser.h>
#include <FL/Fl_Multi_Label.h>
#include <FL/Fl_Multiline_Input.h>
#include <FL/Fl_Multiline_Output.h>
#include <FL/Fl_Nice_Slider.h>
#include <FL/Fl_Object.h>
#include <FL/Fl_Output.h>
#include <FL/Fl_Overlay_Window.h>
#include <FL/Fl_PNG_Image.h>
#include <FL/Fl_PNM_Image.h>
#include <FL/Fl_Pack.h>
#include <FL/Fl_Pixmap.h>
#include <FL/Fl_Positioner.h>
#include <FL/Fl_Preferences.h>
#include <FL/Fl_Progress.h>
#include <FL/Fl_Radio_Button.h>
#include <FL/Fl_Radio_Light_Button.h>
#include <FL/Fl_Radio_Round_Button.h>
#include <FL/Fl_Repeat_Button.h>
#include <FL/Fl_Return_Button.h>
#include <FL/Fl_Roller.h>
#include <FL/Fl_Round_Button.h>
#include <FL/Fl_Round_Clock.h>
#include <FL/Fl_Scroll.h>
#include <FL/Fl_Scrollbar.h>
#include <FL/Fl_Secret_Input.h>
#include <FL/Fl_Select_Browser.h>
#include <FL/Fl_Shared_Image.h>
#include <FL/Fl_Simple_Counter.h>
#include <FL/Fl_Single_Window.h>
#include <FL/Fl_Slider.h>
#include <FL/Fl_Sys_Menu_Bar.h>
#include <FL/Fl_Tabs.h>
#include <FL/Fl_Text_Buffer.h>
#include <FL/Fl_Text_Display.h>
#include <FL/Fl_Text_Editor.h>
#include <FL/Fl_Tile.h>
#include <FL/Fl_Tiled_Image.h>
#include <FL/Fl_Timer.h>
#include <FL/Fl_Toggle_Button.h>
#include <FL/Fl_Toggle_Light_Button.h>
#include <FL/Fl_Toggle_Round_Button.h>
#include <FL/Fl_Tooltip.h>
#include <FL/Fl_Valuator.h>
#include <FL/Fl_Value_Input.h>
#include <FL/Fl_Value_Output.h>
#include <FL/Fl_Value_Slider.h>
#include <FL/Fl_Widget.h>
#include <FL/Fl_Window.h>
#include <FL/Fl_Wizard.h>
#include <FL/Fl_XBM_Image.h>
#include <FL/Fl_XPM_Image.h>
#include <FL/dirent.h>
#include <FL/filename.h>
#include <FL/fl_draw.h>
#include <FL/fl_file_chooser.h>
#include <FL/fl_message.h>
#include <FL/fl_show_colormap.h>
#include <FL/fl_show_input.h>

#include <FL/Fl_Spinner.H>
#include <FL/Fl_Input_Choice.H>

#include "Fl_murgaLuaTimer.h"
#include "Fl_murgaLuaOffScreen.h"

#include <FL/Fl_Node.h>
#include <FL/Fl_Tree.h>
#include <FL/Fl_ToggleNode.h>
#include <FL/Fl_ToggleTree.h>
/* #include "Fl_murgaLuaSound.h" */
