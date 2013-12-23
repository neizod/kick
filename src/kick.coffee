Array::pop = (index=@length-1) -> @splice(index, 1)[0]
Array::random = -> @[Math.floor(@length * Math.random())]

stage_height = 300
stage_width = 1000


fps = new class
    constructor: ->
        @frames = 20
        @time = 0
        @date = new Date()

    loop: ->
        now = new Date()
        @time += (now - @date - @time) / @frames
        @date = now

    rate: ->
        1000 / @time

    show: ->
        @rate().toFixed(1) + ' fps'


player = new class
    constructor: ->
        @lvl = 1
        @point = 0
        @die = false
        @word = null
        @pair = null
        @game = null
        @longest = []


pool_words = new class
    constructor: ->
        @words = []
        @actions = ['box', 'kick', 'punch', 'strike']

    add: (word=@actions.random()) ->
        @words.push(new ShootingWord(word))

    autofill: ->
        for [1..player.lvl-@words.length]
            pool_words.add()

    get: (c) ->
        for word, i in @words
            if c == word.remain[0]
                return @words[i]

    move: ->
        for word in @words
            word.move()

    update: ->
        @words = (word for word in @words when word.remain)

    attack: ->
        @words.some (word) -> word.left <= 0

    draw: ->
        for word in @words
            $('#playground').append(word.repr)


inventory = new class
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

    get: (fullword) ->
        for word, i in @words
            if fullword == word.full
                return @words[i]

    index: (find) ->
        for word, i in @words
            if word.full == find.full
                return i

    show: ->
        sentence = @words.concat(if @name? then [@name] else [])
        (word.repr.html() for word in sentence).join(' ')



class ShootingWord
    constructor: (@full) ->
        @remain = @full
        @top = stage_height * Math.random()
        @left = stage_width - 100 # FIXME initial outside cause multiline
        @repr = @make_repr()
        @update()

    make_repr: ->
        $('<div>').addClass('shooting-word')
                  .css('top', @top)
                  .css('left', @left)

    done: ->
        @full.slice(0, @full.length - @remain.length)

    shot: (c) ->
        if c == @remain[0]
            @remain = @remain.slice(1)
        @update()

    move: ->
        @left -= 1 # TODO render smoother w/ word movement speed
        @repr.css('left', @left)

    update: ->
        if @remain == @full
            @repr.html($('<b>').html(@full))
        else
            @repr.empty()
                 .append($('<u>').html(@done()))
                 .append($('<b>').html(@remain))

    reset: ->
        @remain = @full
        @update()


pool_words.add('kick')

draw = ->
    fps.loop()
    $('#fps').html(fps.show())
    $('#point').html(player.point)
    $('#keep').html(inventory.show())
    $('#playground').empty()
    player.word?.update()
    pool_words.move()
    player.die = true if pool_words.attack()
    pool_words.draw()
    if player.die
        clearInterval(player.game)
        $('#playground').css('background-color', 'darkred')
        player.constructor()
        inventory.constructor()
        pool_words.constructor()
        pool_words.autofill()


$(document).keydown (event) ->
    if event.keyCode == 13 # enter
        if not player.game?
            player.game = setInterval(draw, 12)
            $('#playground').css('background-color', 'lightblue')
    if event.keyCode in [8, 27, 46] # backspace, escape, delete
        player.word?.reset()
        player.word = null
        player.pair?.reset()
        player.pair = null

$(document).keypress (event) ->
    c = String.fromCharCode(event.charCode)
    if not player.word?
        player.word = pool_words.get(c)
    if not player.word? and inventory.name?
        if c == inventory.name.remain[0]
            player.word = inventory.name
    if player.word?
        if player.word.full == player.word.remain
            player.pair = inventory.get(player.word.full)
    player.word?.shot(c)
    player.pair?.shot(c)
    if player.word?.remain == ''
        player.point += player.word.full.length
        inventory.add(player.word)
        pool_words.update()
        player.word.reset()
        player.word = null
        player.lvl += 1
        pool_words.autofill()
    if player.pair?.remain == ''
        player.pair = null
