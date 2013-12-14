pool_words = []
shoot_word = null

class ShootingWord
    constructor: (@full) ->
        @remain = @full

    show: ->
        done = @full.slice(0, @full.length - @remain.length)
        $('<div>').append($('<u>').html(done))
                  .append($('<b>').html(@remain))

    shot: ->
        @remain = @remain.slice(1)

pool_words.push(new ShootingWord('kick neizod'))
pool_words.push(new ShootingWord('punch neizod'))
pool_words.push(new ShootingWord('strike neizod'))


draw = ->
    $('#playground').empty()
    if shoot_word?
        $('#playground').append(shoot_word.show())
    for word in pool_words
        $('#playground').append(word.show())


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
