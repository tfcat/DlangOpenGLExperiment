import std.stdio;

// Read a full file into a string object
string read_file(string filepath) {
  auto f = File(filepath);
  string buffer;

  foreach (line ; f.byLine) {
      buffer ~= line ~ "\n";
  }

  f.close();
  return buffer;
}