Array::pop = (index=@length-1) -> @splice(index, 1)[0]
Array::random = -> @[Math.floor(@length * Math.random())]
Array::remove = (item) -> @pop(index) if (index = @indexOf(item)) > -1

stage_height = 300
stage_width = 1000

pool_words = []
shoot_word = null
shoot_name = null

lvl = 1
point = 0
player_die = false

inventory = new class Inventory
    constructor: ->
        @words = []

    add: (word) ->
        if word == shoot_name?.full
            @words = []
        else if word in @words
            @words.remove(word)
        else
            @words.push(word)
        if not @words.length
            shoot_name = null
        else
            shoot_name = new ShootingWord('@neizod')

    show: ->
        follow = if shoot_name? then ' ' + shoot_name.show.html() else ''
        (word for word in @words).join(' ') + follow


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
        @left <= 0

    reset: ->
        @remain = @full


action_words = ['box', 'kick', 'punch', 'strike']

pool_words.push(new ShootingWord('kick'))

draw = ->
    $('#point').html(point)
    $('#keep').html(inventory.show())
    $('#playground').empty()
    if shoot_word?
        if shoot_word.full == shoot_name?.full
            shoot_word.update()
        else
            shoot_word.move()
            player_die = true if shoot_word.update()
            $('#playground').append(shoot_word.show)
    for word in pool_words
        word.move()
        player_die = true if word.update()
        $('#playground').append(word.show)
    if player_die
        $('#playground').css('background-color', 'darkred')


$(document).ready ->
    setInterval(draw, 12)

$(document).keydown (event) ->
    if event.keyCode in [8, 27, 46] # backspace, escape, delete
        if shoot_word?
            shoot_word.reset()
            pool_words.push(shoot_word)
            shoot_word = null

$(document).keypress (event) ->
    c = String.fromCharCode(event.charCode)
    if not shoot_word?
        for word, i in pool_words
            if c == word.remain[0]
                shoot_word = pool_words.pop(i)
                break
    if not shoot_word? and shoot_name?
        if c == shoot_name.remain[0]
            shoot_word = shoot_name
    if c == shoot_word?.remain[0]
        shoot_word.shot()
    if shoot_word?.remain == ''
        point += shoot_word.full.length
        inventory.add(shoot_word.full)
        shoot_word = null
        lvl += 1
        for i in [1..lvl-pool_words.length]
            pool_words.push(new ShootingWord(action_words.random()))
