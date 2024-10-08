#include "Piraha.hpp"

using namespace cctki_piraha;

void Group::dump(std::ostream& o) {
	dump(-1,o,0);
}
void Group::dump(int n,std::ostream& o,int indent) {
    for(int i=0;i<indent;i++)
        o << ' ';
    if(n >= 0) {
    	o << "[" << n << "] ";
    }
    o << pattern << ": ";
    if(children->size()==0) {
        for(int i=start_;i<end_;i++)
            o << input[i];
    }
    o << std::endl;
    typedef vector<smart_ptr<Group> >::iterator group_iter;
    int nn = 0;
    for(group_iter gi = children->begin();
            gi != children->end();
            ++gi) {
        (*gi)->dump(nn++,o,indent+2);
    }
}
void Group::dumpPerl(std::ostream& o) {
	o << "$VAR = ";
	dumpPerl(o,0);
	o << ";" << std::endl;
}
void Group::dumpPerl(std::ostream &o,int indent) {
	for(int i=0;i<indent;i++)
		o << ' ';
	o << "{" << std::endl;
	indent += 2;
	for(int i=0;i<indent;i++)
		o << ' ';
	o << "name=> \"" << getPatternName() << "\"," << std::endl;
	if(children->size()==0) {
		for(int i=0;i<indent;i++)
			o << ' ';
		o << "children=>[]," << std::endl;
		for(int i=0;i<indent;i++)
			o << ' ';
		o << "text=>\"";
		for(int i=start_;i<end_;i++)
			insertc(o,input[i]);
		o << "\"," << std::endl;
	} else {
		for(int i=0;i<indent;i++)
			o << ' ';
		o << "children=>[" << std::endl;
		typedef vector<smart_ptr<Group> >::iterator group_iter;
		for(group_iter gi = children->begin();
				gi != children->end();
				++gi) {
			(*gi)->dumpPerl(o,indent+2);
			for(int i=0;i<indent;i++)
				o << ' ';
			o << "," << std::endl;
		}
		for(int i=0;i<indent;i++)
			o << ' ';
		o << "]," << std::endl;
	}
	for(int i=0;i<indent;i++)
		o << ' ';
	o << "start=>" << start() << "," << std::endl;
	for(int i=0;i<indent;i++)
		o << ' ';
	o << "end=>" << end() << "," << std::endl;
	for(int i=0;i<indent;i++)
		o << ' ';
	o << "line=>" << line() << "," << std::endl;
	indent -= 2;
	for(int i=0;i<indent;i++)
		o << ' ';
	o << "}" << std::endl;
}

void Group::dumpPython(std::ostream& o) {
	o << "VAR = ";
	dumpPython(o,0);
}
void Group::dumpPython(std::ostream &o,int indent) {
	for(int i=0;i<indent;i++)
		o << ' ';
	o << "{" << std::endl;
	indent += 2;
	for(int i=0;i<indent;i++)
		o << ' ';
	o << "'name' : \"" << getPatternName() << "\"," << std::endl;
	if(children->size()==0) {
		for(int i=0;i<indent;i++)
			o << ' ';
		o << "'children' : []," << std::endl;
		for(int i=0;i<indent;i++)
			o << ' ';
		o << "'text' : \"";
		for(int i=start_;i<end_;i++)
			insertc(o,input[i]);
		o << "\"," << std::endl;
	} else {
		for(int i=0;i<indent;i++)
			o << ' ';
		o << "'children' : [" << std::endl;
		typedef vector<smart_ptr<Group> >::iterator group_iter;
		for(group_iter gi = children->begin();
				gi != children->end();
				++gi) {
			(*gi)->dumpPython(o,indent+2);
			for(int i=0;i<indent;i++)
				o << ' ';
			o << "," << std::endl;
		}
		for(int i=0;i<indent;i++)
			o << ' ';
		o << "]," << std::endl;
	}
	for(int i=0;i<indent;i++)
		o << ' ';
	o << "'start' : " << start() << "," << std::endl;
	for(int i=0;i<indent;i++)
		o << ' ';
	o << "'end' : " << end() << "," << std::endl;
	for(int i=0;i<indent;i++)
		o << ' ';
	o << "'line' : " << line() << "," << std::endl;
	indent -= 2;
	for(int i=0;i<indent;i++)
		o << ' ';
	o << "}" << std::endl;
}

std::string Group::substring() {
    std::string sub;
    for(int i=start_;i<end_;i++) {
        sub += input[i];
    }
    return sub;
}

std::string Group::getPatternName() {
    return pattern;
}

int Group::line() {
	int line = 1;
	for(int i=0;i<start_;i++) {
		if(input[i] == '\n')
			line++;
	}
	return line;
}

int Group::childCount() {
    return children->size();
}

smart_ptr<Group> Group::child(int n) {
    return (*children)[n];
}

const int num_previous_lines = 5;

/**
 * This function formats and displays
 * syntax errors. It prints the last
 * five lines and uses a ^ to point to
 * the position of the error.
 */
int Group::showError(std::ostream& out) {
  out << "Parse Error" << std::endl;
  // keep the start position of the last 5 lines
  int start_position[num_previous_lines];
  start_position[0] = 0;
  int line = 0;
  int err_pos = start_;
  for(int i=0;input[i] != 0;i++) {
    char c = input[i];
    if(c == '\n') {
      line++;
      // the start position of line is
      // found by taking the modulus of
      // the line and the number of lines
      // to be stored.
      int ln = line % num_previous_lines;
      start_position[ln] = i;
      if(i >= err_pos)
        break;
    }
  }
  int ln = line % num_previous_lines;
  int lo = line - num_previous_lines + 1;
  if(lo < 0) lo = 0;
  lo = lo % num_previous_lines;
  // Print the previous five lines to show
  // context for the error
  for(int i=start_position[lo];i<start_position[ln];i++) {
    char c = input[i];
    if(c == '\r') ; // skip carriage returns because
                    // they can confuse the output.
                    // TODO: Backspaces would mess it
                    // up even more. 
    else if(c == '\n') out << std::endl;
    else out << c;
  }
  out << std::endl;
  int m = (line - 1) % num_previous_lines;
  // print the pointer to the error in the line.
  for(int i=start_position[m]+1;i<err_pos;i++)
    out << ' ';
  out << '^' << std::endl;
  return line;
}
