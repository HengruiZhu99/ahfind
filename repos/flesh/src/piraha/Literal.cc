#include "Piraha.hpp"

using namespace cctki_piraha;

bool Literal::match(Matcher *m) {
  if(m->pos - m->input_size >= 0) {
    m->fail(c);
    return false;
  }
  if(m->input[m->pos] == c) {
    m->max_pos = std::max(m->pos,m->max_pos);
    m->pos++;
    return true;
  } else {
    m->fail(c);
    return false;
  }
}
