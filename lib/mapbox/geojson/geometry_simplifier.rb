module Geojson
  # Helper class
  class GeometrySimplifier

    def initialize(coordinates: nil, threshold: 0.05)
      @coordinates = coordinates
      @threshold = threshold
    end

    def simplify
      @coordinates = self.class.reduce_decimals(@coordinates)
      self.class.simplify_lines(@coordinates)
    end

    protected
      # reduce decimals in array of floats, works recursively
      def self.reduce_decimals(coordinates)
        return [] if coordinates.nil? || !coordinates.kind_of?(Array)

        coordinates.map do |coordinate|
          if coordinate.is_a?(Float)
            coordinate.round(2)
          elsif coordinate.is_a?(Fixnum)
            coordinate
          else
            reduce_decimals(coordinate)
          end
        end
      end

      def self.simplify_lines(coordinates)
        return coordinates unless Array === coordinates

        depth_coordinates = depth(coordinates)

        if depth_coordinates < 2
          return coordinates
        elsif depth_coordinates > 2
          coordinates.map do |coordinate|
            simplify_lines(coordinate)
          end
        else
          last_duplicated_coordinate = coordinates.last if coordinates.first == coordinates.last
          coordinates[0...-1] if last_duplicated_coordinate # drop last element from array, it will be added at the end

          # remove points if they are to close
          # NOTE: we must have at least 4 points in a LinearRing of coordinates
          coordinates_temp = []
          threshold = 0.05

          loop do
            coordinates_temp = remove_close_points(coordinates, threshold)
            break if coordinates_temp.length >= 4 || threshold <= 0.0

            threshold -= 0.01
          end
          coordinates = coordinates_temp unless coordinates_temp.empty?

          # if first coordinate was the same as last, add it back to the array (if it's not already there)
          if last_duplicated_coordinate && coordinates.last != last_duplicated_coordinate
            coordinates.push(last_duplicated_coordinate)
          end

          coordinates
        end
      end

      def self.remove_close_points(points, threshold)
        reduced_points = [points.first]
        prev_index = 0

        (1...(points.length)).each do |i|
          current_distance = points_distance(points[prev_index], points[i])

          # keep the point if distance is bigger then threshold
          if current_distance > threshold
            reduced_points.push(points[i])
            prev_index = i
          end
        end

        reduced_points
      end

    private
      def self.depth(array, depth = 1)
        array = array.send(:first)
        Array === array ? depth(array, depth + 1) : depth
      end

      def self.points_distance(point_a, point_b)
        # Pythagoras
        Math.sqrt( (point_a[0] - point_b[0])**2 + (point_a[1] - point_b[1])**2 )
      end
  end
end
