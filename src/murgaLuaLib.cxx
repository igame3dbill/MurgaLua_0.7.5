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
  
  XML Binding code based on code from :

      http://homepage3.nifty.com/akaho/program/lua/xml.html

*/

#include "../3rd-party/tinyxml/tinyxml.h"
#include "murgaLua.h"

#include <string>
#include <sstream>
#include <fstream>

#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <errno.h>

// For time stuff
#ifdef _WIN32
#include <windows.h>
#else
#include <time.h>
#include <sys/time.h>
#endif

using namespace std;
extern "C"
{
  #include "lua.h"
  #include "lualib.h"
  #include "lauxlib.h"

  void replaceInString(char *str, char oldChar, char newChar)
  {
    if (newChar == oldChar) {
        return;
    }
    char *pos = strchr(str, oldChar);
    while (pos != NULL)  {
        *pos = newChar;
        pos = strchr(pos + 1, oldChar);
    }
  }

  /* Converts a hex character to its integer value */
  char from_hex(char ch) {
    return isdigit(ch) ? ch - '0' : tolower(ch) - 'a' + 10;
  }

  /* Converts an integer value to its hex character*/
  char to_hex(char code) {
    static char hex[] = "0123456789abcdef";
    return hex[code & 15];
  }

  /* Returns a url-encoded version of str */
  /* IMPORTANT: be sure to free() the returned string after use */
  char *url_encode(char *str) {
    char *pstr = str;
    char *buf = (char *)malloc(sizeof(char) * (strlen(str)*3+1));
    char *pbuf = buf;
    while (*pstr) {
      if (isalnum(*pstr) || *pstr == '_' || *pstr == '.') /* || *pstr == '-' || *pstr == '~') */
        *pbuf++ = *pstr;
      else if (*pstr == ' ') 
        *pbuf++ = '+';
      else 
        *pbuf++ = '%', *pbuf++ = to_hex(*pstr >> 4), *pbuf++ = to_hex(*pstr & 15);
      pstr++;
    }
    *pbuf = '\0';
    return buf;
  }

  /* Returns a url-decoded version of str */
  char *url_decode(char *str) {
    char *pstr = str;
    char *buf = (char *)malloc(sizeof(char) * (strlen(str)+1));
    char *pbuf = buf;
    while (*pstr) {
      if (*pstr == '%') {
        if (pstr[1] && pstr[2]) {
          *pbuf++ = from_hex(pstr[1]) << 4 | from_hex(pstr[2]);
          pstr += 2;
        }
      } else if (*pstr == '+') { 
        *pbuf++ = ' ';
      } else {
        *pbuf++ = *pstr;
      }
      pstr++;
    }
    *pbuf = '\0';
    return buf;
  }

  /* The + gets replaced with an _ and the % with a : */
  char *encodeXmlSafeLua(const char *myString)
  {
    char *buffer = (char *)malloc(sizeof(char) * (strlen(myString)+1));
    strcpy (buffer,myString);
    
    char *newEncodedString = url_encode(buffer);
    replaceInString(newEncodedString, '+', '-');
    replaceInString(newEncodedString, '%', ':');

    free(buffer);
    return newEncodedString;
  }

  char *decodeXmlSafeLua(const char *myString) 
  {
    char *buffer = (char *)malloc(sizeof(char) * (strlen(myString)+1));
    strcpy (buffer,myString);

    replaceInString(buffer, '-', '+');
    replaceInString(buffer, ':', '%');

    char *newDecodedString = url_decode(buffer);

    free(buffer);
    return newDecodedString;   
  }
}

static int fileCopy(lua_State *L)
{
  int nparam = lua_gettop(L);

  if (nparam < 2)
  {
    luaL_error(L, "Bad arguments - Copy : Source => Destination");
    return 0;
  }
  
  char * inputFile  = (char *) lua_tostring(L, 1);
  char * outputFile = (char *) lua_tostring(L, 2);
    
  std::ifstream infile(inputFile, std::ios_base::binary);
  std::ofstream outfile(outputFile, std::ios_base::binary);
  
  outfile << infile.rdbuf();
  
  infile.close();
  outfile.close();
  
  return 0;
}

