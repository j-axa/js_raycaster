class Player
    @MOVE_SPEED = 0.1
    @ROT_SPEED = 6 * Math.PI / 180

    constructor: ->
        @x = 1.0
        @y = 1.0
        @dir = 0
        @speed = 0
        @rot = 0.0

    move: (map) ->
        step = @speed * Player.MOVE_SPEED
        @rot += @dir * Player.ROT_SPEED
        newX = @x + (Math.cos @rot) * step
        newY = @y + (Math.sin @rot) * step
        unless @isBlocked map, newX, newY
            @x = newX 
            @y = newY

    isBlocked: (map, x, y) ->
        return @w > x > 0 or @h > y > 0 or (map.getWall (Math.floor x), (Math.floor y)) > 0

    parseInput: (key, active = 1) ->
        switch key
            when 38 then @speed =  1 * active
            when 40 then @speed = -1 * active
            when 37 then @dir   = -1 * active
            when 39 then @dir   =  1 * active

class Game
    constructor: (@map, @player) ->
        document.onkeydown = (e) ->
            @player.parseInput e.keyCode
        document.onkeyup = (e) ->
            @player.parseInput e.keyCode, 0
        document.onkeydown = document.onkeydown.bind this
        document.onkeyup = document.onkeyup.bind this

        @minimap = document.querySelector "#minimap"
        @map.initMiniMap @minimap, 8

    update: ->
        @player.move @map
        @map.drawMiniMap @minimap, @player, 8


class Map

    ###
    Initializes the Map class.
    @mapData Array of Array of integer
    ###
    constructor: (@mapData) ->
        @w = @mapData[0].length
        @h = @mapData.length

    ###
    Initializes the specified canvas to the correct proportions 
    based on a given scale and the current maps proportions.
    @minimap HTMLCanvasElement
    @scale integer
    ###
    initMiniMap: (minimap, scale) ->
        minimap.width = @w * scale
        minimap.height = @h * scale
        minimap.style.width = "#{@w * scale}px"
        minimap.style.height = "#{@h * scale}px"

    ###
    Draws the current map to the specified canvas
    @minimap HTMLCanvasElement
    @player Player
    @scale integer
    ###
    drawMiniMap: (minimap, player, scale) ->
        ctx2d = minimap.getContext "2d" 

        # clear
        ctx2d.fillStyle = "rgb(255,255,255)"
        ctx2d.fillRect 0, 0, @w * scale, @h * scale

        # draw map
        ctx2d.fillStyle = "rgb(200,200,200)"
        for y in [0...@h]
            for x in [0...@w]
                wall = @getWall x, y
                if wall > 0
                    ctx2d.fillRect x * scale, y * scale, scale, scale

        # draw player and a line to indicate player direction
        ctx2d.fillStyle = "rgb(255,0,0)"
        ctx2d.fillRect player.x * scale - scale / 4, player.y * scale - scale / 4, scale / 2, scale / 2
        ctx2d.beginPath()
        ctx2d.moveTo player.x * scale, player.y * scale
        ctx2d.lineTo player.x * scale + (Math.cos player.rot) * scale * 2, 
                     player.y * scale + (Math.sin player.rot) * scale * 2
        ctx2d.stroke()
        ctx2d.closePath()

    getWall: (x, y) ->
        return @mapData[y][x]

map = new Map [
    [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
    [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,0,0,3,3,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,0,0,3,0,3,0,0,1,1,1,2,1,1,1,1,1,2,1,1,1,2,1,0,0,0,0,0,0,0,0,1],
    [1,0,0,3,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,1,1,1,1,1],
    [1,0,0,3,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,0,0,3,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2],
    [1,0,0,3,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,0,0,3,3,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,1,1,1,1,1],
    [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,0,0,0,0,0,0,0,0,3,3,3,0,0,3,3,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2],
    [1,0,0,0,0,0,0,0,0,3,3,3,0,0,3,3,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,0,0,0,0,0,0,0,0,3,3,3,0,0,3,3,3,0,0,0,0,0,0,0,0,0,3,1,1,1,1,1],
    [1,0,0,0,0,0,0,0,0,3,3,3,0,0,3,3,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,0,0,4,0,0,4,2,0,2,2,2,2,2,2,2,2,0,2,4,4,0,0,4,0,0,0,0,0,0,0,1],
    [1,0,0,4,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,4,0,0,4,0,0,0,0,0,0,0,1],
    [1,0,0,4,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,4,0,0,4,0,0,0,0,0,0,0,1],
    [1,0,0,4,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,4,0,0,4,0,0,0,0,0,0,0,1],
    [1,0,0,4,3,3,4,2,2,2,2,2,2,2,2,2,2,2,2,2,4,3,3,4,0,0,0,0,0,0,0,1],
    [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
    [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
]

game = new Game map, new Player()
game.update()

window.setInterval game.update.bind(game), 1000 / 60