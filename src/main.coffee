class Player
    @MOVE_SPEED = 0.1
    @ROT_SPEED = 3 * Math.PI / 180

    constructor: ->
        @x = 1.5
        @y = 1.5
        @dir = 0
        @speed = 0
        @rot = 0.0

    move: (map) ->
        step = @speed * Player.MOVE_SPEED
        @rot += @dir * Player.ROT_SPEED % Math.PI * 2
        if @rot < 0
            @rot = Math.PI * 2 - @rot
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

class RayCastingRenderer
    @TWO_PI = Math.PI * 2
    @TWO_PI_34 = @TWO_PI * 0.75
    @TWO_PI_14 = @TWO_PI * 0.25

    constructor: (@screen, @w, @h, @textures) ->
        @screen.width = @w
        @screen.height = @h
        @screen.style.width = "#{@w}px"
        @screen.style.height = "#{@h}px"

        @gridSize = 64
        @fovRad = @toRad 60
        @cameraHeight = 48
        @distanceToProjection = (@w / 2) / Math.tan @fovRad / 2

    render: (game) ->
        ctx2d = @screen.getContext "2d"

        # clear screen
        ctx2d.fillStyle = "rgb(0,0,0)"
        ctx2d.fillRect 0, 0, @w, @h

        ctx2d.drawImage @textures[4], 0, 0, 3840, 1200, 0, 0, @w, @h / 2

        for i in [0...@w]
            rayPos = -@w / 2 + i
            rayDist = Math.sqrt (@square rayPos) + (@square @distanceToProjection)
            rayRad = game.player.rot + Math.asin rayPos / rayDist

            slice = @closestIntersect game.map, game.player, rayRad
            game.minimap.drawRay game.player, slice
            projectedHeight = 1 / slice.dist * @distanceToProjection
            top = (@h - projectedHeight) / 2

            texture = @textures[slice.wall - 1]
            ctx2d.drawImage texture, slice.ofs, 0, 1, 64, i, top, 1, projectedHeight
        null

    closestIntersect: (map, player, rayRad) ->
        rayRad %= RayCastingRenderer.TWO_PI
        horz = @findHorzIntersect map, player, rayRad
        vert = @findVertIntersect map, player, rayRad
        hDist = Math.sqrt (@square player.x - horz.x) + (@square player.y - horz.y)
        vDist = Math.sqrt (@square player.x - vert.x) + (@square player.y - vert.y)
        if hDist < vDist
            x: horz.x,
            y: horz.y,
            dist: (Math.cos player.rot - rayRad) * hDist,
            ofs: (Math.floor horz.x * @gridSize) % @gridSize,
            wall: horz.wall
        else
            x: vert.x,
            y: vert.y,
            dist: (Math.cos player.rot - rayRad) * vDist,
            ofs: (Math.floor vert.y * @gridSize) % @gridSize,
            wall: vert.wall

    findHorzIntersect: (map, player, rayRad) ->
        slope = (Math.cos rayRad) / (Math.sin rayRad)
        up = @isRayFacingUp rayRad
        y = (if up then Math.floor else Math.ceil) player.y
        x = player.x + (y - player.y) * slope
        yStep = if up then -1 else 1
        xStep = yStep * slope
        while 0 <= x < map.w and 0 <= y < map.h
            wallX = Math.floor x
            wallY = Math.floor y + (if up then -1 else 0)
            wall = map.getWall wallX, wallY
            if wall > 0 then break
            x += xStep
            y += yStep
        x: x, y: y, wall: wall

    findVertIntersect: (map, player, rayRad) ->
        slope = (Math.sin rayRad) / (Math.cos rayRad)
        right = @isRayFacingRight rayRad
        x = (if right then Math.ceil else Math.floor) player.x
        y = player.y + (x - player.x) * slope
        xStep = if right then 1 else -1
        yStep = xStep * slope
        while 0 <= x < map.w and 0 <= y < map.h
            wallX = Math.floor x + if right then 0 else -1
            wallY = Math.floor y
            wall = map.getWall wallX, wallY
            if wall > 0 then break
            x += xStep
            y += yStep
        x: x, y: y, wall: wall

    square: (n) ->
        n * n

    isRayFacingUp: (rayRad) ->
        rayRad < 0 or Math.PI < rayRad

    isRayFacingRight: (rayRad) ->
        rayRad > RayCastingRenderer.TWO_PI_34 or rayRad < RayCastingRenderer.TWO_PI_14

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
        @minimap.draw @player
        @renderer.render @

    run: ->
        window.requestAnimationFrame (time) =>
            @update()
            @run()

class Map
    constructor: (@mapData) ->
        @w = @mapData[0].length
        @h = @mapData.length

    getWall: (x, y) ->
        @mapData[y][x]

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

    drawRay: (player, slice) ->
        ctx2d = @minimap.getContext "2d"
        ctx2d.stroleStyle = "rgb(0,0,0)"
        ctx2d.beginPath()
        ctx2d.moveTo player.x * @scale, player.y * @scale
        ctx2d.lineTo slice.x * @scale, slice.y * @scale
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

wallTextures = ["brick.png", "brick_hole.png", "brick_missing.png", "brick_green.png", "sky.jpg"]
imagecount = wallTextures.length
textures = []
for texture in wallTextures
    image = new Image()
    image.onload = ->
        --imagecount
        if imagecount == 0
            start()
    image.src = "file://C:/Users/josaxa/SkyDrive/dev/js_raycaster/src/#{texture}"
    textures.push image

start = ->
    renderer = new RayCastingRenderer (document.querySelector "#screen"), 640, 480, textures
    minimap = new MiniMap (document.querySelector "#minimap"), map, 8
    player = new Player()
    game = new Game map, renderer, minimap, player
    game.run()