static int xml2luavar(lua_State *L, int index, const TiXmlElement *e)
{
    int vt;
    if(e->QueryIntAttribute("luaType", &vt) != TIXML_SUCCESS)
    {
        return -1;
    }
    const char *key = e->Value() + 1;
    int ki;

    if(sscanf(key, "%d", &ki) == 1)
    {
        lua_pushnumber(L, ki);
    }
    else
    {
        char *tmpString = decodeXmlSafeLua(key);
        lua_pushstring(L, tmpString);
        free(tmpString);
    }

    if(vt == LUA_TNIL)
    {
        lua_pushnil(L);
        lua_settable(L, index);
        return 0;
    }

    /* To allow for empty tables */
    if(e->FirstChild() != NULL && e->FirstChild()->Type() == TiXmlNode::TEXT)
    {
        const TiXmlText *text = e->FirstChild()->ToText();
        if(vt == LUA_TNUMBER)
        {
            double d;
            if(sscanf(text->Value(), "%lf", &d) == 1)
            {
                lua_pushnumber(L, d);
                lua_settable(L, index);
            }
            else
            {
                lua_pop(L, 1);
            }
        }
        else if(vt == LUA_TBOOLEAN)
        {
            int i;
            if(sscanf(text->Value(), "%d", &i) == 1)
            {
                lua_pushboolean(L, i);
                lua_settable(L, index);
            }
            else
            {
                lua_pop(L, 1);
            }
        }
        else if(vt == LUA_TSTRING)
        {
            string utf8(text->Value());
            char *tmpString = decodeXmlSafeLua(utf8.c_str());
            lua_pushstring(L, tmpString);
            lua_settable(L, index);
            free(tmpString);
        }
        else
        {
            lua_pop(L, 1);
        }
    }
    else if(vt == LUA_TTABLE)
    {
        lua_newtable(L);
        int tableindex = lua_gettop(L);

        for(const TiXmlElement *child = e->FirstChildElement();
            child != NULL; child = child->NextSiblingElement())
        {
            xml2luavar(L, tableindex, child);
        }
        lua_settable(L, index);
    }
    else
    {
        lua_pop(L, 1);
    }
    return 0;
}

static int luavar2xml(lua_State *L, int index, TiXmlElement *e)
{
    int luaType = lua_type(L, index);

    if(luaType == LUA_TNIL)
    {
        e->SetAttribute("luaType", LUA_TNIL);
    }
    else if(luaType == LUA_TNUMBER)
    {
        e->SetAttribute("luaType", LUA_TNUMBER);
        ostringstream oss;
        oss << lua_tonumber(L, index);
        TiXmlText text(oss.str().c_str());
        e->InsertEndChild(text);
    }
    else if(luaType == LUA_TBOOLEAN)
    {
        e->SetAttribute("luaType", LUA_TBOOLEAN);
        ostringstream oss;
        oss << lua_toboolean(L, index);
        TiXmlText text(oss.str().c_str());
        e->InsertEndChild(text);
    }
    else if(luaType == LUA_TSTRING)
    {
        e->SetAttribute("luaType", LUA_TSTRING);
        string utf8 = (lua_tostring(L, index));
        char *tmpString = encodeXmlSafeLua(utf8.c_str());
        TiXmlText text(tmpString);
        // text.SetCDATA(true);
        e->InsertEndChild(text);
        free(tmpString);
    }
    else if(luaType == LUA_TTABLE)
    {
        e->SetAttribute("luaType", LUA_TTABLE);
        lua_pushnil(L);
        while (lua_next(L, index) != 0)
        {
            lua_pushvalue(L, -2);
            string key("_");
            key += lua_tostring(L, -1);
            char *tmpString = encodeXmlSafeLua(key.c_str());
            TiXmlElement ne(tmpString);
            lua_pop(L, 1);
            luavar2xml(L, lua_gettop(L), &ne);
            e->InsertEndChild(ne);
            lua_pop(L, 1);
            free(tmpString);
        }
    }
    return 0;
}

