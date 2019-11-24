# Class representing visual representation of edge
class VisualEdge
  # Starting +VisualVertex+ of this visual edge
  attr_reader :v1
  # Target +VisualVertex+ of this visual edge
  attr_reader :v2
  # Corresponding edge in the graph
  attr_reader :edge
  # Boolean value given directness
  attr_reader :directed
  # Boolean value emphasize character - drawn differently on output (TODO)
  attr_reader :emphesized
  # Float value of the geographical distance between two vertices
  attr_reader :length

  # create instance of +self+ by simple storing of all parameters
  def initialize(edge, v1, v2, length)
  	@edge = edge
    @v1 = v1
    @v2 = v2
    @length = length
  end
end

