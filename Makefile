#
# Makefile - murgaLua Makefile
#
# Copyright (C) 2006-12 John Murga
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the :
# 
#   Free Software Foundation, Inc.
#   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

PLAT  = none
PLATS = linux linuxStatic windows macos unix

all:	$(PLAT)

$(PLATS) clean:
	cd src && $(MAKE) $@

none:
	@echo ""
	@echo "Please do"
	@echo "   make PLATFORM"
	@echo "where PLATFORM is one of these:"
	@echo "   $(PLATS)"
	@echo ""