static int saveToXml(lua_State *L)
{
    int n = lua_gettop(L);

    if(n != 2 || !lua_isstring(L, 1) || !lua_istable(L, 2))
    {
        lua_settop(L, 0);
        return 0;
    }
    TiXmlDocument doc(lua_tostring(L, 1));
    TiXmlDeclaration dec("1.0", "utf-8", "yes");
    doc.InsertEndChild(dec);
    TiXmlElement root("LuaVariables");
    luavar2xml(L, 2, &root);
    doc.InsertEndChild(root);
    if(!doc.SaveFile())
        printf("failed to save XML.\n");

    lua_settop(L, 0);
    lua_pushboolean(L, 1);
    return 1;
}

static int dumpToXml(lua_State *L)
{
    int n = lua_gettop(L);

    if(n != 1 || !lua_istable(L, 1))
    {
        lua_settop(L, 0);
        return 0;
    }
    TiXmlDocument doc("");
    TiXmlDeclaration dec("1.0", "utf-8", "yes");
    doc.InsertEndChild(dec);
    TiXmlElement root("LuaVariables");
    luavar2xml(L, 1, &root);
    doc.InsertEndChild(root);
 
    string myString("");
    myString << doc;

    lua_settop(L, 0);
    lua_pushstring(L, myString.c_str());
    return 1;
}

static int loadFromXml(lua_State *L)
{
    int n = lua_gettop(L);

    if(n != 1 || !lua_isstring(L, 1))
    {
        lua_settop(L, 0);
        return 0;
    }

    TiXmlDocument doc(lua_tostring(L, 1));
    if(!doc.LoadFile(TIXML_ENCODING_UTF8))
    {
        return 0;
    }
    lua_settop(L, 0);
    lua_newtable(L);

    for(const TiXmlElement *child = doc.FirstChildElement()->FirstChildElement();
        child != NULL; child = child->NextSiblingElement())
    {
        xml2luavar(L, 1, child);
    }
    return 1;
}

static int parseFromXml(lua_State *L)
{
    int n = lua_gettop(L);

    if(n != 1 || !lua_isstring(L, 1))
    {
        lua_settop(L, 0);
        return 0;
    }

    TiXmlDocument doc("");

    if(!doc.Parse(lua_tostring(L, 1)) && doc.Error())
    {
        return 0;
    }

    lua_settop(L, 0);
    lua_newtable(L);

    for(const TiXmlElement *child = doc.FirstChildElement()->FirstChildElement();
        child != NULL; child = child->NextSiblingElement())
    {
        xml2luavar(L, 1, child);
    }
    return 1;
}

/*
  Taken from http://lua-users.org/wiki/LuaXml
  Originally by Robert Noll.
  A rough an ready "load any XML into LUA"
 */

void LuaXML_ParseNode (lua_State *L,TiXmlNode* pNode) {
	if (!pNode) return;
	// resize stack if neccessary
	luaL_checkstack(L, 5, "LuaXML_ParseNode : recursion too deep");
	
	TiXmlElement* pElem = pNode->ToElement();
	if (pElem) {
		// element name
		lua_pushstring(L,"name");
		lua_pushstring(L,pElem->Value());
		lua_settable(L,-3);
		
		// parse attributes
		TiXmlAttribute* pAttr = pElem->FirstAttribute();
		if (pAttr) {
			lua_pushstring(L,"attr");
			lua_newtable(L);
			for (;pAttr;pAttr = pAttr->Next()) {
				lua_pushstring(L,pAttr->Name());
				lua_pushstring(L,pAttr->Value());
				lua_settable(L,-3);
				
			}
			lua_settable(L,-3);
		}
	}
	
	// children
	TiXmlNode *pChild = pNode->FirstChild();
	if (pChild) {
		int iChildCount = 0;
		for(;pChild;pChild = pChild->NextSibling()) {
			switch (pChild->Type()) {
				case TiXmlNode::DOCUMENT: break;
				case TiXmlNode::ELEMENT: 
					// normal element, parse recursive
					lua_newtable(L);
					LuaXML_ParseNode(L,pChild);
					lua_rawseti(L,-2,++iChildCount);
				break;
				case TiXmlNode::COMMENT: break;
				case TiXmlNode::TEXT: 
					// plaintext, push raw
					lua_pushstring(L,pChild->Value());
					lua_rawseti(L,-2,++iChildCount);
				break;
				case TiXmlNode::DECLARATION: break;
				case TiXmlNode::UNKNOWN: break;
			};
		}
		lua_pushstring(L,"n");
		lua_pushnumber(L,iChildCount);
		lua_settable(L,-3);
	}
}

