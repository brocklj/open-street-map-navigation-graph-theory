class DijkstraPerformer 

  # @params graph Graph, vertex_start_id String, vertex_end_id String, vertex_weight_attr String     
  # @return predecessors
  def self.perform_dijkstra(graph, vertex_start_id, vertex_end_id, vertex_weight_attr = 'length') 
    edge_map = graph.edge_map
    # collection of vertex ids    
    v_id_set = [vertex_start_id]  
    predecessors = {}        
    v_weights = {}

    # Set default weights to vertices      
    graph.vertices.each do |key, v|            
      v_weights[key] = Float::INFINITY                
      predecessors[key] = nil
      v_id_set << key
    end

    v_weights[vertex_start_id] = 0.0

   
    while(!v_id_set.empty?)
       # find closest reachable vertex
      u = _get_min_weight_vertex(v_weights, v_id_set, u)      
      
      # Break if source vertex is reached or closed vertex does not exist
      if vertex_end_id == u || u == nil       
        break
      end    

      v_id_set.delete(u)              
  
      neighbors = _get_neighbors_in_set(v_id_set, edge_map, u)

      neighbors.each_with_index do |neighbor, i|               
        alternative = v_weights[u] + _get_neighbors_weight(u, neighbor, edge_map, vertex_weight_attr)

        if alternative < v_weights[neighbor]
            v_weights[neighbor] = alternative
            predecessors[neighbor] = u
        end        
      end            
    end
  
    return predecessors, v_weights
  end

  # @params v1_id String, v2_id String, edge_map {v1_id => {v2 => Edge}}, vertex_weight_attr String
  def self._get_neighbors_weight(v1_id, v2_id, edge_map, vertex_weight_attr)
    edge = edge_map[v1_id][v2_id]
    weight = edge.edge.send(vertex_weight_attr)
    weight    
  end

  # @params v_weights {vertex_id => value}, v_id_set [String], u String
  def self._get_min_weight_vertex(v_weights, v_id_set, u) 
    vertex = nil
    dist = Float::INFINITY   
    v_id_set.each do |v|
        alt = v_weights[v]
      if alt < dist
        dist = alt
        vertex = v
      end
    end
    vertex
  end    

  # @params v_id_set [String], edge_map {v1_id => {v2 => Edge}}, u String
  def self._get_neighbors_in_set(v_id_set, edge_map, u)
    neighbors = []    
    c = edge_map[u] 
    if c == nil
      return []
    end
    c.each do |v, edge|
      if edge_map[u] != nil && edge_map[u][v] != nil
        neighbors << v
      end
    end

    return neighbors 
  end

end