#include <string.h>
#include "Piraha.hpp"

using namespace cctki_piraha;

Matcher::Matcher(smart_ptr<Grammar> g_,const char *pat_,const char *input_,int input_size_) :
    Group(pat_,input_),
    input(input_), g(g_), input_size(input_size_),
    pos(0), max_pos(-1), match_to(-2), pat(pat_), expected(), err_pos(-1) {
    inrule = pat_;
	if(input_size < 0)
		input_size=strlen(input);
}

bool Matcher::matches() {
    // -2 is used just to make sure
    // we can't actually get to that
    // position, even in an error
    // condition.
    return matchesTo(-2);
}

bool Matcher::matchesTo(int match_to_) {
    smart_ptr<Pattern> p = g->patterns.get(pat);
    if(!p.valid()) {
        std::cout << "Grammar does not contain \"" << pat << "\"" << std::endl;
        std::cout << g->patterns << std::endl;
    }
    assert(p.valid());
    //packrat.clear();
    pos = 0;
    max_pos = -1;
    match_to = match_to_;
    err_pos = -1;
    children->clear();
    bool b = p->match(this);
    end_ = pos;
    return b;
}

void Matcher::fail(Bracket *br) {
  for(unsigned int i=0;i<br->ranges.size();i++) {
    fail(br->ranges[i]->lo,br->ranges[i]->hi);
  }
}

void Matcher::fail(char c) {
  fail(c,c);
}

void Matcher::fail(char lo,char hi) {
  if(err_pos > pos)
    return;
  if(lo == hi) {
    if(lo == ' ' || lo == '\r' || lo == '\t' || lo == '\n' || lo == '#')
      return;
  }
  if(pos < input_size) {
    char c = input[pos];
    if(c == '\n' || c == ' ' || c == '\r' || c == '\t') {
      return;
    }
  }
  if(err_pos < pos)
    expected.ranges.clear();
  expected.addRange(lo,hi);
  inrule_max = inrule;
  err_pos = pos;
}

int Matcher::showError() {
    return showError(std::cout);
}

const int num_previous_lines = 5;

bool isHumanReadableRange(char c) {
  return ('a' <= c && c <= 'y') or ('A' <= c && c <= 'Y') or ('0' <= c && c <= '8');
}

int Matcher::showError(std::ostream& out) {
  std::vector<char> expectedChars;
  for(auto r = expected.ranges.begin(); r != expected.ranges.end(); ++r) {
    for(int i = (*r)->lo; i <= (*r)->hi; ++i) {
      expectedChars.push_back((char)i);
    }
  }
  out << "Parse Error" << std::endl;
  out << "Expected one of the following characters:";
  bool first = true;
  for(auto c=expectedChars.begin();c != expectedChars.end();++c) {
    if(first) first = false;
    else out << ',';
    if(isHumanReadableRange(*c)) {
      int n = 1;
      while(c+n != expectedChars.end() && n+(*c) == *(c+n)) {
        n++;
      }
      if(n >= 3) {
        out << " '" << *c << "' to";
        c += (n-1);
      }
    }
    if(*c == '\'')
      out << "single quote";
    else if(*c == '"')
      out << "double quote";
    else
      out << " '" << *c << "'";
  }
  int buf[num_previous_lines];
  buf[0] = 0;
  int line = 0;
  for(int i=0;i < input_size;i++) {
    char c = input[i];
    if(c == '\n') {
      line++;
      int ln = line % num_previous_lines;
      buf[ln] = i;
      if(i >= err_pos)
        break;
    }
  }
  int ln = line % num_previous_lines;
  int lo = line - num_previous_lines + 1;
  if(lo < 0) lo = 0;
  lo = lo % num_previous_lines;
  for(int i=buf[lo];i<buf[ln];i++) {
    char c = input[i];
    if(c == '\r') ;
    else if(c == '\n') out << std::endl;
    else out << c;
  }
  out << std::endl;
  int m = (line - 1) % num_previous_lines;
  for(int i=buf[m]+1;i<err_pos;i++)
    out << ' ';
  out << '^' << std::endl;
  return line;
}