static int LuaXML_ParseFile (lua_State *L) {
	const char* sFileName = luaL_checkstring(L,1);
	TiXmlDocument doc(sFileName);
	doc.LoadFile();
	lua_newtable(L);
	LuaXML_ParseNode(L,&doc);
	return 1;
}

static int LuaXML_ParseString (lua_State *L) {
	const char* sXmlString = luaL_checkstring(L,1);
	TiXmlDocument doc;
	doc.Parse(sXmlString);
	lua_newtable(L);
	LuaXML_ParseNode(L,&doc);
	return 1;
}

static int bin2hex (lua_State *L) {
  size_t l1; //,i=0;
  unsigned char ll[]="0123456789abcdef";
  unsigned char lu[]="0123456789ABCDEF";
  unsigned char *lookup=lu;
  const char *s1 = luaL_checklstring(L, 1, &l1);
  luaL_Buffer b;
  if (lua_isstring(L, 2)) lookup=((char ) *lua_tolstring(L,2,NULL)=='l')?ll:lu;
  luaL_buffinit(L, &b);
  while (l1--) {
    luaL_putchar(&b, lookup[((unsigned char) (*s1)>>4)%16]);
    luaL_putchar(&b, lookup[(unsigned char)(*s1++)%16]);
  }
  luaL_pushresult(&b);
  return 1;
}

static int hex2bin(lua_State *L) {
  unsigned char found=0,i,j=0,obyte=0;
  size_t l1;
  char lookup[]="0123456789ABCDEF0123456789abcdef";
  const char *s1 = luaL_checklstring(L, 1, &l1);
  luaL_Buffer b;
  luaL_buffinit(L, &b);
  lua_pushstring(L,"This isn't a valid hex string!");
  if (l1%2!=0) lua_error(L);
  while (l1--) {
     found++;
     for(i=0;i<32;i++) {
       if (*s1==lookup[i]) {
         if (j==0) obyte=(i%16)<<4;
           else { obyte+=i%16; luaL_putchar(&b,(char)obyte); }
         j^=1;
         s1++;
         found--;
         break;
       }
    }
    if (found==1) lua_error(L);
  }
  luaL_pushresult(&b);
  return 1;
}

/*-------------------------------------------------------------------------*\
* Sleep for n Milliseconds - added for MurgaLua
\*-------------------------------------------------------------------------*/
static int timeout_lua_sleepMillisecs(lua_State *L)
{
    double n = luaL_checknumber(L, 1);
#ifdef _WIN32
    Sleep((int)(n));
#else
    struct timespec t, r;
    n = n / 1000;
    t.tv_sec = (int) n;
    n -= t.tv_sec;
    t.tv_nsec = (int) (n * 1000000000);
    if (t.tv_nsec >= 1000000000) t.tv_nsec = 999999999;
    while (nanosleep(&t, &r) != 0) {
        t.tv_sec = r.tv_sec;
        t.tv_nsec = r.tv_nsec;
    }
#endif
    return 0;
}

static const luaL_reg R[] =
{
    {"saveToXml", saveToXml},
    {"dumpToXml", dumpToXml},
    {"loadFromXml", loadFromXml},
    {"parseFromXml", parseFromXml},
    {"importXmlFile",   LuaXML_ParseFile},
    {"importXmlString", LuaXML_ParseString},
    {"decodeDataFromHex", hex2bin},
    {"encodeDataAsHex", bin2hex},
    {"fileCopy", fileCopy},
    {"sleepMilliseconds", timeout_lua_sleepMillisecs },
    {NULL, NULL}
};

extern "C" int openMurgaLuaLib(lua_State *L)
{
    luaL_openlib(L, "murgaLua", R, 0);

    lua_pushliteral(L, "version");
    lua_pushstring(L, MURGALUA_LIB_VERSION);
    lua_settable(L, -3);

    return 1;
}
