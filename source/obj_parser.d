import std.regex;
import std.stdio;
import derelict.opengl3.gl3;
import files;
import gfm.math;
import std.conv;

struct WavefrontObj {
  vec3f[] vertex_positions;
  vec2f[] uv_coordinates;
  vec3i[] faces_vertids;
  vec3i[] faces_uvids;
};

WavefrontObj parse_obj(string filepath) {
  auto file_text = read_file(filepath);

  WavefrontObj new_obj;

  // load vertex_positions
  auto vert_positions = regex(r"v ([0-9-\.]+) ([0-9-\.]+) ([0-9-\.]+)");
  foreach(c; matchAll(file_text, vert_positions)) {
      new_obj.vertex_positions ~= vec3f(
        to!float(c[1]),
        to!float(c[2]),
        to!float(c[3]),
      );
  }

  // load uv_coordinates
  auto uv_coordinates = regex(r"vt ([0-9-\.]+) ([0-9-\.]+)");
  foreach(c; matchAll(file_text, uv_coordinates)) {
      new_obj.uv_coordinates ~= vec2f(
        to!float(c[1]),
        to!float(c[2]),
      );
  }


  // load face vertids
  auto faces_vertids = regex(r"f ([0-9]+)\/[0-9]+\/[0-9]+ ([0-9]+)\/[0-9]+\/[0-9]+ ([0-9]+)\/[0-9]+\/[0-9]+");
  foreach(c; matchAll(file_text, faces_vertids)) {
      new_obj.faces_vertids ~= vec3i(
        to!int(c[1]) - 1,
        to!int(c[2]) - 1,
        to!int(c[3]) - 1,
      );
  }

  // load face uvids
  auto faces_uvids = regex(r"f [0-9]+\/([0-9]+)\/[0-9]+ [0-9]+\/([0-9]+)\/[0-9]+ [0-9]+\/([0-9]+)\/[0-9]+");
  foreach(c; matchAll(file_text, faces_uvids)) {
      new_obj.faces_uvids ~= vec3i(
        to!int(c[1]) - 1,
        to!int(c[2]) - 1,
        to!int(c[3]) - 1,
      );
  }

  return new_obj;
}

struct MeshData {
  GLfloat[] g_vertex_buffer_data;
  GLfloat[] g_uv_buffer_data;
}

MeshData obj_to_meshdata(string filename) {
  // Parse obj file
  WavefrontObj obj_file = parse_obj(filename);

  // Make a new mesh
  MeshData mesh;
  
  // push all vertices into mesh
  for(int i = 0; i < obj_file.faces_vertids.length; ++i) {
    // vert 1
    mesh.g_vertex_buffer_data ~= [
      obj_file.vertex_positions[obj_file.faces_vertids[i].x].x,
      obj_file.vertex_positions[obj_file.faces_vertids[i].x].y,
      obj_file.vertex_positions[obj_file.faces_vertids[i].x].z,

    // vert 2
      obj_file.vertex_positions[obj_file.faces_vertids[i].y].x,
      obj_file.vertex_positions[obj_file.faces_vertids[i].y].y,
      obj_file.vertex_positions[obj_file.faces_vertids[i].y].z,

    // vert 3
      obj_file.vertex_positions[obj_file.faces_vertids[i].z].x,
      obj_file.vertex_positions[obj_file.faces_vertids[i].z].y,
      obj_file.vertex_positions[obj_file.faces_vertids[i].z].z,
    ];
  }

  // push all uv locations into mesh
  for(int i = 0; i < obj_file.faces_uvids.length; ++i) {
    // vert 1
    mesh.g_uv_buffer_data ~= [
      obj_file.uv_coordinates[obj_file.faces_uvids[i].x].x,
      obj_file.uv_coordinates[obj_file.faces_uvids[i].x].y,

    // vert 2
      obj_file.uv_coordinates[obj_file.faces_uvids[i].y].x,
      obj_file.uv_coordinates[obj_file.faces_uvids[i].y].y,

    // vert 3
      obj_file.uv_coordinates[obj_file.faces_uvids[i].z].x,
      obj_file.uv_coordinates[obj_file.faces_uvids[i].z].y,
    ];
  }

  return mesh;
}