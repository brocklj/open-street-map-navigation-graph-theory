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

      arrowhead = edge.edge.one_way ? "vee arrowsize=3" : "none" 
      color = edge.emphesized ? "orange" : "black"  

    	graph_viz_output.add_edges( edge.v1.id, edge.v2.id, {'arrowhead' => arrowhead, 'penwidth' => penwidth, 'color' => color} )
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

  def find_path_for_id(id_v_start, id_v_end)

    start_v = visual_vertices[id_v_start]
    end_v = visual_vertices[id_v_end]

    start_v.selected = true
    end_v.selected = true
  end

  def show_nodes_for_coordinates(lat_start, lon_start, lat_end, lon_end)
    start_v, end_v = _find_close_vertices(lat_start, lon_start, lat_end, lon_end)

    start_v.color = "green"
    end_v.color = "red"
    start_v.selected = true
    end_v.selected = true
  end

  def find_vehicle_path(lat_start, lon_start, lat_end, lon_end)
    start_v, end_v = _find_close_vertices(lat_start, lon_start, lat_end, lon_end)

    path = _find_shortest_path(start_v.id, end_v.id)
    _mark_visual_edges(path)

    start_v.color = "green"
    end_v.color = "red"
    start_v.selected = true
    end_v.selected = true
  end

  def _mark_visual_edges(path)

     # Mark emphersized visual edges   
    path.each do |v1, v2|
      @graph.edge_map[v1][v2].emphesized = true if graph.edge_map[v1] != nil
    end
  end

  

  def _find_close_vertices(lat_start, lon_start, lat_end, lon_end)
    start_vertex = nil
    end_vertex = nil

    end_score = Float::INFINITY
    start_score = Float::INFINITY
    
    @visual_vertices.each do |i, v|
      
      start_result = (v.lon.to_f - lon_start.to_f).abs + (v.lat.to_f - lat_start.to_f).abs

      if start_result < start_score
        start_score = start_result
        start_vertex = v
      end

      end_result = (v.lon.to_f - lon_end.to_f).abs + (v.lat.to_f - lat_end.to_f).abs
      if end_result < end_score
        end_score = end_result
        end_vertex = v
      end    
  end

  return start_vertex, end_vertex
  end


  # Dijikstra inplementation
  # @return predecessors
  def _perform_dijikstra(graph, vertex_start, vertex_end)
    # collection of vertex ids
    set = [vertex_start]  
    predecessors = {}
    
    closed = {}
    vertex_weights = {}

    graph.vertices.each do |key, v|
      # Set default weights to vertices
      if vertex_start != key
        vertex_weights[key] = Float::INFINITY
      else
        vertex_weights[key] = 0.0      
      end
    end

    # find closest reachable vertex
    while(!set.empty?)
      
      min_dist = Float::INFINITY
      vertex = vertex_start
      
      set.each do |v|
        if vertex_weights[v] < min_dist
            min_dist = vertex_weights[v]
            vertex = v
        end
        
        set.delete(vertex)
        closed[vertex] = true

        if set.include?(vertex_end)
          break
        end

        # refresh vertex weigths
        graph.vertices.each do |id_v, v|
          # check whether edge exists
          if  graph.edge_map[vertex] != nil && graph.edge_map[vertex].has_key?(id_v)
            if !closed[id_v]
              if vertex_weights[vertex] + graph.edge_map[vertex][id_v].edge.length < vertex_weights[id_v]
                vertex_weights[id_v] = vertex_weights[vertex] + graph.edge_map[vertex][id_v].edge.length

                predecessors[id_v] = vertex                
                
                set << id_v
              end
            end
          end
        end
      end
    end
    return predecessors
  end

  # @return vertex ids of the shortest path 
 def _find_shortest_path(vertex_start, vertex_end)
    prev = _perform_dijikstra(@graph, vertex_start, vertex_end)

    path = {}
    u = vertex_end
    if prev[u] != nil || u == vertex_start
      while u != nil
        
        path[prev[u]] = u

        u = prev[u]
      end
    end

    return path
 end

end
