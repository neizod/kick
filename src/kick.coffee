words = []

class ShootingWord
    constructor: (@full) ->
        @remain = @full

    show: ->
        done = @full.slice(0, @full.length - @remain.length)
        $('<div>').append($('<u>').html(done))
                  .append($('<b>').html(@remain))

    shot: ->
        @remain = @remain.slice(1)

words.push(new ShootingWord('kick neizod'))


draw = ->
    $('#playground').empty()
    for word in words
        $('#playground').append(word.show())


$(document).ready ->
    setInterval(draw, 12)

$(document).keypress (event) ->
    c = String.fromCharCode(event.charCode)
    for word in words
        if c == word.remain[0]
            word.shot()
