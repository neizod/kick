stage_height = 300
stage_width = 1000

pool_words = []
shoot_word = null

class ShootingWord
    constructor: (@full) ->
        @remain = @full
        @top = stage_height * Math.random()
        @left = stage_width - 100 # FIXME initial outside cause multiline
        @show = @make_show()

    make_show: ->
        $('<div>').addClass('shooting-word')
                  .append($('<u>').html(@done()))
                  .append($('<b>').html(@remain))
                  .css('top', @top)
                  .css('left', @left)

    done: ->
        @full.slice(0, @full.length - @remain.length)

    shot: ->
        @remain = @remain.slice(1)

    move: ->
        @left -= 1 # TODO render smoother w/ word movement speed
        @show.css('left', @left)

    update: ->
        @show.empty()
             .append($('<u>').html(@done()))
             .append($('<b>').html(@remain))

    # TODO player die when word reach left side


pool_words.push(new ShootingWord('kick neizod'))
pool_words.push(new ShootingWord('punch neizod'))
pool_words.push(new ShootingWord('strike neizod'))


draw = ->
    $('#playground').empty()
    if shoot_word?
        shoot_word.move()
        shoot_word.update()
        $('#playground').append(shoot_word.show)
    for word in pool_words
        word.move()
        word.update()
        $('#playground').append(word.show)


$(document).ready ->
    setInterval(draw, 12)

$(document).keypress (event) ->
    c = String.fromCharCode(event.charCode)
    if not shoot_word?
        for word, i in pool_words
            if c == word.remain[0]
                [shoot_word] = pool_words.splice(i, 1)
                break

    if c == shoot_word?.remain[0]
        shoot_word.shot()
        shoot_word = null if not shoot_word.remain
