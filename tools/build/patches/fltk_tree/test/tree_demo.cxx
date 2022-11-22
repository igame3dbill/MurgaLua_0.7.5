#include <FL/Fl_ToggleTree.H>
#include <FL/Fl_Window.H>
#include <FL/Fl_Button.H>
#include <FL/Fl_Scroll.H>
#include <FL/Fl.H>

#include <FL/folder_small.xpm>
#include <FL/file_small.xpm>

#include <stdio.h>
#include <stdlib.h>

Fl_Pixmap* folderSmall;
Fl_Pixmap* fileSmall;

void
cb_test(Fl_Widget* widget, void*) {
  Fl_ToggleTree* tree = (Fl_ToggleTree*) widget;

  printf("state: %d\n", tree->state());

  if (tree->selected())
    printf("current=%s\n", tree->selected()->label());
  else {
    int i;
    // if selected()==0 then we have a multiple select
    printf("MULTIPLE:\n");
    Fl_ToggleNode* s;
    while ((s = tree->selection()))
      printf(" selected=%s\n", s->label());

    int n = tree->selection_count();
    printf("%d selections:\n", n);
    for (i = 0; i < n; i++) {
      s = tree->selection(i);
      printf(" %d %s\n", i, s->label());
    }
    for (i = n - 1; i >= 0; i--) {
      s = tree->selection(i);
      printf(" %d %s\n", i, s->label());
    }

  }
}

void
cb_remove(Fl_Widget*, void* ptr) {
  Fl_ToggleTree* tree = (Fl_ToggleTree*) ptr;

  if (tree->selected())
    tree->remove(tree->selected());
  else {
    Fl_ToggleNode* s;
    while ((s = tree->selection()))
      tree->remove(s);
  }
}

void
cb_draw_lines(Fl_Widget*, void* ptr) {
  Fl_ToggleTree* tree = (Fl_ToggleTree*) ptr;
  tree->draw_lines(!tree->draw_lines());
  tree->redraw();
}

void
cb_mac_colors(Fl_Widget*, void* ptr) {
  Fl_ToggleTree* tree = (Fl_ToggleTree*) ptr;
  if (tree->alternate_color() == tree->color())
    {
      tree->alternate_color(FL_LIGHT2);
      tree->trim_color(FL_LIGHT1);
    }
  else
    {
      tree->alternate_color(tree->color());
      tree->trim_color(tree->color());
    }
  tree->redraw();
}

void
cb_add_folder(Fl_Widget*, void* ptr) {
  Fl_ToggleTree* tree = (Fl_ToggleTree*) ptr;

  Fl_ToggleNode* sel = (Fl_ToggleNode*) tree->selected();
  if (sel == 0) {
    tree->add_next("Untitled", 1, folderSmall);
    return;
  }

  tree->traverse_start(sel);
  if (sel->is_open() && sel->can_open())
    tree->add_sub("Untitled", 1, folderSmall);
  else
    tree->add_next("Untitled", 1, folderSmall);
}


void
cb_add_paper(Fl_Widget*, void* ptr) {
  Fl_ToggleTree* tree = (Fl_ToggleTree*) ptr;

  Fl_ToggleNode* sel = (Fl_ToggleNode*) tree->selected();
  if (sel == 0) {
    tree->add_next("Untitled", 0, fileSmall);
    return;
  }

  tree->traverse_start(sel);
  if (sel->is_open() && sel->can_open())
    tree->add_sub("Untitled", 0, fileSmall);
  else
    tree->add_next("Untitled", 0, fileSmall);
}

int random_sort(Fl_Node*, Fl_Node*) {
  return (rand()&1)*2 - 1;    // -1 or 1
}

void cb_sort(Fl_Widget*, void* ptr) {
  Fl_ToggleTree* tree = (Fl_ToggleTree*) ptr;

  tree->sort_tree(Fl_ToggleTree::sort_by_label);

  tree->redraw();
}

void cb_sort_reverse(Fl_Widget*, void* ptr) {
  Fl_ToggleTree* tree = (Fl_ToggleTree*) ptr;

  tree->sort_tree(Fl_ToggleTree::sort_by_label, REVERSE_SORT);

  tree->redraw();
}

void cb_sort_random(Fl_Widget*, void* ptr) {
  Fl_ToggleTree* tree = (Fl_ToggleTree*) ptr;

  tree->sort_tree(random_sort);

  tree->redraw();
}

