require 'test/unit'

class DijkstraPerformerTest < Test::Unit::TestCase

    def test_dijkstra_performer
        assert_equal 'world', 'world', "Hello.world should return a string called 'world'"
    end

    def test_flunk
        flunk "You shall not pass"
    end

end