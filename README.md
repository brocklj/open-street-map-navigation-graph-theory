# Open Street Map Simple Navigator   
This project is a simple navigation tool that loads maps from various formats, performs specific actions on the data, and exports the results. The tool supports various input and output formats and provides multiple functionalities, including graph visualization, node marking, shortest path calculations, and more.


## Author

Created and maintained by [Jakub Bröckl](#).




---

## Usage

```bash
 ruby osm_simple_nav.rb <load_command> <input.IN> <action_command> <output.OUT>
 ```

### Load Commands

The tool supports the following commands for loading map data from a file (`<input.IN>` can be `DOT` or `OSM`):

-   `--load-undir`: Load an undirected map.
-   `--load-dir`: Load a directed map.
-   `--load-undir-comp`: Load an undirected map with additional compression.
-   `--load-dir-comp`: Load a directed map with additional compression.

### Action Commands

The tool provides the following commands to perform actions on the loaded map:

-   `--export`: Export the graph to a file (`<output.OUT>` can be `PDF`, `PNG`, or `DOT`).
-   `--show-nodes`: Mark nodes and export the graph. Output formats are `PDF`, `PNG`, or `DOT`.

Additional options for marking nodes:

-   `[<geo lat1 long1> <geo lat2 long2>]`: Mark nodes within the specified geographic coordinates.
-   `[<node_from_id> <node_to_id>]`: Mark specific nodes by their IDs.

Other action commands:

-   `--midist-len`: Find the shortest path (by distance) between two points and export the result (`PDF` or `PNG`).
-   `--midist-time`: Find the fastest path (by time) between two points and export the result (`PDF` or `PNG`).
-   `--center`: Find the center of an undirected graph and export the result (`PDF` or `PNG`).
* * *

## Examples

### Load an undirected map and export to PDF:

bash

Copy code

`ruby osm_simple_nav.rb --load-undir map.osm --export graph.pdf`

### Show nodes within a geographic range and export to PNG:

bash

Copy code

`ruby osm_simple_nav.rb --load-dir map.dot --show-nodes geo 50.0 14.0 50.1 14.1 graph.png`

### Find the shortest path by distance between nodes:

bash

Copy code

`ruby osm_simple_nav.rb --load-undir-comp map.osm --midist-len node_1 node_2 graph.pdf`

* * *

## Input and Output Formats

### Input File Formats

-   `DOT`: Graph description format.
-   `OSM`: OpenStreetMap data format.

### Output File Formats

-   `PDF`: Portable Document Format for visualizing graphs.
-   `PNG`: Portable Network Graphics for visualizing graphs.
-   `DOT`: Graph description format for further processing.
* * *

## Requirements

-   Ruby (compatible with version `x.y.z` or higher)
-   Libraries required for graph manipulation and visualization (e.g., `Graphviz`).

### Ruby-graphviz library installation
``
$ gem install ruby-graphviz
``
* * *

## License

This project is licensed under the MIT License.
