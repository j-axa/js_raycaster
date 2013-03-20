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
