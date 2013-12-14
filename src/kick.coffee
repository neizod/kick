words = []

class ShootingWord
    constructor: (@full) ->
        @remain = @full

    show: ->
        done = @full.slice(0, @full.length - @remain.length)
        $('<div>').append($('<u>').html(done))
                  .append($('<b>').html(@remain))

words.push(new ShootingWord('kick neizod'))

$(document).ready ->
    for word in words
        $('#playground').append(word.show())
