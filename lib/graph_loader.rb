require_relative '../process_logger'
require 'nokogiri'
require_relative 'graph'
require_relative 'visual_graph'

# Class to load graph from various formats. Actually implemented is Graphviz formats. Future is OSM format.
class GraphLoader
	attr_reader :highway_attributes

	# Create an instance, save +filename+ and preset highway attributes
	def initialize(filename, highway_attributes)
		@filename = filename
		@highway_attributes = highway_attributes 
	end

	# Load graph from Graphviz file which was previously constructed from this application, i.e. contains necessary data.
	# File needs to contain 
	# => 1) For node its 'id', 'pos' (containing its re-computed position on graphviz space) and 'comment' containig string with comma separated lat and lon
	# => 2) Edge (instead of source and target nodes) might contains info about 'speed' and 'one_way'
	# => 3) Generaly, graph contains parametr 'bb' containing array withhou bounds of map as minlon, minlat, maxlon, maxlat
	#
	# @return [+Graph+, +VisualGraph+]
	def load_graph_viz()
		ProcessLogger.log("Loading graph from GraphViz file #{@filename}.")
		gv = GraphViz.parse(@filename)

		# aux data structures
		hash_of_vertices = {}
		list_of_edges = []
		hash_of_visual_vertices = {}
		list_of_visual_edges = []		

		# process vertices
		ProcessLogger.log("Processing vertices")
		gv.node_count.times { |node_index|
			node = gv.get_node_at_index(node_index)
			vid = node.id

			v = Vertex.new(vid) unless hash_of_vertices.has_key?(vid)
			ProcessLogger.log("\t Vertex #{vid} loaded")
			hash_of_vertices[vid] = v

			geo_pos = node["comment"].to_s.delete("\"").split(",")
			pos = node["pos"].to_s.delete("\"").split(",")	
			hash_of_visual_vertices[vid] = VisualVertex.new(vid, v, geo_pos[0], geo_pos[1], pos[1], pos[0])
			ProcessLogger.log("\t Visual vertex #{vid} in ")
		}

		# process edges
		gv.edge_count.times { |edge_index|
			link = gv.get_edge_at_index(edge_index)
			vid_from = link.node_one.delete("\"")
			vid_to = link.node_two.delete("\"")
			speed = 50
			one_way = false
			link.each_attribute { |k,v|
				speed = v if k == "speed"
				one_way = true if k == "oneway"
			}
			e = Edge.new(vid_from, vid_to, speed, one_way)
			list_of_edges << e
			list_of_visual_edges << VisualEdge.new(e, hash_of_visual_vertices[vid_from], hash_of_visual_vertices[vid_to])
		}

		# Create Graph instance
		g = Graph.new(hash_of_vertices, list_of_edges)

		# Create VisualGraph instance
		bounds = {}
		bounds[:minlon], bounds[:minlat], bounds[:maxlon], bounds[:maxlat] = gv["bb"].to_s.delete("\"").split(",")
		vg = VisualGraph.new(g, hash_of_visual_vertices, list_of_visual_edges, bounds)

		return g, vg
	end

	# Method to load graph from OSM file and create +Graph+ and +VisualGraph+ instances from +self.filename+
	#
	# @return [+Graph+, +VisualGraph+]
	def load_graph(load_cmd)
		ProcessLogger.log("Loading graph from GraphViz file #{@filename}.")

		# Load OSM from XML
		osm = File.open(@filename) { |f| Nokogiri::XML(f) }

		# aux data structures
		hash_of_vertices = {}
		list_of_edges = []
		hash_of_visual_vertices = {}
		list_of_visual_edges = []	

		osm.at_xpath("//osm")

		ways = osm.xpath("//way")		
		ways.each do |way| 
			way_tags = way.xpath("tag")

			# Check whether current way is according to @highway_attributes	
			tag_highway = way_tags.at_css("[@k='highway']")
			highway_type = tag_highway.nil? ? nil : tag_highway["v"]  
			unless (@highway_attributes.include?(highway_type))
				next
			end
			
			# gets speed whether is set or assign 50 as default
			tag_maxspeed = way_tags.at_css("[@k='maxspeed']")
			speed = tag_maxspeed.nil? ? 50 : tag_maxspeed["v"].to_i

			# gets value wheter is oneway
			tag_oneway = way_tags.css("[@k='oneway']")
			is_one_way = tag_oneway.nil? && tag_oneway["v"] != "yes" ? false : true 

			way_nds = way.xpath("nd")
			way_nds.count.times do |nd_index| 
				
				vid_from =  way_nds[nd_index]["ref"]
				vid_to = way_nds[nd_index + 1].nil? ? nil : way_nds[nd_index + 1]["ref"]
			
				if vid_from && vid_to
					v1 = hash_of_vertices.has_key?(vid_from) ? hash_of_vertices[vid_from] : Vertex.new(vid_from) 
					unless hash_of_vertices.has_key?(vid_from)
						hash_of_vertices[vid_from] = v1 
						ProcessLogger.log("\t Vertex #{vid_from} loaded")
					end

					v2 = hash_of_vertices.has_key?(vid_to) ? hash_of_vertices[vid_to] : Vertex.new(vid_to) 
					unless hash_of_vertices.has_key?(vid_to)
						hash_of_vertices[vid_to] = v2 
						ProcessLogger.log("\t Vertex #{vid_to} loaded")
					end

					edge = Edge.new(v1, v2, speed, is_one_way)
					list_of_edges << edge
				end
			end
		end

		if load_cmd == "--load-comp"
			list_of_edges, hash_of_vertices = _process_comp(list_of_edges, hash_of_vertices)
		end

		# process visual vertices	
		ProcessLogger.log("Processing vertices")
		nodes = osm.xpath("//node")
		nodes.each do |node|
			vid = node["id"]
			unless hash_of_vertices.has_key?(vid)
				next
			end

			vertex = hash_of_vertices[vid]
			lat = node["lat"]
			lon = node["lon"]
			x = lon.to_f * 100
			y = lat.to_f * 100
					
			hash_of_visual_vertices[vid] = VisualVertex.new(vid, vertex, lat, lon, y, x)
			ProcessLogger.log("\t Visual vertex #{vid} in ")			
		end
		
		# process visual edges
		list_of_edges.each do |edge|		
			v1 = hash_of_visual_vertices[edge.v1.id] if hash_of_visual_vertices.has_key?(edge.v1.id)
			v2 = hash_of_visual_vertices[edge.v2.id] if hash_of_visual_vertices.has_key?(edge.v2.id)
			
			list_of_visual_edges << VisualEdge.new(edge, v1, v2)
		end
		
		# get bounds hash from OSM
		osm_bounds = osm.at_xpath("//bounds")
		bounds = {:minlat => osm_bounds["minlat"], :minlon => osm_bounds["minlon"], :maxlat => osm_bounds["maxlat"], :maxlon => osm_bounds["maxlon"]}
		# multiply each bound by 100
		bounds.map {|key, val|  bounds[key] = val.to_f * 100 }

		# puts "hash_of_vertices: #{hash_of_vertices.count}, list_of_edges: #{list_of_edges.count}"
		# puts "hash_of_visual_vertices: #{hash_of_visual_vertices.count}, list_of_visual_edges: #{list_of_visual_edges.count}"
		
		g = Graph.new(hash_of_vertices, list_of_edges)
		vg = VisualGraph.new(g, hash_of_visual_vertices, list_of_visual_edges, bounds)

		return g, vg	
	end

	# implement DFS in order to get the greatest component
	# @return greatest component
	def _process_comp(list_of_edges, hash_of_vertices)
		list_of_components = []
		# list of IDs visited vertices
		visited_edges = []	

		discovered_vertices = []
		
		list_of_edges.each do |edge|
			if visited_edges.include?(edge)
				next
			end
		
			component = _perform_comp_search(list_of_edges, edge)
			list_of_components << component

			visited_edges = visited_edges.concat(component)
		end

		comp_list_of_edges = []
		list_of_components.each do |comp|
			if comp.length >=  comp_list_of_edges.length
				comp_list_of_edges = comp
			end
		end

		comp_vertices_edges = {}
		comp_list_of_edges.each do |e| 
			comp_vertices_edges[e.v1.id] = e
			comp_vertices_edges[e.v2.id] = e
		end

		comp_hash_of_vertices = hash_of_vertices.select { |key, v| comp_vertices_edges.has_key?(key)}
		
		return comp_list_of_edges, comp_hash_of_vertices					
	end

	def _perform_comp_search(list_of_edges, edge, component = [])
		v1 = edge.v1
		v2 = edge.v2		
		
		connected_edges = list_of_edges.select {|e| (v1.id == e.v1.id || v1.id == e.v2.id || v2.id == e.v1.id || v2.id == e.v2.id ) }
		connected_edges.length.times do |i| 			
			e = connected_edges[i]
			if !component.include?(e)
				component << e				
				_perform_comp_search(list_of_edges, e, component)
			end			
			
		end

		return component		
	end
end
