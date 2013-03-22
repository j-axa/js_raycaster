class Player
    @MOVE_SPEED = 0.1
    @ROT_SPEED = 3 * Math.PI / 180

    constructor: (@weapon) ->
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
        unless @isBlockedX map, newX, @y
            @x = newX
        unless @isBlockedY map, @x, newY
            @y = newY

    isBlockedX: (map, x, y) ->
        return @w > x > 0 or (map.getWall (Math.floor x), (Math.floor y)) > 0

    isBlockedY: (map, x, y) ->
        return @h > y > 0 or (map.getWall (Math.floor x), (Math.floor y)) > 0

    parseInput: (key, active = 1) ->
        switch key
            when 38 then @speed =  1 * active
            when 40 then @speed = -1 * active
            when 37 then @dir   = -1 * active
            when 39 then @dir   =  1 * active
            when 17 then @weapon.fire()
