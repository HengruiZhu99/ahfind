#include "Piraha.hpp"

using namespace cctki_piraha;

ILiteral::ILiteral(char b) : lc(lc_(b)), uc(uc_(b)) {}

bool ILiteral::match(Matcher *m) {
  if(m->pos >= (int)m->input_size ) {
    m->fail(lc);
    m->fail(uc);
    return false;
  }
  char c = m->input[m->pos];
  if(c == uc || c == lc) {
    m->max_pos = std::max(m->pos,m->max_pos);
    m->pos++;
    return true;
  } else {
    m->fail(lc);
    m->fail(uc);
    return false;
  }
}
