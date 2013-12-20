Array::pop = (index=@length-1) -> @splice(index, 1)[0]
Array::random = -> @[Math.floor(@length * Math.random())]

stage_height = 300
stage_width = 1000


player = new class Player
    constructor: ->
        @lvl = 1
        @point = 0
        @die = false
        @word = null
        @game = null
        @longest = []


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
                return @words[i]

    move: ->
        for word in @words
            word.move()
            word.update()

    update: ->
        @words = (word for word in @words when word.remain)

    attack: ->
        @words.some (word) -> word.left <= 0

    draw: ->
        for word in @words
            $('#playground').append(word.show)


inventory = new class Inventory
    constructor: ->
        @words = []
        @name = null

    add: (word) ->
        if word.full == @name?.full
            if @words.length >= player.longest.length
                player.longest = @words
            @words = []
        else if (index = @index(word))?
            @words.pop(index)
        else
            @words.push(word)
        if not @words.length
            @name = null
        else
            @name = new ShootingWord('@neizod')

    index: (find) ->
        for word, i in @words
            if word.full == find.full
                return i

    show: ->
        sentence = @words.concat(if @name? then [@name] else [])
        (word.show.html() for word in sentence).join(' ')



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

    shot: (c) ->
        if c == @remain[0]
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
    player.word?.update()
    pool_words.move()
    player.die = true if pool_words.attack()
    pool_words.draw()
    if player.die
        clearInterval(player.game)
        player.game = null
        $('#playground').css('background-color', 'darkred')


$(document).keydown (event) ->
    if event.keyCode == 13 # enter
        if not player.game?
            player.game = setInterval(draw, 12)
    if event.keyCode in [8, 27, 46] # backspace, escape, delete
        if player.word?
            player.word.reset()
            player.word.update()
            player.word = null

$(document).keypress (event) ->
    c = String.fromCharCode(event.charCode)
    if not player.word?
        player.word = pool_words.get(c)
    if not player.word? and inventory.name?
        if c == inventory.name.remain[0]
            player.word = inventory.name
    player.word?.shot(c)
    if player.word?.remain == ''
        player.point += player.word.full.length
        inventory.add(player.word)
        pool_words.update()
        player.word.reset()
        player.word.update()
        player.word = null
        player.lvl += 1
        pool_words.autofill(player.lvl)
