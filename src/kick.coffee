Array::pop = (index=@length-1) -> @splice(index, 1)[0]
Array::random = -> @[Math.floor(@length * Math.random())]
Array::remove = (item) -> @pop(index) if (index = @indexOf(item)) > -1

stage_height = 300
stage_width = 1000

animate_id = null
shoot_name = null


player = new class Player
    constructor: ->
        @lvl = 1
        @point = 0
        @die = false
        @word = null


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
    $('#point').html(player.point)
    $('#keep').html(inventory.show())
    $('#playground').empty()
    if player.word?
        if player.word.full == shoot_name?.full
            player.word.update()
        else
            player.word.move()
            player.die = true if player.word.update()
            $('#playground').append(player.word.show)
    pool_words.move()
    player.die = true if pool_words.attack()
    pool_words.draw()
    if player.die
        clearInterval(animate_id)
        animate_id = null
        $('#playground').css('background-color', 'darkred')


$(document).keydown (event) ->
    if event.keyCode == 13 # enter
        if not animate_id?
            animate_id = setInterval(draw, 12)
    if event.keyCode in [8, 27, 46] # backspace, escape, delete
        if player.word?
            player.word.reset()
            pool_words.add(player.word.full)
            player.word = null

$(document).keypress (event) ->
    c = String.fromCharCode(event.charCode)
    if not player.word?
        player.word = pool_words.get(c)
    if not player.word? and shoot_name?
        if c == shoot_name.remain[0]
            player.word = shoot_name
    if c == player.word?.remain[0]
        player.word.shot()
    if player.word?.remain == ''
        player.point += player.word.full.length
        inventory.add(player.word.full)
        player.word = null
        player.lvl += 1
        pool_words.autofill(player.lvl)
