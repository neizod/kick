Array::pop = (index=@length-1) -> @splice(index, 1)[0]
Array::random = -> @[Math.floor(@length * Math.random())]
Array::remove = (item) -> @pop(index) if (index = @indexOf(item)) > -1

stage_height = 300
stage_width = 1000

animate_id = null
shoot_word = null
shoot_name = null

lvl = 1
point = 0
player_die = false

pool_words = new class PoolWord
    constructor: ->
        @words = []
        @actions = ['box', 'kick', 'punch', 'strike']

    add: (word=null) ->
        if not word?
            word = @actions.random()
        @words.push(new ShootingWord(word))

    autofill: (lvl) ->
        for [1..lvl-@words.length]
            pool_words.add()

    get: (c) ->
        for word, i in @words
            if c == word.remain[0]
                return @words.pop(i)

    move: ->
        for word in @words
            word.move()
            word.update()

    attack: ->
        @words.some (word) -> word.left <= 0

    draw: ->
        for word in @words
            $('#playground').append(word.show)

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


pool_words.add('kick')

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
    pool_words.move()
    player_die = true if pool_words.attack()
    pool_words.draw()
    if player_die
        clearInterval(animate_id)
        animate_id = null
        $('#playground').css('background-color', 'darkred')


$(document).keydown (event) ->
    if event.keyCode == 13 # enter
        if not animate_id?
            animate_id = setInterval(draw, 12)
    if event.keyCode in [8, 27, 46] # backspace, escape, delete
        if shoot_word?
            shoot_word.reset()
            pool_words.add(shoot_word.full)
            shoot_word = null

$(document).keypress (event) ->
    c = String.fromCharCode(event.charCode)
    if not shoot_word?
        shoot_word = pool_words.get(c)
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
        pool_words.autofill(lvl)
