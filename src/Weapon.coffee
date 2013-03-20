class Weapon
    constructor: (@frames, @animRate, @scale, @vOffset) ->
        @currentFrame = 0
        @lastAnim = 0
        @firing = false

    fire: ->
        @firing = true

    draw: (ctx2d, time, w, h) ->
        currentTexture = @frames[@currentFrame]
        ctx2d.drawImage currentTexture, (w - currentTexture.width * @scale) / 2 + @vOffset * @scale, h - currentTexture.height * @scale, currentTexture.width * @scale, currentTexture.height * @scale
        if @firing and time - @lastAnim >= @animRate
            if @currentFrame == @frames.length - 1
                @firing = false
                @currentFrame = 0
                @lastAnim = 0
            else
                @lastAnim = time
                ++@currentFrame
