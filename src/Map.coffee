class Map
    constructor: (@mapData) ->
        @w = @mapData[0].length
        @h = @mapData.length

    getWall: (x, y) ->
        @mapData[y][x]
