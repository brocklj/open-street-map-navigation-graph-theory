require 'ruby-graphviz'
require_relative 'visual_edge'
require_relative 'visual_vertex'

# Visual graph storing representation of graph for plotting.
class VisualGraph
  # Instances of +VisualVertex+ classes
  attr_reader :visual_vertices
  # Instances of +VisualEdge+ classes
  attr_reader :visual_edges
  # Corresponding +Graph+ Class
  attr_reader :graph
  # Scale for printing to output needed for GraphViz
  attr_reader :scale

  # Create instance of +self+ by simple storing of all given parameters.
  def initialize(graph, visual_vertices, visual_edges, bounds)
  	@graph = graph
    @visual_vertices = visual_vertices
    @visual_edges = visual_edges
    @bounds = bounds
    @scale = ([bounds[:maxlon].to_f - bounds[:minlon].to_f, bounds[:maxlat].to_f - bounds[:minlat].to_f].min).abs / 10.0
  end

  # Export +self+ into Graphviz file given by +export_filename+.
  def export_graphviz(export_filename)
    # create GraphViz object from ruby-graphviz package
    graph_viz_output = GraphViz.new( :G, 
    								                  use: :neato, 
		                                  truecolor: true,
                              		    inputscale: @scale,
                              		    margin: 0,
                              		    bb: "#{@bounds[:minlon]},#{@bounds[:minlat]},
                                  		    #{@bounds[:maxlon]},#{@bounds[:maxlat]}",
                              		    outputorder: :nodesfirst)

    # append all vertices
    @visual_vertices.each { |k,v|
    	graph_viz_output.add_nodes( v.id , :shape => 'point', 
                                         :comment => "#{v.lat},#{v.lon}!", 
                                         :pos => "#{v.y},#{v.x}!")
	  }

    # append all edges
	  @visual_edges.each { |edge| 
    	graph_viz_output.add_edges( edge.v1.id, edge.v2.id, {'arrowhead' => 'none', 'label' => edge.length.to_i} )
	  }

    # export to a given format
    format_sym = export_filename.slice(export_filename.rindex('.')+1,export_filename.size).to_sym
    graph_viz_output.output( format_sym => export_filename )
  end

  #show nodes
  def show_nodes
    @visual_vertices.each do |k, v|
      print "#{v.id}: #{v.lat}, #{v.lon} \n"

    end 
  end

  def find_path_for_id(id_start, id_stop)

    start_vertex = @visual_vertices[id_start]
    end_vertex = @visual_vertices[id_stop]

    p start_vertex
    p end_vertex

  end

  def find_path_for_coordinates(lat_start, lon_start, lat_end, lon_end)
    p lat_start
    p lon_start
    p lat_end
    p lon_end

  end

  def find_vehicle_path(lat_start, lon_start, lat_end, lon_end)
    p lat_start
    p lon_start
    p lat_end
    p lon_end

  end

end