main() {
  Fl_Window win(240, 304, "Tree Example");
  Fl_Button remove_button(10, 200, 100, 22, "Remove");
  Fl_Button add_paper_button(10, 224, 100, 22, "Add Paper");
  Fl_Button add_folder_button(10, 248, 100, 22, "Add Folder");
  Fl_Button draw_lines_button(10, 272, 100, 22, "Draw Lines");
  Fl_Button sort_button(130, 200, 100, 22, "Sort");
  Fl_Button sort_button_rev(130, 224, 100, 22, "Reverse Sort");
  Fl_Button sort_button_rnd(130, 248, 100, 22, "Randomize");
  Fl_Button mac_colors_button(130, 272, 100, 22, "Mac Colors");
  Fl_Scroll s(10, 10, 220, 180);
  s.type(Fl_Scroll::VERTICAL_ALWAYS);
  s.box(FL_THIN_DOWN_FRAME);
  // When constructing an Fl_ToggleTree, the height doesn't matter.

  Fl_ToggleTree tree(12, 12, 220-s.scrollbar.w(), 10);

  s.end();

  // Add callbacks to the widgets

  remove_button.callback((Fl_Callback*)cb_remove, (void *)&tree);
  add_paper_button.callback((Fl_Callback*)cb_add_paper, (void *)&tree);
  add_folder_button.callback((Fl_Callback*)cb_add_folder, (void *)&tree);
  sort_button.callback((Fl_Callback*)cb_sort, (void *)&tree);
  sort_button_rnd.callback((Fl_Callback*)cb_sort_random, (void *)&tree);
  sort_button_rev.callback((Fl_Callback*)cb_sort_reverse, (void *)&tree);
  draw_lines_button.callback((Fl_Callback*)cb_draw_lines, (void *)&tree);
  mac_colors_button.callback((Fl_Callback*)cb_mac_colors, (void *)&tree);
  tree.callback(cb_test);

  int w[3] = {150, 200, 0};
  tree.column_widths(w);

  folderSmall = new Fl_Pixmap(folder_small);
  fileSmall = new Fl_Pixmap(file_small);

  Fl_ToggleNode* node;

  // Add some nodes with icons -- some open, some closed.
  // Fl_ToggleNode::Fl_ToggleNode( LABEL , CAN_OPEN (default=1) , ICON )

  tree.add_next("aaa\t123", 1, folderSmall);

  tree.add_sub("bbb TWO\t456", 1, folderSmall);
  tree.traverse_up();

  node = tree.add_next("bbb", 1, folderSmall);
  tree.close(node);

  tree.add_sub("ccc\t789", 1, folderSmall);
  tree.add_sub("ddd\t012", 0, fileSmall);
  tree.traverse_up();
  tree.traverse_up();

  tree.add_next("eee", 1, folderSmall);
  tree.add_sub("fff", 0, fileSmall);
  tree.traverse_up();

  tree.add_next("ggg", 1, folderSmall);
  node = tree.add_sub("hhh", 1, fileSmall);
  tree.close(node);
  tree.add_sub("iii", 1, fileSmall);
  tree.traverse_up();
  tree.traverse_up();

  tree.add_next("jjj", 1, folderSmall);
  tree.add_sub("kkk", 0, fileSmall);
  tree.traverse_up();

  tree.add_next("lll", 0, fileSmall);
  node = tree.add_next("mmm", 1, folderSmall);
  tree.close(node);
  tree.add_sub("nnn", 1, folderSmall);
  tree.add_sub("ooo", 0, fileSmall);
  tree.traverse_up();
  tree.traverse_up();

  tree.add_next("ppp", 1, folderSmall);
  tree.add_sub("qqq", 0, fileSmall);
  tree.traverse_up();

  tree.add_next("rrr", 1, folderSmall);
  tree.add_sub("sss", 1, folderSmall);
  tree.add_sub("ttt", 1, folderSmall);
  tree.traverse_up();
  tree.traverse_up();

  tree.add_next("uuu", 1, folderSmall);
  tree.add_sub("vvv", 0, fileSmall);
  tree.traverse_up();

  tree.add_next("www", 0, fileSmall);
  tree.add_next("xxx", 0, fileSmall);
  tree.add_next("yyy", 0, fileSmall);
  tree.add_sub("zzz", 0, fileSmall);

  // Examples of removing items (successfully, and unsuccessfully)
  // by label name:

  if (tree.remove("xxx"))
    printf("Successfully deleted \"xxx\"\n");
  else
    printf("Could not delete \"xxx\"\n");

  if (tree.remove("nonexistant"))
    printf("Successfully deleted \"nonexistant\"\n");
  else
    printf("Could not delete \"nonexistant\"\n");

  tree.update_height();

  win.show();

  Fl::run();
}


