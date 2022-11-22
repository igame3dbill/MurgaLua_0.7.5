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

class Fl_murgaLuaTimer : public Fl_Widget
{
  char active;
  static void stepcb(void *);
public:
  virtual void draw();
  Fl_murgaLuaTimer(int X, int Y, int W, int H, const char *l);
  ~Fl_murgaLuaTimer();
  void doWait(double);
  char isActive();
};
