require 'ruby-graphviz'
require_relative 'visual_edge'
require_relative 'visual_vertex'
require_relative 'dijkstra_performer'
require_relative 'utils'

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
      color = !v.color.nil? ? v.color : "black"
      size = v.selected ? "11" : "2"
      graph_viz_output.add_nodes( v.id , :shape => "point",
                                         :penwidth => size, 
                                         :comment => "#{v.lat},#{v.lon}!", 
                                         :pos => "#{v.y},#{v.x}!",
                                         :color => color)
	  }

    # append all edges
    @visual_edges.each { |edge| 
      penwidth = edge.emphesized ? 5 : 1

      arrowhead = edge.edge.one_way ? "normal arrowsize=0.2" : "none" 
      color = edge.emphesized ? "orange" : "black"  

    	graph_viz_output.add_edges( edge.v1.id, edge.v2.id, {'arrowhead' => arrowhead, 'penwidth' => penwidth, 'color' => color} )
    }
        
    # export to a given format    
    format_sym = export_filename.slice(export_filename.rindex('.')+1,export_filename.size).to_sym

    if !@path_distance.nil? || !@path_time.nil?
    graph_viz_output.add_label("label" => "distance: #{@path_distance} meters \n time: #{@path_time} seconds",                              
                                "penwidth" => "0",
                                "color" => "orange"
                              )
    end

    graph_viz_output.output( format_sym => export_filename )
  end

  #show nodes
  def show_nodes
    @visual_vertices.each do |k, v|
      print "#{v.id}: #{v.lat}, #{v.lon} \n"

    end 
  end

  def show_nodes_for_id(id_v_start, id_v_end)

    start_v = visual_vertices[id_v_start]
    end_v = visual_vertices[id_v_end]

    _mark_vertices(start_v, end_v)
  end

  def show_nodes_for_coordinates(lat_start, lon_start, lat_end, lon_end)    
    start_v = _find_close_vertex(lat_start, lon_start)
    end_v = _find_close_vertex(lat_end, lon_end)

    start_v.color = "green"
    end_v.color = "red"
    start_v.selected = true
    end_v.selected = true
  end

  def find_vehicle_path(start_v, end_v, vertex_weight_attr)     
    _mark_vertices(start_v, end_v)

    path = _find_shortest_path(start_v.id, end_v.id, vertex_weight_attr)
    dis, time = _process_path(path)
    @path_time = time
    @path_distance = dis
    print "------------------------- \n"
    print "INFO: duration\n"
    print dis.to_s + " meters \n"
    print time.to_s + " seconds \n"
    print "------------------------- \n"
  end

 def _mark_vertices(start_v, end_v)
  start_v.color = "green"
  end_v.color = "red"
  start_v.selected = true
  end_v.selected = true

end

  # @params path [[vertex, vertex]]
  # @return distance [meters] time duration [seconds]
  def _process_path(path)
    time = 0.0
    # distance in meters
    dis = 0
     # Mark emphersized visual edges   
    path.each do |v1, v2|
      if graph.edge_map[v1] != nil
        v_edge = @graph.edge_map[v1][v2] 
        v_edge.emphesized = true                                                       
        length = v_edge.edge.length   
        dis += length        
        time +=  v_edge.edge.time
      end
    end
    return dis.round(2), time.round(2)
  end
  
  def _find_close_vertex(lat, lon)    
    found_vertex = nil
    
    score = Float::INFINITY
    
    @visual_vertices.each do |i, v|
      
      result = (v.lon.to_f - lon.to_f).abs + (v.lat.to_f - lat.to_f).abs

      if result < score
        score = result
        found_vertex = v
      end 
  end

  return found_vertex
  end

  # @return vertex ids of the shortest path 
 def _find_shortest_path(vertex_start_id, vertex_end_id, vertex_weight_attr)
    start_timestamp = Time.now
    print "Running perform_dijkstra: #{start_timestamp} \n"   
    prev = DijkstraPerformer.perform_dijkstra(@graph, vertex_start_id, vertex_end_id, vertex_weight_attr)
    print "Ran perform_dijkstra in #{Time.now - start_timestamp} seconds \n"   

    path = {}
    u = vertex_end_id
    if prev[u] != nil || u == vertex_start_id
      while u != nil
        
        path[prev[u]] = u
        u = prev[u]
      end
    end

    return path
 end

end
