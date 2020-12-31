class Utils
    def self.get_path_time(length, max_kmph_speed)
        # converts to m/s
        max_mps_speed = max_kmph_speed / 3.6

        return length / max_mps_speed
    end    
end