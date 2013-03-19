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

class RayCastingRenderer #extends Renderer
    constructor: (@screen, @w, @h) ->
        @screen.width = @w
        @screen.height = @h
        @screen.style.width = "#{@w}px"
        @screen.style.height = "#{@h}px"

        @gridSize = 64
        @fovDeg = 60
        @cameraHeight = 48

    render: (game) ->
        ctx2d = @screen.getContext "2d"
        ctx2d.fillStyle = "rgb(0,0,0)"
        ctx2d.fillRect 0, 0, @w, @h
        step = @fovDeg / @w
        start = (@toDeg game.player.rot) - @fovDeg / 2
        for i in [0...@w]
            slice = @closestIntersect game.map, game.player, start
            projectedHeight = @gridSize / slice.dist * 255#@cameraDistanceToProjection()
            top = (@h - projectedHeight) / 2

            c = 255 - Math.floor slice.dist / 1000 * 200
            if c < 20 then c = 20
            ctx2d.fillStyle = "rgb(#{c},#{c},#{c})"
            ctx2d.fillRect i, top, 1, projectedHeight
            start += step

    closestIntersect: (map, player, rayDeg) ->
        horz = @findHorzIntersect map, player, rayDeg
        vert = @findVertIntersect map, player, rayDeg
        hDist = Math.sqrt (@square player.x - horz.x) + (@square player.y - horz.y)
        vDist = Math.sqrt (@square player.x - vert.x) + (@square player.y - vert.y)
        if hDist < vDist
            x: horz.x,
            y: horz.y,
            dist: (Math.cos player.rot - @toRad rayDeg) * hDist,
            ofs: x % @gridSize
        else
            x: vert.x,
            y: vert.y,
            dist: (Math.cos player.rot - @toRad rayDeg) * vDist,
            ofs: y % @gridSize

    findHorzIntersect: (map, player, rayDeg) ->
        up = @isRayFacingUp rayDeg
        y = (@toUnit player.y) + if up then -1 else @gridSize
        x = (@toUnit player.x) + ((@toUnit player.y) - y) / Math.tan @toRad @fovDeg
        yStep = if up then -@gridSize else @gridSize
        xStep = @gridSize / Math.tan @toRad rayDeg
        while (map.getWall (@toMap x), (@toMap y)) == 0
            x += xStep
            y += yStep
        x: x, y: y

    findVertIntersect: (map, player, rayDeg) ->
        right = @isRayFacingRight rayDeg
        x = (@toUnit player.x) + if right then @gridSize else -1
        y = (@toUnit player.y) + ((@toUnit player.x) - x) / Math.tan @toRad @fovDeg
        xStep = if right then @gridSize else -@gridSize
        yStep = @gridSize * Math.tan @toRad rayDeg
        while (map.getWall (@toMap x), (@toMap y)) == 0
            x += xStep
            y += yStep
        x: x, y: y

    square: (n) ->
        n * n

    cameraDistanceToProjection: ->
        @w / 2 / (Math.tan (@toRad @fovDeg / 2))

    isRayFacingUp: (rayDeg) ->
        0 < rayDeg < 180

    isRayFacingRight: (rayDeg) ->
        90 < rayDeg < 270

    toDeg: (rad) ->
        deg = (rad * 180 / Math.PI) % 360
        if deg < 0 then 360 - deg else deg

    toRad: (deg) ->
        deg * Math.PI / 180

    toUnit: (x) ->
        (Math.floor x) * @gridSize

    toMap: (x) ->
        Math.floor x / @gridSize


class Game
    constructor: (@map, @renderer, @minimap, @player) ->
        document.onkeydown = (e) ->
            @player.parseInput e.keyCode
        document.onkeyup = (e) ->
            @player.parseInput e.keyCode, 0
        document.onkeydown = document.onkeydown.bind this
        document.onkeyup = document.onkeyup.bind this

    update: ->
        @player.move @map
        @renderer.render @
        @minimap.draw @player

    run: =>
        window.setInterval (=> @update()), 1000 / 60

class Map
    constructor: (@mapData) ->
        @w = @mapData[0].length
        @h = @mapData.length

    getWall: (x, y) ->
        if 0 <= x < @w and 0 <= y < @h
            @mapData[y][x]
        else
            #debugger;
            1

class MiniMap
    constructor: (@minimap, @map, @scale) ->
        @minimap.width = @map.w * @scale
        @minimap.height = @map.h * @scale
        @minimap.style.width = "#{@minimap.width}px"
        @minimap.style.height = "#{@minimap.height}px"

    draw: (player) ->
        ctx2d = @minimap.getContext "2d"

        # clear
        ctx2d.fillStyle = "rgb(255,255,255)"
        ctx2d.fillRect 0, 0, @map.w * @scale, @map.h * @scale

        # draw map
        ctx2d.fillStyle = "rgb(200,200,200)"
        for y in [0...@map.h]
            for x in [0...@map.w]
                wall = @map.getWall x, y
                if wall > 0
                    ctx2d.fillRect x * @scale,
                                   y * @scale,
                                   @scale,
                                   @scale

        # draw a rectangle half the size of scale around the players position
        ctx2d.fillStyle = "rgb(255,0,0)"
        ctx2d.fillRect player.x * @scale - @scale / 4,
                       player.y * @scale - @scale / 4,
                       @scale / 2,
                       @scale / 2

        # draw a line with length 2 * scale originating from the players position in the direction the player is facing
        ctx2d.strokeStyle = "rgb(255,0,0)"
        ctx2d.beginPath()
        ctx2d.moveTo player.x * @scale, player.y * @scale
        ctx2d.lineTo player.x * @scale + (Math.cos player.rot) * @scale * 2,
                     player.y * @scale + (Math.sin player.rot) * @scale * 2
        ctx2d.stroke()
        ctx2d.closePath()

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
renderer = new RayCastingRenderer (document.querySelector "#screen"), 640, 480
minimap = new MiniMap (document.querySelector "#minimap"), map, 8
player = new Player()
game = new Game map, renderer, minimap, player
game.run()
