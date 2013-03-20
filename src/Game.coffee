class Game
    constructor: (@map, @renderer, @minimap, @player) ->
        document.onkeydown = (e) ->
            @player.parseInput e.keyCode
        document.onkeyup = (e) ->
            @player.parseInput e.keyCode, 0
        document.onkeydown = document.onkeydown.bind this
        document.onkeyup = document.onkeyup.bind this

    update: (time) ->
        @player.move @map
        @minimap.draw @player
        @renderer.render @, time

    run: ->
        window.requestAnimationFrame (time) =>
            @update time
            @run()
