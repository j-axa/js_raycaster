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

    render: (game, time) ->
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
        crosshair = @textures[5]
        ctx2d.drawImage crosshair, (@w - crosshair.width) / 2, (@h - crosshair.height) / 2
        game.player.weapon.draw ctx2d, time, @w, @h
        null

    closestIntersect: (map, player, rayRad) ->
        rayRad %= RayCastingRenderer.TWO_PI
        cosRay = Math.cos rayRad
        sinRay = Math.sin rayRad
        horz = @findHorzIntersect map, player, rayRad, cosRay, sinRay
        vert = @findVertIntersect map, player, rayRad, cosRay, sinRay
        hDist = (@square player.x - horz.x) + (@square player.y - horz.y)
        vDist = (@square player.x - vert.x) + (@square player.y - vert.y)
        if hDist < vDist
            ofs = (Math.floor horz.x * @gridSize) % @gridSize
            unless horz.up
                ofs = @gridSize - ofs - 1
            x: horz.x,
            y: horz.y,
            dist: (Math.cos player.rot - rayRad) * (Math.sqrt hDist),
            ofs: ofs,
            wall: horz.wall
        else
            ofs = (Math.floor vert.y * @gridSize) % @gridSize
            unless vert.right
                ofs = @gridSize - ofs - 1
            x: vert.x,
            y: vert.y,
            dist: (Math.cos player.rot - rayRad) * (Math.sqrt vDist),
            ofs: ofs,
            wall: vert.wall

    findHorzIntersect: (map, player, rayRad, cosRay, sinRay) ->
        slope = cosRay / sinRay
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
        x: x, y: y, wall: wall, up: up

    findVertIntersect: (map, player, rayRad, cosRay, sinRay) ->
        slope = sinRay / cosRay
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
        x: x, y: y, wall: wall, right: right

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
