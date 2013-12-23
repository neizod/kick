Array::pop = (index=@length-1) -> @splice(index, 1)[0]
Array::random = -> @[Math.floor(@length * Math.random())]

stage_height = 300
stage_width = 1000
font_height = 18


class ShootingWord
    constructor: (@full) ->
        @remain = @full
        @top = (stage_height - font_height) * Math.random()
        @left = stage_width
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
            @repr.html([$('<u>').html(@done()), $('<b>').html(@remain)])

    reset: ->
        @remain = @full
        @update()


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

    reset: ->
        @word?.reset()
        @word = null
        @pair?.reset()
        @pair = null


pool = new class
    constructor: ->
        @words = []
        @actions = ['box', 'kick', 'punch', 'strike']
        @autofill()

    add: (word=@actions.random()) ->
        @words.push(new ShootingWord(word))

    autofill: ->
        for [1..player.lvl-@words.length]
            @add()

    get: (c) ->
        for word, i in @words
            if c == word.remain[0]
                return @words[i]

    loop: ->
        for word in @words
            word.move()

    update: ->
        @words = (word for word in @words when word.remain)

    attack: ->
        @words.some (word) -> word.left <= 0


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

    get_name: (c) ->
        if c == @name?.remain[0]
            return @name

    index: (find) ->
        for word, i in @words
            if word.full == find.full
                return i

    show: ->
        sentence = @words.concat(if @name? then [@name] else [])
        (word.repr.html() for word in sentence).join(' ')


animate = new class
    constructor: ->
        @id = null

    start: ->
        @id = setInterval(@loop, 12)
        $('#playground').css('background-color', 'lightblue')

    stop: ->
        clearInterval(@id)
        $('#playground').css('background-color', 'darkred')

    reset: ->
        @id = null
        for reinit_object in [player, inventory, pool]
            reinit_object.constructor()

    loop: =>
        fps.loop()
        pool.loop()
        $('#fps').html(fps.show())
        $('#point').html(player.point)
        $('#keep').html(inventory.show())
        $('#playground').html(word.repr for word in pool.words)
        player.die = true if pool.attack()
        if player.die
            @stop()
            @reset()


$(document).keydown (event) ->
    if event.keyCode == 13 # enter
        if not animate.id?
            animate.start()
            if animate.id == 1
                pool.words = []
                pool.add('kick')
    if event.keyCode in [8, 27, 46] # backspace, escape, delete
        player.reset()


$(document).keypress (event) ->
    c = String.fromCharCode(event.charCode)
    if not player.word?
        player.word = pool.get(c)
    if not player.word?
        player.word = inventory.get_name(c)
    if player.word?
        if player.word.full == player.word.remain
            player.pair = inventory.get(player.word.full)
    player.word?.shot(c)
    player.pair?.shot(c)
    if player.word?.remain == ''
        player.point += player.word.full.length
        inventory.add(player.word)
        pool.update()
        player.word.reset()
        player.word = null
        player.lvl += 1
        pool.autofill()
    if player.pair?.remain == ''
        player.pair = null
