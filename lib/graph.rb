require_relative 'vertex'
require_relative 'edge'

# Class defining Graph
class Graph
  # Hash of instances of +Vertex+
  attr_reader :vertices
  # List of instances of +Edge+
  attr_reader :edges

  # Hash of [vertex1_id][vertex2_id] 
  attr_reader :edge_map

  # create instance of +self+ by simple storing of all parameters
  def initialize(vertices, edges, edge_map = {})
    @vertices = vertices
    @edges = edges
    @edge_map = edge_map
  end
end
