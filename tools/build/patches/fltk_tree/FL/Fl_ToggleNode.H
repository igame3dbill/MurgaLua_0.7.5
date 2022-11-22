
#ifndef Fl_ToggleNode_H
#define Fl_ToggleNode_H

#include <FL/Fl_Node.H>
#include <FL/Enumerations.H>
#include <string.h>

class Fl_Pixmap;

class Fl_ToggleNode : public Fl_Node {

  friend class Fl_ToggleTree;

public:

  Fl_ToggleNode(char* label = 0, int can_open = 1, Fl_Pixmap* pixmap = 0, int can_edit = 0,
                char * d = 0) : Fl_Node() {
    vsub_ = 0;
    selected_ = 0;
    changed_ = 0;
    opened_ = 1;
    color_ = FL_BLACK;

    label_ = strdup(label);
    pixmap_ = pixmap;
    can_open_ = can_open;
	can_edit_ = can_edit;
    data_ = d;
  }

  char* label(void) {
    return label_;
  }

  void label(char* ptr) {
    if (label_)
      delete label_;
    label_ = strdup(ptr);
  }

  Fl_Pixmap* pixmap(void) {
    return pixmap_;
  }

  void pixmap(Fl_Pixmap* ptr) {
    pixmap_ = ptr;
  }

  char* data() const {
    return data_;
  }

  void data(char* v) {
    data_ = v;
  }

  int can_open() {
    return can_open_;
  }

  void can_open (int b) {
    can_open_ = b;
  }

  int can_edit() {
    return can_edit_;
  }

  void can_edit (int b) {
    can_edit_ = b;
  }
  
  int is_open() {
    return opened_;
  }

  Fl_Color color() {
    return color_;
  }

  void color(Fl_Color b) {
    color_ = b;
  }

protected:

  int selected_;
  int changed_;
  int can_open_;
  int can_edit_;
  Fl_Color color_; 

  char* label_;
  Fl_Pixmap* pixmap_;
  char* data_;

};

#endif
